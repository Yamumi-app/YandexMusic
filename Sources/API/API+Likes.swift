extension API {
    /// Fetches the current user's liked tracks library.
    /// - Parameter ifModifiedSinceRevision: Optional revision for incremental updates (0
    /// = full list).
    func getLikedTracks(userUID: String, ifModifiedSinceRevision: Int = 0) async throws
        -> LikedTracksLibrary
    {
        let result: LikedTracksResult =
            try await request("users/\(userUID)/likes/tracks") {
                $0.queryItems(
                    .init(
                        name: "if-modified-since-revision",
                        value: String(ifModifiedSinceRevision)
                    )
                )
            }
        return result.library
    }

    /// Adds or removes a like for a track
    ///   POST /users/{uid}/likes/tracks/add-multiple   { track-ids: ids }
    ///   POST /users/{uid}/likes/tracks/remove        { track-ids: ids }
    func setTrackLiked(userUID: String, trackID: String, isLiked: Bool) async throws {
        let action = isLiked ? "add-multiple" : "remove"

        let _: SetTrackLikedResult =
            try await request("users/\(userUID)/likes/tracks/\(action)") {
                $0.body(.urlForm([.init(name: "track-ids", value: trackID)]))
            }
    }

    /// Adds or removes a dislike for a track
    ///   POST /users/{uid}/dislikes/tracks/add-multiple   { track-ids: ids }
    ///   POST /users/{uid}/dislikes/tracks/remove          { track-ids: ids }
    func setTrackDisliked(
        userUID: String,
        trackID: String,
        isDisliked: Bool
    ) async throws {
        let action = isDisliked ? "add-multiple" : "remove"

        let _: SetTrackLikedResult =
            try await request("users/\(userUID)/dislikes/tracks/\(action)") {
                $0.body(.urlForm([.init(name: "track-ids", value: trackID)]))
            }
    }

    /// Fetches playlists liked by the given user.
    func getLikedPlaylists(userUID: String) async throws -> [Playlist] {
        let response: LikedPlaylistsResponse =
            try await request("users/\(userUID)/likes/playlists")
        return response.result.compactMap(\.playlist)
    }
}
