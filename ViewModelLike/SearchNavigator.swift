//
//  SearchNavigator.swift
//  ViewModelLike
//
//  Created by marty-suzuki on 2021/09/28.
//

import Model
import UIKit
import ViewDataModel

public protocol SearchNavigator {
    func navigateToDetail(
        movieID: Movie.ID,
        on viewController: UIViewController
    )
    
    func navigateToError(
        alert: AlertViewDataModel,
        on viewController: UIViewController
    )

    func navigateToWebview(
        url: URL,
        on viewController: UIViewController
    )
}
