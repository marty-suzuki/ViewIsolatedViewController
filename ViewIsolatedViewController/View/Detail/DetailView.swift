//
//  DetailView.swift
//  ViewIsolatedViewController
//
//  Created by marty-suzuki on 2021/09/26.
//

import Combine
import PresenterLike
import UIKit
import ViewDataModel

final class DetailView: UIView {
    private typealias DataSource = UICollectionViewDiffableDataSource<DetailSection, DetailItem>

    weak var presenterLike: DetailPresenterLike?

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.register(LoadingView.self, forCellWithReuseIdentifier: CellIdentifiers.loading)
        collectionView.register(DetailThumbnailView.self, forCellWithReuseIdentifier: CellIdentifiers.thumbnail)
        collectionView.register(DetailSummaryView.self, forCellWithReuseIdentifier: CellIdentifiers.sumamry)
        collectionView.register(DetailOverviewView.self, forCellWithReuseIdentifier: CellIdentifiers.overview)
        collectionView.register(MovieView.self, forCellWithReuseIdentifier: CellIdentifiers.movie)
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CellIdentifiers.header)
        return collectionView
    }()

    private lazy var dataSource: DataSource = {
        let dataSrouce = DataSource(
            collectionView: collectionView,
            cellProvider: cellProvider
        )
        dataSrouce.supplementaryViewProvider = supplementaryViewProvider
        return dataSrouce
    }()

    private lazy var cellProvider: DataSource.CellProvider = { collectionView, indexPath, item in
        switch item {
        case .thumbnail(.noImage):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CellIdentifiers.thumbnail,
                for: indexPath
            ) as! DetailThumbnailView
            return cell

        case let .thumbnail(.image(url)):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CellIdentifiers.thumbnail,
                for: indexPath
            ) as! DetailThumbnailView
            cell.configure(imageURL: url)
            return cell

        case let .summary(summary):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CellIdentifiers.sumamry,
                for: indexPath
            ) as! DetailSummaryView
            cell.configure(title: summary.title, release: summary.release)
            return cell

        case let .overview(overview):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CellIdentifiers.overview,
                for: indexPath
            ) as! DetailOverviewView
            cell.configure(text: overview.text)
            return cell

        case let .movie(viewDataModel):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CellIdentifiers.movie,
                for: indexPath
            ) as! MovieView
            cell.configure(title: viewDataModel.title, imageURL: viewDataModel.imageURL)
            return cell

        case .loading:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CellIdentifiers.loading,
                for: indexPath
            ) as! LoadingView
            cell.startAnimation()
            return cell
        }
    }

    private lazy var supplementaryViewProvider: DataSource.SupplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
        self.flatMap {
            switch elementKind {
            case UICollectionView.elementKindSectionHeader:
                return $0.dataSource
                    .snapshot()
                    .sectionIdentifiers[indexPath.section]
                    .headerTitle
                    .map { title in
                        let header = collectionView.dequeueReusableSupplementaryView(
                            ofKind: elementKind,
                            withReuseIdentifier: CellIdentifiers.header,
                            for: indexPath
                        ) as! HeaderView
                        header.configure(title: title)
                        return header
                    }

            case UICollectionView.elementKindSectionFooter:
                return nil

            default:
                return nil
            }
        }
    }

    private lazy var layout: UICollectionViewLayout = {
        UICollectionViewCompositionalLayout { [weak self] section, env in
            return self.flatMap {
                let section = $0.dataSource.snapshot().sectionIdentifiers[section]
                switch section {
                case .thumbnail:
                    return DetailThumbnailView.layoutSection()

                case .summary:
                    return DetailSummaryView.layoutSection()

                case .overview:
                    return DetailOverviewView.layoutSectionWithHeader()

                case .recommendations:
                    return MovieView.layoutSectionWithHeader(itemCount: 3)

                case .loading:
                    return LoadingView.layoutSection(style: .full)
                }
            }
        }
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        collectionView.delegate = self

        backgroundColor = .white

        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum CellIdentifiers {
        static let movie = "movie-cell"
        static let loading = "loading-cell"
        static let thumbnail = "thumbnail-cell"
        static let sumamry = "summary-cell"
        static let overview = "overview-cell"
        static let header = "header"
    }
}

extension DetailView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        presenterLike?.didSelectIndexPath(indexPath)
    }
}

extension DetailView: DetailViewLike {
    func setSnapshot(_ snapshot: DetailSnapshot) {
        dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
    }
}
