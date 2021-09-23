//
//  DetailNavigator.swift
//  ViewIsolatedViewController
//
//  Created by marty-suzuki on 2021/09/26.
//

import CombineSchedulers
import Model
import PresenterLike
import UIKit

final class DetailNavigator: PresenterLike.DetailNavigator {

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
}
