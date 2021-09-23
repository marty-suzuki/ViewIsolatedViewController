//
//  Image.swift
//  Model
//
//  Created by marty-suzuki on 2021/09/25.
//

import Foundation

public struct Image: Decodable {

    public let filePath: ImageURL

    public init(
        filePath: ImageURL
    ) {
        self.filePath = filePath
    }
}
