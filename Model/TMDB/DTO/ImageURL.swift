//
//  ImageURL.swift
//  Model
//
//  Created by marty-suzuki on 2021/09/25.
//

import Foundation

public struct ImageURL: Decodable {

    public let rawValue: URL

    public init(
        rawValue: URL
    ) {
        self.rawValue = rawValue
    }

    public init(
        from decoder: Decoder
    ) throws {
        let container = try decoder.singleValueContainer()
        let path = try container.decode(String.self)
        self.rawValue = URL(string: "https://image.tmdb.org/t/p/w500" + path)!
    }
}
