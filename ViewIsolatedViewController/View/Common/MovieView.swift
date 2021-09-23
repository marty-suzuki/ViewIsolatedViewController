//
//  MovieView.swift
//  ViewIsolatedViewController
//
//  Created by marty-suzuki on 2021/09/25.
//

import Nuke
import UIKit
import ViewDataModel

final class MovieView: UICollectionViewCell {

    private let imageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 12)
        return label
    }()

    private var imageTask: ImageTask?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .lightGray

        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])

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

    func configure(title: String, imageURL: URL?) {
        titleLabel.text = title
        var options = ImageLoadingOptions.shared
        options.transition = .fadeIn(duration: 0.3)
        imageTask = loadImage(
            with: imageURL,
            options: options,
            into: imageView
        )
    }
}

extension MovieView {

    static func layoutSection(itemCount: Int) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalHeight(1)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalWidth(1.5 / CGFloat(itemCount))
            ),
            subitem: item,
            count: itemCount
        )
        group.interItemSpacing = .fixed(1)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 1
        return section
    }

    static func layoutSectionWithHeader(itemCount: Int) -> NSCollectionLayoutSection {
        let section = layoutSection(itemCount: itemCount)
        section.boundarySupplementaryItems = [
            NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(44)
                ),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
        ]
        return section
    }
}
