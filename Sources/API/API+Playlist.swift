extension API {
    /// Fetches the current user's playlists.
    func getUserPlaylists(userUID: String) async throws -> [Playlist] {
        try await request("users/\(userUID)/playlists/list") as [Playlist]
    }

    /// Fetches personal playlists from the landing blocks endpoint.
    func getPersonalPlaylists() async throws -> [PersonalPlaylistItem] {
        let response: PersonalPlaylistsResponse =
            try await request("landing-blocks/personal-playlists") {
                $0.userAgent(.desktopApp)
            }
        return response.items
    }

    /// Fetches a playlist by its UUID (public share link format).
    func getPlaylist(uuid: String) async throws -> Playlist {
        try await request("playlist/\(uuid)") as Playlist
    }

    /// Fetches a playlist by its owner UID and kind.
    func getPlaylist(ownerUID: Int, kind: Int) async throws -> Playlist {
        try await request("users/\(ownerUID)/playlists/\(kind)") as Playlist
    }
}
