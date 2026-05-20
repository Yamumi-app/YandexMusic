extension API {
    /// Fetches track metadata (title, artists, cover) for one or more tracks.
    func getTracks(ids: [String]) async throws -> [Track] {
        try await request("tracks") {
            $0.body(
                .urlForm([
                    .init(name: "track-ids", value: ids.joined(separator: kEscapedComma)),
                    .init(name: "with-positions", value: "false"),
                ])
            )
        } as [Track]
    }

    /// Fetches track lyrics metadata for track
    func getTrackLyricsInfo(
        id: String,
        format: LyricsFormat,
        timestamp: String
    ) async throws -> Lyrics {
        let signature = try signLyricsInfoRequest(timestamp: timestamp, trackID: id)
        return try await request("tracks/\(id)/lyrics") {
            $0.queryItems(
                .init(name: "sign", value: signature),
                .init(name: "timeStamp", value: timestamp),
                .init(name: "format", value: format.rawValue)
            )
            .userAgent(.desktopApp)
        } as Lyrics
    }
}

// https://api.music.yandex.com/tracks/149957594/lyrics?sign=ckF%2F0jop1C7vEKfH3%2F7C4DodZuQzLsQIRLh4cbzJzYE%3D&timeStamp=1776199160&format=LRC
