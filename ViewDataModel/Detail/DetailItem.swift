//
//  DetailItem.swift
//  ViewDataModel
//
//  Created by marty-suzuki on 2021/09/28.
//

import Foundation

public enum DetailItem: Hashable {
    case loading
    case thumbnail(Thumbnail)
    case summary(Summary)
    case overview(Overview)
    case movie(MovieViewDataModel)
}

extension DetailItem {

    public enum Thumbnail: Hashable {
        case image(URL)
        case noImage
    }

    public struct Summary: Hashable {
        public let title: String
        public let release: String

        public init(
            title: String,
            release: String
        ) {
            self.title = title
            self.release = release
        }
    }

    public enum Overview: Hashable {
        case fixed(String)
        case flexible(truncatedText: String, fullText: String, isOpen: Bool)
    }
}
