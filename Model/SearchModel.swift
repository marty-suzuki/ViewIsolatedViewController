//
//  SearchModel.swift
//  Model
//
//  Created by marty-suzuki on 2021/09/25.
//

import Combine
import Foundation

public protocol SearchModel: AnyObject {
    var moviesPulisher: AnyPublisher<[Movie], Never> { get }
    var isExecutingPublisher: AnyPublisher<Bool, Never> { get }
    func search(query: String) -> AnyPublisher<Result<Void, TMDBError>, Never>
    func loadMore() -> AnyPublisher<Result<Void, TMDBError>, Never>
}

public final class SearcModelImpl: SearchModel {

    public var moviesPulisher: AnyPublisher<[Movie], Never> {
        $movies.eraseToAnyPublisher()
    }
    public var isExecutingPublisher: AnyPublisher<Bool, Never> {
        $isExecuting.eraseToAnyPublisher()
    }

    private let service: TheMovieDatabaseService

    private var nextRequest: NextRequest?
    @Published private var movies: [Movie] = []
    @Published private var isExecuting = false

    public init(
        service: TheMovieDatabaseService
    ) {
        self.service = service
    }

    public func search(query: String) -> AnyPublisher<Result<Void, TMDBError>, Never> {
        nextRequest = nil
        return fetchMovies(query: query, page: 1)
    }

    public func loadMore() -> AnyPublisher<Result<Void, TMDBError>, Never> {
        guard
            !isExecuting,
            case let .existed(query, page) = nextRequest
        else {
            return Empty().eraseToAnyPublisher()
        }
        return fetchMovies(query: query, page: page)
    }

    private func fetchMovies(
        query: String,
        page: Int
    ) -> AnyPublisher<Result<Void, TMDBError>, Never> {
        isExecuting = true
        return service.movies(query: query, page: page)
            .handleEvents(
                receiveOutput: { [weak self] in
                    if page < $0.totalPages {
                        self?.nextRequest = .existed(query: query, page: page + 1)
                    } else {
                        self?.nextRequest = .notExisted
                    }
                    if page > 1 {
                        self?.movies += $0.results
                    } else {
                        self?.movies = $0.results
                    }
                },
                receiveCompletion: { [weak self] _ in
                    self?.isExecuting = false
                }
            )
            .map { _ in
                Result<Void, TMDBError>.success(())
            }
            .catch {
                Just(Result<Void, TMDBError>.failure($0))
            }
            .eraseToAnyPublisher()
    }

    private enum NextRequest: Equatable {
        case existed(query: String, page: Int)
        case notExisted
    }
}
