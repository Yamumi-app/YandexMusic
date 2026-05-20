extension API {
    /// Fetches an album with all its tracks.
    func getAlbumWithTracks(albumID: String) async throws -> Album {
        try await request("albums/\(albumID)/with-tracks") as Album
    }

    func getUserAlbums(
        userUID: String,
        page: Int,
        pageSize: Int = 20
    ) async throws -> (albums: [Album], pager: Pager) {
        let response: UserAlbumsResponse =
            try await request("users/\(userUID)/likes/albums/page") {
                $0.queryItems(
                    .init(name: "rich", value: "true"),
                    .init(name: "page", value: String(page)),
                    .init(name: "pageSize", value: String(pageSize)),
                    .init(name: "metaType", value: "music")
                )
            }
        let albums = response.albums.map(\.album)
        return (albums, response.pager)
    }
}

private struct UserAlbum: Decodable {
    let album: Album
}

private struct UserAlbumsResponse: Decodable {
    let albums: [UserAlbum]
    let pager: Pager
}
