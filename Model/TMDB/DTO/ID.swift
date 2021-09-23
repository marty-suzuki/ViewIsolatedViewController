//
//  ID.swift
//  Model
//
//  Created by marty-suzuki on 2021/09/25.
//

import Foundation

public struct _ID<Root, Value: Decodable>: Decodable {

    public let rawValue: Value

    public init(
        rawValue: Value
    ) {
        self.rawValue = rawValue
    }

    public init(
        from decoder: Decoder
    ) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(Value.self)
    }
}
