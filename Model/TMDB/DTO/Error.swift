//
//  ErrorStatus.swift
//  Model
//
//  Created by marty-suzuki on 2021/09/29.
//

import Foundation

public enum TMDBError: Decodable, Error {
    case invalidApiKey(TMDBError.Data)
    case tmdb(TMDBError.Data)
    case other(Error)
}

extension TMDBError {

    public struct Data: Decodable, Swift.Error {
        public let statusCode: Int
        public let statusMessage: String

        public init(
            statusCode: Int,
            statusMessage: String
        ) {
            self.statusCode = statusCode
            self.statusMessage = statusMessage
        }
    }

    public init(from decoder: Decoder) throws {
        let data = try TMDBError.Data(from: decoder)
        switch data.statusCode {
        case 7:
            self = .invalidApiKey(data)
        default:
            self = .other(data)
        }
    }
}
