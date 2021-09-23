//
//  MovieImage.swift
//  Model
//
//  Created by marty-suzuki on 2021/09/25.
//

import Foundation

public struct MovieImage: Decodable {

    public let backdrops: [Image]
    public let posters: [Image]

    public init(
        backdrops: [Image],
        posters: [Image]
    ) {
        self.backdrops = backdrops
        self.posters = posters
    }
}
