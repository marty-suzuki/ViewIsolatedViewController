//
//  MovieViewDataModel.swift
//  ViewDataModel
//
//  Created by marty-suzuki on 2021/09/25.
//

public struct MovieViewDataModel: Hashable {

    public let id: Int
    public let title: String
    public let imageURL: URL?

    public init(
        id: Int,
        title: String,
        imageURL: URL?
    ) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
    }
}
