//
//  MovieDetail.swift
//  Model
//
//  Created by marty-suzuki on 2021/09/25.
//

import Foundation

public struct MovieDetail: Decodable {

    public let id: Movie.ID
    public let title: String
    public let posterPath: ImageURL?
    public let backdropPath: ImageURL?
    public let overview: String?
    public let releaseDate: String
    public let runtime: Int
    public let credits: Credit?
    public let recommendations: ListResponse<Movie>?
    public let images: MovieImage?

    public init(
        id: Movie.ID,
        title: String,
        posterPath: ImageURL?,
        backdropPath: ImageURL?,
        overview: String?,
        releaseDate: String,
        runtime: Int,
        credits: Credit?,
        recommendations: ListResponse<Movie>?,
        images: MovieImage?
    ) {
        self.id = id
        self.title = title
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.overview = overview
        self.releaseDate = releaseDate
        self.runtime = runtime
        self.credits = credits
        self.recommendations = recommendations
        self.images = images
    }
}
