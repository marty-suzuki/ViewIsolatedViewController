//
//  ViewModelLikeTests.swift
//  ViewModelLikeTests
//
//  Created by marty-suzuki on 2021/10/02.
//

import Combine
import CombineSchedulers
import Model
import ViewDataModel
import ViewModelLike
import XCTest

final class ViewModelLikeTests: XCTestCase {

    private var testTarget: SearchViewController!
    private var viewContainer = ViewContainerMock()
    private let model = SearchModelMock()
    private let navigator = SearchNavigatorMock()
    private let mainScheduer = AnySchedulerOf<DispatchQueue>.immediate
    private var cancellabes = Set<AnyCancellable>()

    override func setUpWithError() throws {
        testTarget = SearchViewController(
            viewContainer: viewContainer.eraseToAnyViewContainer(),
            model: model,
            navigator: navigator,
            mainScheduler: mainScheduer
        )
        testTarget.loadViewIfNeeded()
    }

    override func tearDownWithError() throws {
        cancellabes.removeAll()
    }

    func testSnapshot_moviesPublisher_changed() {
        let snapshot = CurrentValueSubject<SearchSnapshot?, Never>(nil)
        viewContainer._setSnapshot.params
            .sink(receiveValue: snapshot.send)
            .store(in: &cancellabes)

        let movies = [
            Movie(
                id: .init(rawValue: 1),
                title: "test-title",
                posterPath: nil
            )
        ]
        model.movies.send(movies)

        let expected = [
            SearchItem.movie(
                MovieViewDataModel(
                    id: 1,
                    title: "test-title",
                    imageURL: nil
                )
            )
        ]
        XCTAssertEqual(expected, snapshot.value?.itemIdentifiers(inSection: .movie))
    }

    func testSnapshot_isExecutingPublisher_changed_when_movies_existed() {
        let snapshot = CurrentValueSubject<SearchSnapshot?, Never>(nil)
        viewContainer._setSnapshot.params
            .sink(receiveValue: snapshot.send)
            .store(in: &cancellabes)

        let movies = [
            Movie(
                id: .init(rawValue: 1),
                title: "test-title",
                posterPath: nil
            )
        ]
        model.movies.send(movies)
        model.isExecuting.send(true)

        XCTAssertEqual([SearchItem.loading], snapshot.value?.itemIdentifiers(inSection: .loading(.small)))
        XCTAssertNil(snapshot.value?.indexOfSection(.loading(.large)))

        model.isExecuting.send(false)

        XCTAssertNil(snapshot.value?.indexOfSection(.loading(.small)))
        XCTAssertNil(snapshot.value?.indexOfSection(.loading(.large)))
    }

    func testSnapshot_isExecutingPublisher_changed_when_movies_not_existed() {
        let snapshot = CurrentValueSubject<SearchSnapshot?, Never>(nil)
        viewContainer._setSnapshot.params
            .sink(receiveValue: snapshot.send)
            .store(in: &cancellabes)

        model.isExecuting.send(true)

        XCTAssertEqual([SearchItem.loading], snapshot.value?.itemIdentifiers(inSection: .loading(.large)))
        XCTAssertNil(snapshot.value?.indexOfSection(.loading(.small)))

        model.isExecuting.send(false)

        XCTAssertNil(snapshot.value?.indexOfSection(.loading(.small)))
        XCTAssertNil(snapshot.value?.indexOfSection(.loading(.large)))
    }

    func testNavigateToDetail_didSelectIndexPath_called() {
        let id = CurrentValueSubject<Movie.ID?, Never>(nil)
        navigator._navigateToDetail.params
            .sink(receiveValue: id.send)
            .store(in: &cancellabes)

        let expected = Movie.ID(rawValue: 100)
        let movies = [
            Movie(
                id: expected,
                title: "test-title",
                posterPath: nil
            )
        ]
        model.movies.send(movies)

        viewContainer._didSelectIndexPath.send(IndexPath(item: 0, section: 0))
        XCTAssertEqual(expected.rawValue, id.value?.rawValue)
    }

    func testNavigateToError_and_navigateToWebview_searchText_failed() throws {
        let alertModel = CurrentValueSubject<AlertViewDataModel?, Never>(nil)
        navigator._navigateToError.params
            .sink(receiveValue: alertModel.send)
            .store(in: &cancellabes)

        viewContainer._searchText.send("test")

        let errorData = TMDBError.Data(statusCode: 0, statusMessage: "message")
        model._search.send(Result.failure(.invalidApiKey(errorData)))

        XCTAssertEqual("Code: 0", alertModel.value?.title)
        XCTAssertEqual("message See https://developers.themoviedb.org/3/getting-started/introduction.", alertModel.value?.message)

        let action = try XCTUnwrap(alertModel.value?.actions.first)
        XCTAssertEqual("Open", action.title)

        let url = CurrentValueSubject<URL?, Never>(nil)
        navigator._navigateToWebview.params
            .sink(receiveValue: url.send)
            .store(in: &cancellabes)

        action.handler?()

        XCTAssertEqual(
            "https://developers.themoviedb.org/3/getting-started/introduction",
            url.value?.absoluteString
        )
    }

    func testLoadMore_isBottom_changed() {
        viewContainer._didScroll.send((
            CGSize(width: 0, height: 100),
            CGSize(width: 0, height: 100),
            CGPoint(x: 0, y: 1)
        ))
        XCTAssertEqual(0, model._loadMore.calledCount)

        viewContainer._didScroll.send((
            CGSize(width: 0, height: 100),
            CGSize(width: 0, height: 120),
            CGPoint(x: 0, y: 21)
        ))
        XCTAssertEqual(1, model._loadMore.calledCount)
    }
}

extension ViewModelLikeTests {
    private final class PublisherSpy<Parameters, Output, Failure: Error> {

        var params: AnyPublisher<Parameters, Never> {
            _params.eraseToAnyPublisher()
        }
        private let _params = PassthroughSubject<Parameters, Never>()
        private let _responder = PassthroughSubject<Output, Failure>()

        private(set) var calledCount = 0

        func send(_ output: Output) {
            _responder.send(output)
        }

        func send(_ failure: Failure) {
            _responder.send(completion: .failure(failure))
        }

        func respond(_ params: Parameters) -> AnyPublisher<Output, Failure> {
            calledCount += 1
            _params.send(params)
            return _responder.eraseToAnyPublisher()
        }
    }

    private final class ViewContainerMock: SearchInput, SearchOutput, ViewContainer {

        var view: UIView { UIView() }
        var input: SearchInput { self }
        var output: SearchOutput { self }

        let _searchText = PublisherSpy<Void, String?, Never>()
        var searchText: AnyPublisher<String?, Never> {
            _searchText.respond(())
        }

        let _didScroll = PublisherSpy<Void, (CGSize, CGSize, CGPoint), Never>()
        var didScroll: AnyPublisher<(CGSize, CGSize, CGPoint), Never> {
            _didScroll.respond(())
        }

        let _didSelectIndexPath = PublisherSpy<Void, IndexPath, Never>()
        var didSelectIndexPath: AnyPublisher<IndexPath, Never> {
            _didSelectIndexPath.respond(())
        }

        let _setSnapshot = PublisherSpy<SearchSnapshot, Never, Never>()
        func setSnapshot(_ snapshot: SearchSnapshot) {
            _ = _setSnapshot.respond(snapshot)
        }
    }

    private final class SearchNavigatorMock: SearchNavigator {

        let _navigateToDetail = PublisherSpy<Movie.ID, Never, Never>()
        func navigateToDetail(movieID: Movie.ID, on viewController: UIViewController) {
            _ = _navigateToDetail.respond(movieID)
        }

        let _navigateToError = PublisherSpy<AlertViewDataModel, Never, Never>()
        func navigateToError(alert: AlertViewDataModel, on viewController: UIViewController) {
            _ = _navigateToError.respond(alert)
        }

        let _navigateToWebview = PublisherSpy<URL, Never, Never>()
        func navigateToWebview(url: URL, on viewController: UIViewController) {
            _  = _navigateToWebview.respond(url)
        }
    }

    private final class SearchModelMock: SearchModel {

        let movies = PublisherSpy<Void, [Movie], Never>()
        var moviesPulisher: AnyPublisher<[Movie], Never> {
            movies.respond(())
        }

        let isExecuting = PublisherSpy<Void, Bool, Never>()
        var isExecutingPublisher: AnyPublisher<Bool, Never> {
            isExecuting.respond(())
        }

        let _search = PublisherSpy<String, Result<Void, TMDBError>, Never>()
        func search(query: String) -> AnyPublisher<Result<Void, TMDBError>, Never> {
            _search.respond(query)
        }

        let _loadMore = PublisherSpy<Void, Result<Void, TMDBError>, Never>()
        func loadMore() -> AnyPublisher<Result<Void, TMDBError>, Never> {
            _loadMore.respond(())
        }
    }
}
