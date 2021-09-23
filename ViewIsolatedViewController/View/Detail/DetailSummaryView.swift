//
//  DetailSummaryView.swift
//  ViewIsolatedViewController
//
//  Created by marty-suzuki on 2021/09/29.
//

import UIKit

final class DetailSummaryView: UICollectionViewCell {

    private let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .darkGray
        label.font = .boldSystemFont(ofSize: 28)
        label.numberOfLines = 0
        return label
    }()

    private let releaseLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .darkGray
        label.font = .boldSystemFont(ofSize: 18)
        label.numberOfLines = 1
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])

        addSubview(releaseLabel)
        NSLayoutConstraint.activate([
            releaseLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            releaseLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            releaseLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            releaseLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])

    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        releaseLabel.text = nil
    }

    func configure(
        title: String,
        release: String
    ) {
        titleLabel.text = title
        releaseLabel.text = release
    }
}

extension DetailSummaryView {

    static func layoutSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(44)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(44)
            ),
            subitem: item,
            count: 1
        )

        return NSCollectionLayoutSection(group: group)
    }
}
