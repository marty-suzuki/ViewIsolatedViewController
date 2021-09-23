//
//  SearchView.swift
//  ViewIsolatedViewController
//
//  Created by marty-suzuki on 2021/09/25.
//

import Combine
import UIKit
import ViewDataModel
import ViewModelLike

final class SearchView: UIView {
    private typealias DataSource = UICollectionViewDiffableDataSource<SearchSection, SearchItem>

    private let _searchText = PassthroughSubject<String?, Never>()
    private let _didScroll = PassthroughSubject<(CGSize, CGSize, CGPoint), Never>()
    private let _didSelectIndexPath = PassthroughSubject<IndexPath, Never>()

    private let searchBar: UISearchBar = {
        let view = UISearchBar(frame: .zero)
        view.showsCancelButton = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return view
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.register(MovieView.self, forCellWithReuseIdentifier: CellIdentifiers.movie)
        collectionView.register(LoadingView.self, forCellWithReuseIdentifier: CellIdentifiers.loading)
        return collectionView
    }()

    private lazy var dataSource = DataSource(
        collectionView: collectionView,
        cellProvider: cellProvider
    )

    private lazy var cellProvider: DataSource.CellProvider = { collectionView, indexPath, item in
        switch item {
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

    private lazy var layout: UICollectionViewLayout = {
        UICollectionViewCompositionalLayout { [weak self] section, env in
            return self.flatMap {
                let section = $0.dataSource.snapshot().sectionIdentifiers[section]
                switch section {
                case .movie:
                    return MovieView.layoutSection(itemCount: 3)

                case let .loading(size):
                    switch size {
                    case .large:
                        return LoadingView.layoutSection(style: .full)
                    case .small:
                        return LoadingView.layoutSection(style: .fixed(64))
                    }
                }
            }
        }
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        searchBar.delegate = self
        collectionView.delegate = self

        backgroundColor = .white

        addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
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
    }
}

extension SearchView: UISearchBarDelegate {

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        _searchText.send(searchBar.text)
    }
}

extension SearchView: UICollectionViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        _didScroll.send(
            (
                scrollView.bounds.size,
                scrollView.contentSize,
                scrollView.contentOffset
            )
        )
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        _didSelectIndexPath.send(indexPath)
    }
}

extension SearchView: SearchInput {

    func setSnapshot(_ snapshot: SearchSnapshot) {
        dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
    }
}

extension SearchView: SearchOutput {

    var didSelectIndexPath: AnyPublisher<IndexPath, Never> {
        _didSelectIndexPath.eraseToAnyPublisher()
    }

    var didScroll: AnyPublisher<(CGSize, CGSize, CGPoint), Never> {
        _didScroll.eraseToAnyPublisher()
    }

    var searchText: AnyPublisher<String?, Never> {
        _searchText.eraseToAnyPublisher()
    }
}

extension SearchView: ViewContainer {
    var input: SearchInput { self }
    var output: SearchOutput { self }
}
