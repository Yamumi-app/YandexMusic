import Foundation

public struct SearchMixedResponse: Sendable, Decodable {
    public let searchRequestId: String?
    public let text: String?
    public let misspellCorrected: Bool?
    public let misspellResult: String?
    public let lastPage: Bool?
    public let total: Int?
    public let perPage: Int?
    public let results: [SearchResult]
    public let bestResults: [SearchBestResult]
    public let responseType: String?

    private enum CodingKeys: String, CodingKey {
        case searchRequestId
        case text
        case misspellCorrected
        case misspellResult
        case lastPage
        case total
        case perPage
        case results
        case bestResults
        case responseType
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        searchRequestId = try container.decodeIfPresent(
            String.self,
            forKey: .searchRequestId
        )
        text = try container.decodeIfPresent(String.self, forKey: .text)
        misspellCorrected = try container.decodeIfPresent(
            Bool.self,
            forKey: .misspellCorrected
        )
        misspellResult = try container.decodeIfPresent(
            String.self,
            forKey: .misspellResult
        )
        lastPage = try container.decodeIfPresent(Bool.self, forKey: .lastPage)
        total = try container.decodeIfPresent(Int.self, forKey: .total)
        perPage = try container.decodeIfPresent(Int.self, forKey: .perPage)
        responseType = try container.decodeIfPresent(String.self, forKey: .responseType)

        let decodedResults =
            try container.decodeIfPresent(
                [RawSearchResult].self,
                forKey: .results
            ) ?? []
        results = decodedResults.compactMap(\.value)

        let decodedBestResults =
            try container.decodeIfPresent(
                [RawSearchBestResult].self,
                forKey: .bestResults
            ) ?? []
        bestResults = decodedBestResults.compactMap(\.value)
    }
}

public enum SearchResult: Sendable {
    case track(Track)
    case album(Album)
    case artist(Artist)
}

public enum SearchBestResult: Sendable {
    case album(SearchBestAlbum)
    case artist(SearchBestArtist)
    case track(Track)
}

public struct SearchBestAlbum: Sendable, Decodable {
    public let album: SearchBestAlbumDetails
    public let artists: [Artist]?

    private enum CodingKeys: String, CodingKey {
        case album
        case artists
    }
}

public struct SearchBestAlbumDetails: Sendable, Decodable {
    public let id: Int
    public let title: String?
    public let cover: SearchBestCover?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case cover
    }
}

public struct SearchBestArtist: Sendable, Decodable {
    public let artist: Artist

    private enum CodingKeys: String, CodingKey {
        case artist
    }
}

public struct SearchBestCover: Sendable, Decodable {
    public let uri: URLTemplate?

    private enum CodingKeys: String, CodingKey {
        case uri
    }
}

private struct RawSearchResult: Decodable {
    let value: SearchResult?

    private enum CodingKeys: String, CodingKey {
        case type
        case track
        case album
        case artist
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type)

        switch type {
        case "track":
            if let track = try container.decodeIfPresent(Track.self, forKey: .track) {
                value = .track(track)
            } else {
                value = nil
            }
        case "album":
            if let album = try container.decodeIfPresent(Album.self, forKey: .album) {
                value = .album(album)
            } else {
                value = nil
            }
        case "artist":
            if let artist = try container.decodeIfPresent(Artist.self, forKey: .artist) {
                value = .artist(artist)
            } else {
                value = nil
            }
        default:
            value = nil
        }
    }
}

private struct RawSearchBestResult: Decodable {
    let value: SearchBestResult?

    private enum CodingKeys: String, CodingKey {
        case type
        case bestResultAlbum
        case bestResultArtist
        case bestResultTrack
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type)

        switch type {
        case "best_result_album":
            if let album = try container.decodeIfPresent(
                SearchBestAlbum.self,
                forKey: .bestResultAlbum
            ) {
                value = .album(album)
            } else {
                value = nil
            }
        case "best_result_artist":
            if let artist = try container.decodeIfPresent(
                SearchBestArtist.self,
                forKey: .bestResultArtist
            ) {
                value = .artist(artist)
            } else {
                value = nil
            }
        case "best_result_track":
            if let track = try container.decodeIfPresent(
                Track.self,
                forKey: .bestResultTrack
            ) {
                value = .track(track)
            } else {
                value = nil
            }
        default:
            value = nil
        }
    }
}
