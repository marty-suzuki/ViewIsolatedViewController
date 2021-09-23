//
//  RootViewController.swift
//  ViewIsolatedViewController
//
//  Created by marty-suzuki on 2021/09/23.
//

import Combine
import CombineSchedulers
import Model
import PresenterLike
import UIKit
import ViewModelLike

final class RootViewController: UINavigationController {

    private let service = try! TheMovieDatabaseServiceImpl(
        infoDictionary: Bundle.main.infoDictionary!
    ) {
        URLSession.shared
            .dataTaskPublisher(for: $0)
            .eraseToAnyPublisher()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewModelLike = SearchViewController(
            viewContainer: SearchView(frame: .zero).eraseToAnyViewContainer(),
            model: SearcModelImpl(service: service),
            navigator: SearchNavigator(service: service),
            mainScheduler: .main
        )

        setViewControllers([viewModelLike], animated: false)
    }
}
