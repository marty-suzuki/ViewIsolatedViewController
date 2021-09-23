//
//  DetailThumbnailView.swift
//  ViewIsolatedViewController
//
//  Created by marty-suzuki on 2021/09/28.
//

import Nuke
import UIKit

final class DetailThumbnailView: UICollectionViewCell {

    private let imageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 9 / 16).isActive = true
        return view
    }()

    private var imageTask: ImageTask?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        imageView.image = nil
    }

    func configure(imageURL: URL) {
        var options = ImageLoadingOptions.shared
        options.transition = .fadeIn(duration: 0.3)
        imageTask = loadImage(
            with: imageURL,
            options: options,
            into: imageView
        )
    }
}

extension DetailThumbnailView {

    static func layoutSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(9/16)
            ),
            subitem: item,
            count: 1
        )

        return NSCollectionLayoutSection(group: group)
    }
}
