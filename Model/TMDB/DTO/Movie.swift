//
//  Movie.swift
//  Model
//
//  Created by marty-suzuki on 2021/09/25.
//

import Foundation

public struct Movie: Decodable {
    public typealias ID = _ID<Movie, Int>

    public let id: ID
    public let title: String
    public let posterPath: ImageURL?

    public init(
        id: ID,
        title: String,
        posterPath: ImageURL?
    ) {
        self.id = id
        self.title = title
        self.posterPath = posterPath
    }
}
