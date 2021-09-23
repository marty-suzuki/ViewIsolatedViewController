//
//  Credit.swift
//  Model
//
//  Created by marty-suzuki on 2021/09/25.
//

import Foundation

public struct Credit: Decodable {

    public let cast: [Cast]
    public let crew: [Crew]

    public init(
        cast: [Cast],
        crew: [Crew]
    ) {
        self.cast = cast
        self.crew = crew
    }
}
