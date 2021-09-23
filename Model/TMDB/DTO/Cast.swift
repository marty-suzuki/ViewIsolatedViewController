//
//  Cast.swift
//  Model
//
//  Created by marty-suzuki on 2021/09/25.
//

import Foundation

public struct Cast: Decodable {
    public typealias ID = _ID<Cast, Int>

    public let id: ID
    public let  name: String
    public let  character: String

    public init(
        id: ID,
        name: String,
        character: String
    ) {
        self.id = id
        self.name = name
        self.character = character
    }
}
