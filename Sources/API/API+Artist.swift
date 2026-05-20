extension API {
    /// Fetches tracks by an artist.
    /// - Parameters:
    ///   - artistId: The artist ID
    ///   - page: Page number (0-based)
    ///   - pageSize: Number of tracks per page
    func getArtistTracks(
        artistID: String,
        page: Int = 0,
        pageSize: Int = 200
    ) async throws -> [Track] {
        let result: ArtistTracks = try await request("artists/\(artistID)/tracks") {
            $0.queryItems(
                .init(name: "page", value: String(page)),
                .init(name: "page-size", value: String(pageSize))
            )
        }
        return result.tracks
    }

    func getLikedArtists(userUID: String, page: Int = 0, pageSize: Int = 20) async throws
        -> (artists: [Artist], pager: Pager)
    {
        let result: LikedArtistsResponse =
            try await request("users/\(userUID)/likes/artists/page") {
                $0.queryItems(
                    .init(name: "page", value: String(page)),
                    .init(name: "pageSize", value: String(pageSize))
                )
            }
        return (result.artists, result.pager)
    }

    func getArtistAlbums(
        artistID: String,
        page: Int = 0,
        pageSize: Int = 20
    ) async throws -> (albums: [Album], pager: Pager) {
        let result: ArtistAlbumsResponse =
            try await request("artists/\(artistID)/direct-albums") {
                $0.queryItems(
                    .init(name: "page", value: String(page)),
                    .init(name: "pageSize", value: String(pageSize)),
                    .init(name: "sort-by", value: "year")
                )
            }
        return (result.albums, result.pager)
    }
}

private struct LikedArtistsResponse: Decodable {
    let artists: [Artist]
    let pager: Pager
}

private struct ArtistAlbumsResponse: Decodable {
    let albums: [Album]
    let pager: Pager
}
