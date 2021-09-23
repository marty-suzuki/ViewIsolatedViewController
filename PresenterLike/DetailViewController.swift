//
//  DetailViewController.swift
//  PresenterLike
//
//  Created by marty-suzuki on 2021/09/26.
//

import Combine
import CombineSchedulers
import Model
import UIKit
import ViewDataModel

public typealias DetailSnapshot = NSDiffableDataSourceSnapshot<DetailSection, DetailItem>

public protocol DetailPresenterLike: AnyObject {
    func didSelectIndexPath(_ indexPath: IndexPath)
}

public protocol DetailViewLike: ViewContainer {
    var presenterLike: DetailPresenterLike? { get set }
    func setSnapshot(_ snapshot: DetailSnapshot)
}

public final class DetailViewController: UIViewController {

    private let viewContainer: DetailViewLike
    private let model: DetailModel
    private let navigator: DetailNavigator
    private let movieID: Movie.ID
    private let mainScheduler: AnySchedulerOf<DispatchQueue>
    private let defaultScheduler: AnySchedulerOf<DispatchQueue>

    private let _didSelectIndexPath = PassthroughSubject<IndexPath, Never>()
    private var cancellables = Set<AnyCancellable>()

    @Published private var snapshot = DetailSnapshot()
    @Published private var thumbnailStatus: ThumbnailStatus?
    @Published private var isAppeared = false

    public init(
        movieID: Movie.ID,
        viewContainer: DetailViewLike,
        model: DetailModel,
        navigator: DetailNavigator,
        mainScheduler: AnySchedulerOf<DispatchQueue>,
        defaultScheduler: AnySchedulerOf<DispatchQueue>
    ) {
        self.viewContainer = viewContainer
        self.model = model
        self.movieID = movieID
        self.navigator = navigator
        self.mainScheduler = mainScheduler
        self.defaultScheduler = defaultScheduler
        super.init(nibName: nil, bundle: nil)
        snapshot.appendSections([.loading])
        snapshot.appendItems([.loading], toSection: .loading)
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

        viewContainer.presenterLike = self

        let initialSnapshotAndThumbnailStatus = model.movieDetailPublisher
            .map { movieDetail -> (DetailSnapshot, ThumbnailStatus?) in
                var snapshot = DetailSnapshot()
                snapshot.appendSections([.thumbnail])

                let thumbnailStatus: ThumbnailStatus?
                if
                    let backdrops = movieDetail.images?.backdrops,
                    let image = backdrops.first
                {
                    thumbnailStatus = ThumbnailStatus(
                        index: 0,
                        images: backdrops.map { $0.filePath.rawValue }
                    )
                    snapshot.appendItems([.thumbnail(.image(image.filePath.rawValue))], toSection: .thumbnail)
                } else {
                    thumbnailStatus = nil
                    snapshot.appendItems([.thumbnail(.noImage)], toSection: .thumbnail)
                }

                let summary = DetailItem.Summary(
                    title: movieDetail.title,
                    release: movieDetail.releaseDate
                )
                snapshot.appendSections([.summary])
                snapshot.appendItems([.summary(summary)], toSection: .summary)

                if let text = movieDetail.overview {
                    let overview: DetailItem.Overview
                    let truncated = String(text.prefix(300))
                    if text != truncated {
                        overview = .flexible(
                            truncatedText: truncated + "...",
                            fullText: text,
                            isOpen: false
                        )
                    } else {
                        overview = .fixed(text)
                    }
                    snapshot.appendSections([.overview])
                    snapshot.appendItems([.overview(overview)], toSection: .overview)
                }

                if let recommendations = movieDetail.recommendations?.results, !recommendations.isEmpty {
                    let movies = recommendations.map { movie in
                        DetailItem.movie(
                            .init(
                                id: movie.id.rawValue,
                                title: movie.title,
                                imageURL: movie.posterPath?.rawValue
                            )
                        )
                    }
                    snapshot.appendSections([.recommendations])
                    snapshot.appendItems(movies, toSection: .recommendations)
                }

                return (snapshot, thumbnailStatus)
            }
            .eraseToAnyPublisher()
            .multicast(subject: PassthroughSubject())

        let updatedSnapshotAndThumbnailStatus = $isAppeared
            .map { [weak self] isAppeared -> AnyPublisher<(DetailSnapshot, ThumbnailStatus?), Never> in
                guard isAppeared, let me = self else {
                    return Empty().eraseToAnyPublisher()
                }

                return me.$thumbnailStatus
                    .delay(for: 3, scheduler: me.defaultScheduler)
                    .flatMap { thumbnailStatus -> AnyPublisher<(DetailSnapshot, ThumbnailStatus?), Never> in
                        guard
                            let me = self,
                            let thumbnailStatus = thumbnailStatus
                        else {
                            return Empty().eraseToAnyPublisher()
                        }

                        let imageCount = thumbnailStatus.images.count
                        guard imageCount > 1 else {
                            return Empty().eraseToAnyPublisher()
                        }

                        let nextIndex: Int
                        if thumbnailStatus.index + 1 < imageCount {
                            nextIndex = thumbnailStatus.index + 1
                        } else {
                            nextIndex = 0
                        }

                        var snapshot = me.snapshot
                        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .thumbnail))
                        let images = thumbnailStatus.images
                        snapshot.appendItems([.thumbnail(.image(images[nextIndex]))], toSection: .thumbnail)

                        return Just((snapshot, ThumbnailStatus(index: nextIndex, images: images)))
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
            .multicast(subject: PassthroughSubject())

        initialSnapshotAndThumbnailStatus
                .merge(with: updatedSnapshotAndThumbnailStatus)
                .map { $0.0 }
                .assign(to: &$snapshot)

        initialSnapshotAndThumbnailStatus
                .merge(with: updatedSnapshotAndThumbnailStatus)
                .map { $1 }
                .assign(to: &$thumbnailStatus)

        initialSnapshotAndThumbnailStatus
                .connect()
                .store(in: &cancellables)

        updatedSnapshotAndThumbnailStatus
                .connect()
                .store(in: &cancellables)

        model.loadMovieDetail(movieID: movieID)
            .sink { _ in

            }
            .store(in: &cancellables)

        $snapshot
            .receive(on: mainScheduler)
            .sink { [weak self] in
                self?.viewContainer.setSnapshot($0)
            }
            .store(in: &cancellables)

        _didSelectIndexPath
            .throttle(for: 1, scheduler: mainScheduler, latest: false)
            .flatMap { [weak self] indexPath -> AnyPublisher<DetailItem, Never> in
                guard let me = self else {
                    return Empty().eraseToAnyPublisher()
                }
                let section = me.snapshot.sectionIdentifiers[indexPath.section]
                let item = me.snapshot.itemIdentifiers(inSection: section)[indexPath.item]
                return Just(item).eraseToAnyPublisher()
            }
            .sink { [weak self] item in
                switch item {
                case let .movie(viewDataModel):
                    guard let me = self else {
                        return
                    }
                    me.navigator.navigateToDetail(
                        movieID: Movie.ID(rawValue: viewDataModel.id),
                        on: me
                    )

                case let .overview(.flexible(truncatedText, fullText, isOpen)):
                    guard let me = self else {
                        return
                    }
                    var snapshot = me.snapshot
                    snapshot.deleteItems([item])
                    let summary = DetailItem.Overview.flexible(
                        truncatedText: truncatedText,
                        fullText: fullText,
                        isOpen: !isOpen
                    )
                    snapshot.appendItems([.overview(summary)], toSection: .overview)
                    me.snapshot = snapshot

                case .loading,
                    .thumbnail,
                    .summary,
                    .overview(.fixed):
                    return
                }
            }
            .store(in: &cancellables)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isAppeared = true
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isAppeared = false
    }

    private struct ThumbnailStatus: Equatable {
        let index: Int
        let images: [URL]
    }
}

extension DetailViewController: DetailPresenterLike {

    public func didSelectIndexPath(_ indexPath: IndexPath) {
        _didSelectIndexPath.send(indexPath)
    }
}

extension DetailSection {

    public var headerTitle: String? {
        switch self {
        case .recommendations:
            return "Recommendations"
        case .overview:
            return "Overview"
        case .loading,
                .thumbnail,
                .summary:
            return nil
        }
    }
}

extension DetailItem.Overview {

    public var text: String {
        switch self {
        case let .fixed(text):
            return text
        case let .flexible(truncatedText, fullText, isOpen):
            return isOpen ? fullText : truncatedText
        }
    }
}
