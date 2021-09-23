//
//  ListResponse.swift
//  Model
//
//  Created by marty-suzuki on 2021/09/25.
//

import Foundation

public struct ListResponse<T: Decodable>: Decodable {

    public let page: Int
    public let results: [T]
    public let totalResults: Int
    public let totalPages: Int

    public init(
        page: Int,
        results: [T],
        totalResults: Int,
        totalPages: Int
    ) {
        self.page = page
        self.results = results
        self.totalResults = totalResults
        self.totalPages = totalPages
    }
}
