//
//  LoadingView.swift
//  ViewIsolatedViewController
//
//  Created by marty-suzuki on 2021/09/26.
//

import UIKit

final class LoadingView: UICollectionViewCell {

    private let indicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        view.hidesWhenStopped = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(indicatorView)
        NSLayoutConstraint.activate([
            indicatorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            indicatorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        indicatorView.stopAnimating()
    }

    func startAnimation() {
        indicatorView.startAnimating()
    }
}

extension LoadingView {

    enum Style {
        case full
        case fixed(CGFloat)
    }


    static func layoutSection(
        style: Style
    ) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )

        let heightDimension: NSCollectionLayoutDimension
        switch style {
        case .full:
            heightDimension = .fractionalHeight(1.0)
        case let .fixed(height):
            heightDimension = .absolute(height)
        }

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: heightDimension
            ),
            subitem: item,
            count: 1
        )

        return NSCollectionLayoutSection(group: group)
    }
}
