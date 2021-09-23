//
//  SearchViewController.swift
//  ViewModelLike
//
//  Created by marty-suzuki on 2021/09/25.
//

import Combine
import CombineSchedulers
import Model
import UIKit
import ViewDataModel

public typealias SearchSnapshot = NSDiffableDataSourceSnapshot<SearchSection, SearchItem>

public protocol SearchInput {
    func setSnapshot(_ snapshot: SearchSnapshot)
}

public protocol SearchOutput {
    var searchText: AnyPublisher<String?, Never> { get }
    var didScroll: AnyPublisher<(CGSize, CGSize, CGPoint), Never> { get }
    var didSelectIndexPath: AnyPublisher<IndexPath, Never> { get }
}

public final class SearchViewController: UIViewController {

    private let viewContainer: AnyViewContainer<SearchInput, SearchOutput>
    private let model: SearchModel
    private let navigator: SearchNavigator
    private let mainScheduler: AnySchedulerOf<DispatchQueue>
    private var cancellables = Set<AnyCancellable>()

    @Published private var snapshot = SearchSnapshot()
    @Published private var isBottom = false

    public init(
        viewContainer: AnyViewContainer<SearchInput, SearchOutput>,
        model: SearchModel,
        navigator: SearchNavigator,
        mainScheduler: AnySchedulerOf<DispatchQueue>
    ) {
        self.viewContainer = viewContainer
        self.model = model
        self.navigator = navigator
        self.mainScheduler = mainScheduler
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = viewContainer.view
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        let navigateToWebview = PassthroughSubject<URL, Never>()
        navigateToWebview
            .receive(on: mainScheduler)
            .sink { [weak self] in
                guard let me = self else {
                    return
                }
                me.navigator.navigateToWebview(url: $0, on: me)
            }
            .store(in: &cancellables)

        viewContainer.output.searchText
            .flatMap { [model] query -> AnyPublisher<TMDBError, Never> in
                guard let query = query else {
                    return Empty().eraseToAnyPublisher()
                }
                return model.search(query: query)
                    .flatMap { result -> AnyPublisher<TMDBError, Never> in
                        switch result {
                        case .success:
                            return Empty().eraseToAnyPublisher()
                        case let .failure(value):
                            return Just(value).eraseToAnyPublisher()
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: mainScheduler)
            .sink { [weak self] error in
                guard let me = self else {
                    return
                }
                let alert: AlertViewDataModel
                switch error {
                case let .invalidApiKey(data):
                    alert = AlertViewDataModel(
                        title: "Code: \(data.statusCode)",
                        message: data.statusMessage + " See \(Const.tmdbDocument.absoluteString).",
                        actions: [
                            AlertViewDataModel.Action(
                                title: "Open",
                                style: .default
                            ) {
                                navigateToWebview.send(Const.tmdbDocument)
                            }
                        ]
                    )
                case let .tmdb(data):
                    alert = AlertViewDataModel(
                        title: "Code: \(data.statusCode)",
                        message: data.statusMessage,
                        actions: []
                    )
                case .other:
                    return
                }
                me.navigator.navigateToError(
                    alert: alert,
                    on: me
                )
            }
            .store(in: &cancellables)

        $isBottom
            .removeDuplicates()
            .flatMap { [model] isBottom -> AnyPublisher<Void, Never> in
                guard isBottom else {
                    return Empty().eraseToAnyPublisher()
                }
                return model.loadMore()
                    .map { _ in }
                    .eraseToAnyPublisher()
            }
            .sink {}
            .store(in: &cancellables)

        viewContainer.output.didScroll
            .map { size, contentSize, offset -> Bool in
                let delta = contentSize.height - size.height
                guard delta > 0 else {
                    return false
                }
                return delta < offset.y
            }
            .assign(to: &$isBottom)

        let snapshot1 = model.moviesPulisher
            .flatMap { movies -> AnyPublisher<SearchSnapshot, Never> in
                guard !movies.isEmpty else {
                    return Empty().eraseToAnyPublisher()
                }
                var snapshot = SearchSnapshot()
                snapshot.appendSections([.movie])
                let items: [SearchItem] = movies.map {
                    .movie(
                        MovieViewDataModel(
                            id: $0.id.rawValue,
                            title: $0.title,
                            imageURL: $0.posterPath?.rawValue
                        )
                    )
                }
                var seen = Set<SearchItem>()
                snapshot.appendItems(items.filter { seen.insert($0).inserted }, toSection: .movie)
                return Just(snapshot).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()

        let snapshot2 = model.isExecutingPublisher
            .flatMap { [weak self] isExecuting -> AnyPublisher<SearchSnapshot, Never> in
                guard let me = self else {
                    return Empty().eraseToAnyPublisher()
                }
                var snapshot = me.snapshot
                if isExecuting {
                    let snapshotPublisher: (SearchSection) -> AnyPublisher<SearchSnapshot, Never> = {
                        if snapshot.indexOfSection($0) == nil {
                            snapshot.appendSections([$0])
                            snapshot.appendItems([.loading], toSection: $0)
                            return Just(snapshot).eraseToAnyPublisher()
                        } else {
                            return Empty().eraseToAnyPublisher()
                        }
                    }
                    if snapshot.indexOfSection(.movie) == nil {
                        return snapshotPublisher(.loading(.large))
                    } else {
                        return snapshotPublisher(.loading(.small))
                    }
                } else {
                    snapshot.deleteSections([.loading(.small), .loading(.large)])
                    return Just(snapshot).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()

        snapshot1
            .merge(with: snapshot2)
            .assign(to: &$snapshot)

        $snapshot
            .receive(on: mainScheduler)
            .sink { [weak self] in
                self?.viewContainer.input.setSnapshot($0)
            }
            .store(in: &cancellables)

        viewContainer.output.didSelectIndexPath
            .throttle(for: 1, scheduler: mainScheduler, latest: false)
            .flatMap { [weak self] indexPath -> AnyPublisher<Movie.ID, Never> in
                guard let me = self else {
                    return Empty().eraseToAnyPublisher()
                }
                let section = me.snapshot.sectionIdentifiers[indexPath.section]
                switch me.snapshot.itemIdentifiers(inSection: section)[indexPath.item] {
                case let .movie(viewDataModel):
                    return Just(Movie.ID(rawValue: viewDataModel.id)).eraseToAnyPublisher()
                case .loading:
                    return Empty().eraseToAnyPublisher()
                }
            }
            .sink { [weak self] id in
                guard let me = self else {
                    return
                }
                me.navigator.navigateToDetail(movieID: id, on: me)
            }
            .store(in: &cancellables)
    }

    private enum Const {
        static let tmdbDocument = URL(string: "https://developers.themoviedb.org/3/getting-started/introduction")!
    }
}
