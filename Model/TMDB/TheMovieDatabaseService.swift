//
//  TheMovieDatabaseService.swift
//  Model
//
//  Created by marty-suzuki on 2021/09/25.
//

import Combine
import Foundation

public protocol TheMovieDatabaseService: AnyObject {
    func movies(query: String, page: Int) -> AnyPublisher<ListResponse<Movie>, TMDBError>
    func movieDetail(movieID: Movie.ID) -> AnyPublisher<MovieDetail, TMDBError>
}

public final class TheMovieDatabaseServiceImpl: TheMovieDatabaseService {

    private let apiKey: ApiKey
    private let sendRequest: (URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError>

    public init(
        infoDictionary: [String: Any],
        sendRequest: @escaping (URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
    ) throws {
        let data = try JSONSerialization.data(
            withJSONObject: infoDictionary,
            options: .fragmentsAllowed
        )
        self.apiKey = try JSONDecoder().decode(ApiKey.self, from: data)
        self.sendRequest = sendRequest
    }

    public func movies(query: String, page: Int) -> AnyPublisher<ListResponse<Movie>, TMDBError> {
        sendGetRequest(
            path: "search/movie",
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: "\(page)")
            ]
        )
    }

    public func movieDetail(movieID: Movie.ID) -> AnyPublisher<MovieDetail, TMDBError> {
        sendGetRequest(
            path: "movie/\(movieID.rawValue)",
            queryItems: [
                URLQueryItem(name: "append_to_response", value: "images,recommendations,credits")
            ]
        )
    }

    private func sendGetRequest<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]
    ) -> AnyPublisher<T, TMDBError> {
        do {
            var components = try URLComponents(string: Const.baseURLString + path)
                ?? { throw NSError() }()
            components.queryItems = queryItems + [
                URLQueryItem(name: "api_key", value: apiKey.rawValue)
            ]

            let request = try components.url.map { URLRequest(url: $0) } ?? { throw NSError() }()

            return sendRequest(request)
                .tryMap { data, response in
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    guard
                        let response = response as? HTTPURLResponse,
                        (200..<300) ~= response.statusCode
                    else {
                        throw try decoder.decode(TMDBError.self, from: data)
                    }
                    return try decoder.decode(T.self, from: data)
                }
                .catch { error -> Fail in
                    if let error = error as? TMDBError {
                        return Fail(error: error)
                    } else {
                        return Fail(error: .other(error))
                    }
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: .other(error)).eraseToAnyPublisher()
        }
    }

    private enum Const {
        static let baseURLString = "https://api.themoviedb.org/3/"
    }

    fileprivate struct ApiKey: RawRepresentable {
        let rawValue: String
    }
}

extension TheMovieDatabaseServiceImpl.ApiKey: Decodable {

    enum CodingKeys: String, CodingKey {
        case apiKey = "TMDB_API_KEY_V3_AUTH"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(rawValue: try container.decode(String.self, forKey: .apiKey))
    }
}
