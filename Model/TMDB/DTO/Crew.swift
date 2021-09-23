//
//  Crew.swift
//  Model
//
//  Created by marty-suzuki on 2021/09/25.
//

import Foundation

public struct Crew: Decodable {
    public typealias ID = _ID<Crew, Int>

    public let id: ID
    public let  name: String

    public init(
        id: ID,
        name: String
    ) {
        self.id = id
        self.name = name
    }
}
