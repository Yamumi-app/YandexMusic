import Foundation

public final class YandexMusicClient: @unchecked Sendable {
    private var cachedAccountUID: Int?
    private var api: API
    private let codecs: [AudioCodec]

    public init(
        token: String,
        codecs: [AudioCodec],
        baseURL: URL = kDefaultBaseURL,
        session: URLSession = .shared,
        language: YandexMusicLanguage = .english
    ) {
        self.codecs = codecs
        api = API(token: token, baseURL: baseURL, session: session, language: language)
    }

    // MARK: - Account

    /// Updates the token and resets cached account info.
    public func updateToken(_ token: String) async {
        await api.updateToken(token)
        cachedAccountUID = nil
    }

    /// Returns the current user's account UID.
    ///
    /// If called multiple times, the result will be cached.
    public func getAccountUID() async throws -> Int {
        if let cachedAccountUID {
            return cachedAccountUID
        }

        let uid = try await api.getAccountStatus().account.uid
        cachedAccountUID = uid
        return uid
    }

    // MARK: - Tracks

    /// Fetches metadata for multiple tracks.
    public func getTracks(ids: [String]) async throws -> [Track] {
        try await api.getTracks(ids: ids)
    }

    /// Fetches metadata for a single track.
    public func getTrack(id: String) async throws -> Track? {
        try await getTracks(ids: [id]).first
    }

    public func getTrackLyrics(id: String, format: LyricsFormat) async throws -> String {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let info = try await api.getTrackLyricsInfo(
            id: id,
            format: format,
            timestamp: timestamp
        )
        let lyricsData = try await api.request(info.downloadUrl, fullURL: true)

        guard let lyrics = String(data: lyricsData, encoding: .utf8) else {
            throw NSError(domain: "YandexMusicClient", code: 0, userInfo: nil)
        }
        return lyrics
    }

    // MARK: - Albums

    /// Fetches an album with all its tracks.
    public func getAlbumWithTracks(albumID: String) async throws -> Album {
        try await api.getAlbumWithTracks(albumID: albumID)
    }

    /// Fetches the current user's albums.
    public func getUserAlbums(pageSize: Int = 20) async throws -> [Album] {
        let uid = try await getAccountUID()
        var page = 0
        var albums: [Album] = []

        while true {
            let (newAlbums, pager) = try await api.getUserAlbums(
                userUID: String(uid),
                page: page,
                pageSize: pageSize
            )
            albums.append(contentsOf: newAlbums)
            if (pager.page + 1) * pager.perPage >= pager.total {
                break
            }
            page = pager.page + 1
        }

        return albums
    }

    // MARK: - Artists

    /// Fetches tracks by an artist.
    public func getArtistTracks(
        artistID: String,
        page: Int = 0,
        pageSize: Int = 200
    ) async throws
        -> [Track]
    {
        try await api.getArtistTracks(artistID: artistID, page: page, pageSize: pageSize)
    }

    /// Fetches the current user's liked artists.
    public func getLikedArtists(pageSize: Int = 20) async throws -> [Artist] {
        let uid = try await getAccountUID()
        var page = 0
        var artists: [Artist] = []
        while true {
            let (newArtists, pager) = try await api.getLikedArtists(
                userUID: String(uid), page: page, pageSize: pageSize
            )
            artists.append(contentsOf: newArtists)
            if (pager.page + 1) * pager.perPage >= pager.total {
                break
            }
            page = pager.page + 1
        }
        return artists
    }

    /// Fetches albums by an artist.
    public func getArtistAlbums(
        artistID: String,
        pageSize: Int = 20
    ) async throws -> [Album] {
        var page = 0
        var albums: [Album] = []
        while true {
            let (newAlbums, pager) = try await api.getArtistAlbums(
                artistID: artistID, page: page, pageSize: pageSize
            )
            albums.append(contentsOf: newAlbums)
            if (pager.page + 1) * pager.perPage >= pager.total {
                break
            }
            page += 1
        }
        return albums
    }

    // MARK: - Playlists

    /// Fetches the current user's playlists.
    public func getUserPlaylists() async throws -> [Playlist] {
        let uid = try await getAccountUID()
        return try await api.getUserPlaylists(userUID: String(uid))
    }

    /// Fetches personal playlists from the landing blocks endpoint.
    public func getPersonalPlaylists() async throws -> [PersonalPlaylistItem] {
        try await api.getPersonalPlaylists()
    }

    /// Fetches a playlist by its UUID (public share link format).
    public func getPlaylist(uuid: String) async throws -> Playlist {
        try await api.getPlaylist(uuid: uuid)
    }

    /// Fetches a playlist by its owner UID and kind.
    public func getPlaylist(ownerUID: Int, kind: Int) async throws -> Playlist {
        try await api.getPlaylist(ownerUID: ownerUID, kind: kind)
    }

    // MARK: - Search

    /// Performs mixed search over tracks, albums and artists.
    public func search(
        text: String,
        page: Int = 0,
        pageSize: Int = 36
    ) async throws -> SearchMixedResponse {
        try await api.searchInstantMixed(
            text: text,
            page: page,
            pageSize: pageSize
        )
    }

    // MARK: - Likes

    /// Fetches the current user's liked tracks library.
    public func getLikedTracks(ifModifiedSinceRevision: Int = 0) async throws
        -> LikedTracksLibrary
    {
        let uid = try await getAccountUID()
        return try await api.getLikedTracks(
            userUID: String(uid),
            ifModifiedSinceRevision: ifModifiedSinceRevision
        )
    }

    /// Adds or removes a like for a track
    public func setTrackLiked(
        userUID: String,
        trackID: String,
        isLiked: Bool
    ) async throws {
        try await api.setTrackLiked(userUID: userUID, trackID: trackID, isLiked: isLiked)
    }

    /// Adds or removes a dislike for a track
    public func setTrackDisliked(
        userUID: String,
        trackID: String,
        isDisliked: Bool
    ) async throws {
        try await api.setTrackDisliked(
            userUID: userUID,
            trackID: trackID,
            isDisliked: isDisliked
        )
    }

    /// Fetches playlists liked by the current user.
    public func getLikedPlaylists() async throws -> [Playlist] {
        let uid = try await getAccountUID()
        return try await api.getLikedPlaylists(userUID: String(uid))
    }

    // MARK: - Track data

    /// Resolves stable download metadata for a track and quality.
    public func getTrackDownloadInfo(
        id: String,
        quality: AudioQuality
    ) async throws -> FileDownloadInfo {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        return try await api.getFileDownloadInfo(
            trackID: id,
            quality: quality,
            transport: .encrypted,
            codecs: codecs,
            timestamp: timestamp
        )
    }

    /// Downloads and decrypts track data for a previously resolved download info.
    public func getTrackData(
        id: String,
        downloadInfo: FileDownloadInfo,
        range: FileDataRange = .full
    ) async throws -> FileDownloadResult {
        guard let key = downloadInfo.key else {
            throw YandexMusicError.missingEncryptionKey
        }
        let (data, response) = try await api.getFileDataWithResponse(
            from: downloadInfo.url,
            range: range
        )
        let decryptedData: Data
        if range.start > 0 {
            decryptedData = try decryptEncraw(
                data: data,
                hexKey: key,
                offset: range.start
            )
        } else {
            decryptedData = try decryptEncraw(data: data, hexKey: key)
        }

        return FileDownloadResult(
            trackID: id,
            data: decryptedData,
            codec: downloadInfo.codec,
            bitrate: downloadInfo.bitrate,
            contentLength: parseTotalContentLength(from: response)
        )
    }

    /// Downloads data for a track.
    public func getTrackData(
        id: String,
        quality: AudioQuality,
        range: FileDataRange = .full
    ) async throws -> FileDownloadResult {
        let downloadInfo = try await getTrackDownloadInfo(id: id, quality: quality)
        return try await getTrackData(
            id: id,
            downloadInfo: downloadInfo,
            range: range
        )
    }

    /// Downloads data for a track.
    public func getTrackDataBatch(
        trackIDs: [String],
        quality: AudioQuality,
        range: FileDataRange = .full
    ) async throws -> [FileDownloadResult] {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let downloadInfos = try await api.getFileDownloadInfoBatch(
            trackIDs: trackIDs,
            quality: quality,
            transport: .encrypted,
            codecs: codecs,
            timestamp: timestamp
        )

        var results: [FileDownloadResult] = []
        results.reserveCapacity(downloadInfos.count)
        for (index, downloadInfo) in downloadInfos.enumerated() {
            guard let key = downloadInfo.key else {
                throw YandexMusicError.missingEncryptionKey
            }
            let (data, response) = try await api.getFileDataWithResponse(
                from: downloadInfo.url,
                range: range
            )
            let decryptedData: Data
            if range.start > 0 {
                decryptedData = try decryptEncraw(
                    data: data,
                    hexKey: key,
                    offset: range.start
                )
            } else {
                decryptedData = try decryptEncraw(data: data, hexKey: key)
            }
            results.append(
                FileDownloadResult(
                    trackID: trackIDs[index],
                    data: decryptedData,
                    codec: downloadInfo.codec,
                    bitrate: downloadInfo.bitrate,
                    contentLength: parseTotalContentLength(from: response)
                )
            )
        }

        return results
    }

    // MARK: - Rotor

    public func createRotorSession(
        settings: RotorSettings,
        queue: [String]
    ) async throws -> (String, RotorSessionBatch) {
        let (sessionID, batch) = try await api.createRotorSession(
            seeds: settings.seeds, queue: queue
        )
        return (sessionID, batch)
    }

    public func createRotorSession(
        seeds: [String],
        queue: [String]
    ) async throws -> (String, RotorSessionBatch) {
        let (sessionID, batch) = try await api.createRotorSession(
            seeds: seeds, queue: queue
        )
        return (sessionID, batch)
    }

    public func sendRotorSessionFeedback(
        sessionID: String,
        batchID: String,
        event: RotorSessionEvent
    ) async throws {
        try await api.sendRotorSessionFeedback(
            sessionID: sessionID,
            batchID: batchID,
            event: event
        )
    }

    public func getRotorSessionBatch(
        sessionID: String,
        previousBatchID: String,
        events: [RotorSessionEvent],
        queue: [String]
    ) async throws -> RotorSessionBatch {
        try await api.getRotorSessionBatch(
            sessionID: sessionID, previousBatchID: previousBatchID, events: events,
            queue: queue
        )
    }
}

public enum YandexMusicError: Error {
    case missingEncryptionKey
    case invalidResponse(String)
}

private func parseTotalContentLength(from response: HTTPURLResponse) -> Int64? {
    if let contentRange = response.value(forHTTPHeaderField: "Content-Range"),
       let slash = contentRange.lastIndex(of: "/")
    {
        let totalPart = contentRange[contentRange.index(after: slash)...]
            .trimmingCharacters(in: .whitespaces)
        if totalPart != "*",
           let total = Int64(totalPart),
           total > 0
        {
            return total
        }
    }

    if response.statusCode == 200,
       let contentLength = response.value(forHTTPHeaderField: "Content-Length"),
       let length = Int64(contentLength),
       length > 0
    {
        return length
    }

    return nil
}
