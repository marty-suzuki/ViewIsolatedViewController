//
//  PresenterLikeTests.swift
//  PresenterLikeTests
//
//  Created by marty-suzuki on 2021/10/02.
//

import Combine
import CombineSchedulers
import Model
import PresenterLike
import ViewDataModel
import XCTest

final class PresenterLikeTests: XCTestCase {

    private var testTarget: DetailViewController!
    private let movieID = Movie.ID(rawValue: 100)
    private let model = DetailModelMock()
    private let navigator = DetailNavigatorMock()
    private let viewContainer = DetailViewLikeMock()
    private let testScheduler = DispatchQueue.test
    private var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        testTarget = DetailViewController(
            movieID: movieID,
            viewContainer: viewContainer,
            model: model,
            navigator: navigator,
            mainScheduler: .immediate,
            defaultScheduler: testScheduler.eraseToAnyScheduler()
        )
        testTarget.loadViewIfNeeded()
    }

    override func tearDownWithError() throws {
        cancellables.removeAll()
    }

    func testSnapshot_movieDetailPublisher_changed() {
        let snapshot = CurrentValueSubject<DetailSnapshot?, Never>(nil)
        viewContainer._setSnapshot.params
            .sink(receiveValue: snapshot.send)
            .store(in: &cancellables)

        try! setUpWithError()

        XCTAssertEqual(
            [DetailItem.loading],
            snapshot.value?.itemIdentifiers
        )

        let detail = MovieDetail(
            id: movieID,
            title: "title",
            posterPath: nil,
            backdropPath: nil,
            overview: "overview",
            releaseDate: "2000-01-01",
            runtime: 100,
            credits: nil,
            recommendations: ListResponse(
                page: 1,
                results: [
                    Movie(
                        id: .init(rawValue: 200),
                        title: "title2",
                        posterPath: nil
                    )
                ],
                totalResults: 1,
                totalPages: 1
            ),
            images: MovieImage(
                backdrops: [
                    Image(filePath: .init(rawValue: URL(string: "https://sample.com/image/1")!))
                ],
                posters: []
            )
        )
        model.movieDetail.send(detail)

        XCTAssertEqual(
            [
                DetailItem.thumbnail(.image(URL(string: "https://sample.com/image/1")!)),
                DetailItem.summary(.init(title: "title", release: "2000-01-01")),
                DetailItem.overview(.fixed("overview")),
                DetailItem.movie(.init(id: 200, title: "title2", imageURL: nil))
            ],
            snapshot.value?.itemIdentifiers
        )

        testTarget.viewDidAppear(false)
        testScheduler.advance(by: 3)

        XCTAssertEqual(
            [
                DetailItem.thumbnail(.image(URL(string: "https://sample.com/image/1")!)),
                DetailItem.summary(.init(title: "title", release: "2000-01-01")),
                DetailItem.overview(.fixed("overview")),
                DetailItem.movie(.init(id: 200, title: "title2", imageURL: nil))
            ],
            snapshot.value?.itemIdentifiers
        )

        viewContainer.presenterLike?.didSelectIndexPath(IndexPath(item: 0, section: 2))

        XCTAssertEqual(
            [
                DetailItem.thumbnail(.image(URL(string: "https://sample.com/image/1")!)),
                DetailItem.summary(.init(title: "title", release: "2000-01-01")),
                DetailItem.overview(.fixed("overview")),
                DetailItem.movie(.init(id: 200, title: "title2", imageURL: nil))
            ],
            snapshot.value?.itemIdentifiers
        )

        let navigateToDetail = CurrentValueSubject<Movie.ID?, Never>(nil)
        navigator._navigateToDetail.params
            .sink(receiveValue: navigateToDetail.send)
            .store(in: &cancellables)

        viewContainer.presenterLike?.didSelectIndexPath(IndexPath(item: 0, section: 3))

        XCTAssertEqual(200, navigateToDetail.value?.rawValue)
    }

    func testSnapshot_movieDetailPublisher_changed_multiple_images() {
        let snapshot = CurrentValueSubject<DetailSnapshot?, Never>(nil)
        viewContainer._setSnapshot.params
            .sink(receiveValue: snapshot.send)
            .store(in: &cancellables)

        let detail = MovieDetail(
            id: movieID,
            title: "title",
            posterPath: nil,
            backdropPath: nil,
            overview: "overview",
            releaseDate: "2000-01-01",
            runtime: 100,
            credits: nil,
            recommendations: nil,
            images: MovieImage(
                backdrops: [
                    Image(filePath: .init(rawValue: URL(string: "https://sample.com/image/1")!)),
                    Image(filePath: .init(rawValue: URL(string: "https://sample.com/image/2")!))
                ],
                posters: []
            )
        )
        model.movieDetail.send(detail)

        let patterns: [(Bool?, Bool, Int, UInt)] = [
            (nil, false, 1, #line),
            (true, true, 2, #line),
            (nil, true, 1, #line),
            (false, true, 1, #line)
        ]

        patterns.forEach { shouldViewAppear, shouldAdvence, id, line in
            switch shouldViewAppear {
            case true?:
                testTarget.viewDidAppear(false)
            case false?:
                testTarget.viewDidDisappear(false)
            case .none:
                break
            }
            if shouldAdvence {
                testScheduler.advance(by: 3)
            }
            XCTAssertEqual(
                [
                    DetailItem.thumbnail(.image(URL(string: "https://sample.com/image/\(id)")!)),
                    DetailItem.summary(.init(title: "title", release: "2000-01-01")),
                    DetailItem.overview(.fixed("overview"))
                ],
                snapshot.value?.itemIdentifiers,
                line: line
            )
        }
    }

    func testSnapshot_movieDetailPublisher_changed_over300chars_overview() {
        let snapshot = CurrentValueSubject<DetailSnapshot?, Never>(nil)
        viewContainer._setSnapshot.params
            .sink(receiveValue: snapshot.send)
            .store(in: &cancellables)

        let fullOverview = (0...301).map { _ in "a" }.joined()
        let truncatedOverview = String(fullOverview.prefix(300)) + "..."

        let detail = MovieDetail(
            id: movieID,
            title: "title",
            posterPath: nil,
            backdropPath: nil,
            overview: fullOverview,
            releaseDate: "2000-01-01",
            runtime: 100,
            credits: nil,
            recommendations: nil,
            images: nil
        )
        model.movieDetail.send(detail)

        let patterns: [(Bool, Bool, String, UInt)] = [
            (false, false, truncatedOverview, #line),
            (true, true, fullOverview, #line),
            (true, false, truncatedOverview, #line),
        ]

        patterns.forEach { shouldSelect, isOpen, overviewText, line in
            if shouldSelect {
                viewContainer.presenterLike?.didSelectIndexPath(IndexPath(item: 0, section: 2))
            }

            let overview = DetailItem.Overview.flexible(
                truncatedText: truncatedOverview,
                fullText: fullOverview,
                isOpen: isOpen
            )

            XCTAssertEqual(
                [
                    DetailItem.thumbnail(.noImage),
                    DetailItem.summary(.init(title: "title", release: "2000-01-01")),
                    DetailItem.overview(overview)
                ],
                snapshot.value?.itemIdentifiers,
                line: line
            )

            XCTAssertEqual(overviewText, overview.text, line: line)
        }
    }
}

extension PresenterLikeTests {
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

    private final class DetailViewLikeMock: DetailViewLike {

        weak var presenterLike: DetailPresenterLike?
        var view: UIView { UIView() }

        let _setSnapshot = PublisherSpy<DetailSnapshot, Never, Never>()
        func setSnapshot(_ snapshot: DetailSnapshot) {
            _ = _setSnapshot.respond(snapshot)
        }
    }

    private final class DetailNavigatorMock: DetailNavigator {

        let _navigateToDetail = PublisherSpy<Movie.ID, Never, Never>()
        func navigateToDetail(movieID: Movie.ID, on viewController: UIViewController) {
            _ = _navigateToDetail.respond(movieID)
        }
    }

    private final class DetailModelMock: DetailModel {

        let isExecting = PublisherSpy<Void, Bool, Never>()
        var isExecutingPublisher: AnyPublisher<Bool, Never> {
            isExecting.respond(())
        }

        let movieDetail = PublisherSpy<Void, MovieDetail, Never>()
        var movieDetailPublisher: AnyPublisher<MovieDetail, Never> {
            movieDetail.respond(())
        }

        let _loadMovieDetail = PublisherSpy<Movie.ID, Result<Void, Error>, Never>()
        func loadMovieDetail(movieID: Movie.ID) -> AnyPublisher<Result<Void, Error>, Never> {
            _loadMovieDetail.respond(movieID)
        }
    }
}
