//
//  SearchSection.swift
//  ViewDataModel
//
//  Created by marty-suzuki on 2021/09/25.
//

public enum SearchSection: Hashable {
    case movie
    case loading(Loading)
}

extension SearchSection {

    public enum Loading: Hashable {
        case small
        case large
    }
}
