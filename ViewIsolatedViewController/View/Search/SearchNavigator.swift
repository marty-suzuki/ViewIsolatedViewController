//
//  ViewModelLikeSearchNavigator.swift
//  ViewIsolatedViewController
//
//  Created by marty-suzuki on 2021/09/26.
//

import CombineSchedulers
import Model
import PresenterLike
import SafariServices
import UIKit
import ViewDataModel
import ViewModelLike

final class SearchNavigator: ViewModelLike.SearchNavigator {

    private let service: TheMovieDatabaseService

    init(
        service: TheMovieDatabaseService
    ) {
        self.service = service
    }

    func navigateToDetail(movieID: Movie.ID, on viewController: UIViewController) {
        let vc = DetailViewController(
            movieID: movieID,
            viewContainer: DetailView(frame: .zero),
            model: DetailModelImpl(service: service),
            navigator: DetailNavigator(service: service),
            mainScheduler: .main,
            defaultScheduler: AnySchedulerOf<DispatchQueue>(DispatchQueue.global())
        )
        viewController.navigationController?.pushViewController(vc, animated: true)
    }

    func navigateToError(alert: AlertViewDataModel, on viewController: UIViewController) {
        let vc = UIAlertController(title: alert.title, message: alert.message, preferredStyle: .alert)
        alert.actions.forEach { action in
            let action = UIAlertAction(
                title: action.title,
                style: action.style
            ) { _ in
                action.handler?()
            }
            vc.addAction(action)
        }
        viewController.present(vc, animated: true, completion: nil)
    }

    func navigateToWebview(url: URL, on viewController: UIViewController) {
        let vc = SFSafariViewController(url: url)
        viewController.present(vc, animated: true, completion: nil)
    }
}
