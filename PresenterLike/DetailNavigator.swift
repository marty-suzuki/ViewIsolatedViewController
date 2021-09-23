//
//  DetailNavigator.swift
//  PresenterLike
//
//  Created by marty-suzuki on 2021/09/28.
//

import Model
import UIKit

public protocol DetailNavigator {
    func navigateToDetail(
        movieID: Movie.ID,
        on viewController: UIViewController
    )
}

