//
//  DetailModel.swift
//  Model
//
//  Created by marty-suzuki on 2021/09/26.
//

import Combine
import Foundation

public protocol DetailModel {
    var isExecutingPublisher: AnyPublisher<Bool, Never> { get }
    var movieDetailPublisher: AnyPublisher<MovieDetail, Never> { get }
    func loadMovieDetail(movieID: Movie.ID) -> AnyPublisher<Result<Void, Error>, Never>
}

public final class DetailModelImpl: DetailModel {

    public var isExecutingPublisher: AnyPublisher<Bool, Never> {
        $isExecuting.eraseToAnyPublisher()
    }

    public var movieDetailPublisher: AnyPublisher<MovieDetail, Never> {
        $movieDetail
            .flatMap { movieDetail -> AnyPublisher<MovieDetail, Never> in
                movieDetail.map { Just($0).eraseToAnyPublisher() }
                    ?? Empty().eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private let service: TheMovieDatabaseService
    @Published var movieDetail: MovieDetail?
    @Published var isExecuting = false

    public init(
        service: TheMovieDatabaseService
    ) {
        self.service = service
    }

    public func loadMovieDetail(movieID: Movie.ID) -> AnyPublisher<Result<Void, Error>, Never> {
        isExecuting = true
        return service.movieDetail(movieID: movieID)
            .handleEvents(
                receiveOutput: { [weak self] in
                    self?.movieDetail = $0
                },
                receiveCompletion: { [weak self] _ in
                    self?.isExecuting = false
                }
            )
            .map { _ in
                Result<Void, Error>.success(())
            }
            .catch {
                Just(Result<Void, Error>.failure($0))
            }
            .eraseToAnyPublisher()
    }
}
