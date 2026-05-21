import Foundation
import YandexMusic

@main
struct Playground {
    var demoStoragePath = URL(fileURLWithPath: "./PlaygroundStorage")

    static func main() async {
        guard let token = ProcessInfo.processInfo.environment["YA_MUSIC_API_TOKEN"] else {
            fatalError("YA_MUSIC_API_TOKEN environment variable not found")
        }
        if CommandLine.argc < 2 {
            fatalError("Usage: yandexmusic-playground <subcommand>")
        }
        let subcommand = CommandLine.arguments[1]
        let api = YandexMusicClient(
            token: token,
            codecs: [.flac, .aac, .heAac, .mp3, .flacMp4, .aacMp4, .heAacMp4]
        )

        try? FileManager.default.createDirectory(
            at: Self().demoStoragePath, withIntermediateDirectories: true
        )

        do {
            switch subcommand {
            case "rotor":
                _ = try await playRotor(
                    with: api,
                    settings: .onYourWave,
                    limit: 10
                )
            case "liked":
                _ = try await playLikedTracks(
                    with: api,
                    limit: 10
                )
            case "favorite-albums":
                try await printFavoriteAlbums(with: api)
            case "favorite-artists":
                try await printFavoriteArtists(with: api)
            case "personal-playlists":
                try await printPersonalPlaylists(with: api)
            case "artist-albums":
                try await printArtistAlbums(
                    with: api,
                    artistLink: "https://music.yandex.ru/artist/1206276"
                )
            case "playlist":
                _ = try await playPlaylist(
                    with: api,
                    playlistLink:
                    "https://music.yandex.ru/playlists/9fffe273-1950-b502-a727-8e6a6319d410",
                    limit: 10
                )
            case "album":
                _ = try await playAlbum(
                    with: api,
                    albumLink: "https://music.yandex.ru/album/26917357",
                    limit: 10
                )
            case "lyrics":
                _ = try await getTrackLyrics(
                    with: api, "https://music.yandex.ru/album/41449120/track/149957594"
                )
            case "artist":
                _ = try await playArtist(
                    with: api,
                    artistLink: "https://music.yandex.ru/artist/1206276",
                    limit: 10
                )
            case "search":
                guard let text = parseSearchText(from: CommandLine.arguments) else {
                    fatalError("Usage: yandexmusic-playground search <text>")
                }
                try await printSearchResults(with: api, text: text)
            default:
                fatalError("Unknown subcommand: \(subcommand)")
            }
        } catch {
            print(error)
        }
    }

    static func parseSearchText(from arguments: [String]) -> String? {
        let text =
            arguments
                .dropFirst(2)
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            return nil
        }
        return text
    }

    static func getISONow() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    struct PlayedTrack {
        let id: String
        let finishEvent: RotorSessionEvent
    }

    static func playRotor(
        with api: YandexMusicClient,
        settings _: RotorSettings,
        limit: Int
    ) async throws -> [PlayedTrack] {
        if limit <= 0 {
            print("Limit must be greater than 0")
            return []
        }

        let storagePath = Self().demoStoragePath.appendingPathComponent("rotor")
        try? FileManager.default.createDirectory(
            at: storagePath,
            withIntermediateDirectories: true
        )

        let (sessionID, firstBatch) = try await api.createRotorSession(
            settings: .onYourWave, queue: []
        )
        var batchID = firstBatch.batchId
        var batch = firstBatch.sequence

        // Send radio started event
        try await api.sendRotorSessionFeedback(
            sessionID: sessionID,
            batchID: batchID,
            event: .radioStarted(timestamp: getISONow())
        )

        var playedTracks: [PlayedTrack] = []
        var batchPlayedTracks: [PlayedTrack] = []
        while true {
            if playedTracks.count >= limit {
                break
            }

            let item = batch.removeFirst()
            guard let trackID = item.track?.id.value else {
                continue
            }
            print("Playing track \(trackID)")
            // Send track started event
            try await api.sendRotorSessionFeedback(
                sessionID: sessionID,
                batchID: batchID,
                event: .trackStarted(trackId: trackID, timestamp: getISONow())
            )
            // Download track
            print("Downloading track \(trackID)")
            let trackData = try await api.getTrackData(id: trackID, quality: .normal)
            let fileName = "\(trackID).\(trackData.codec.fileExtension)"
            let trackURL = storagePath.appendingPathComponent(fileName)
            try trackData.data.write(to: trackURL)

            // Simulate track playback
            let playedSeconds = try await simulateProcrastinatoryListening()
            print("Stopped playing track \(trackID) at \(playedSeconds) seconds")

            // Save play result
            let finishedAt = getISONow()
            let finishEvent: RotorSessionEvent
            // Simulate track skip or finish
            if Bool.random() {
                finishEvent = .trackFinished(
                    trackId: trackID, timestamp: finishedAt,
                    totalPlayedSeconds: playedSeconds
                )
            } else {
                finishEvent = .skip(
                    trackId: trackID, timestamp: finishedAt,
                    totalPlayedSeconds: playedSeconds
                )
            }

            let playResult = PlayedTrack(id: trackID, finishEvent: finishEvent)
            batchPlayedTracks.append(playResult)
            playedTracks.append(playResult)

            if batch.isEmpty {
                print("Getting next batch and sending batch feedback")
                // Send batch play results
                let nextBatch = try await api.getRotorSessionBatch(
                    sessionID: sessionID,
                    previousBatchID: batchID,
                    events: batchPlayedTracks.map(\.finishEvent),
                    queue:
                    playedTracks
                        .suffix(10)
                        .reversed()
                        .map(\.id)
                )
                batch = nextBatch.sequence
                batchID = nextBatch.batchId
                batchPlayedTracks.removeAll()
            }
        }
        return playedTracks
    }

    static func playLikedTracks(
        with api: YandexMusicClient,
        limit: Int
    ) async throws -> [PlayedTrack] {
        let storagePath = Self().demoStoragePath.appendingPathComponent("liked")
        try? FileManager.default.createDirectory(
            at: storagePath,
            withIntermediateDirectories: true
        )
        var playedTracks: [PlayedTrack] = []

        let likedTracks = try await api.getLikedTracks()
        for (trackIndex, track) in likedTracks.tracks.enumerated() {
            if trackIndex >= limit {
                break
            }
            print("Downloading track \(track.id.value)")
            let trackData = try await api.getTrackData(
                id: track.id.value,
                quality: .normal
            )
            let fileName = "\(track.id.value).\(trackData.codec.fileExtension)"
            let trackURL = storagePath.appendingPathComponent(fileName)
            try trackData.data.write(to: trackURL)

            print("Playing track \(track.id.value)")
            let playedSeconds = try await simulateProcrastinatoryListening()
            print("Stopped playing track \(track.id.value) at \(playedSeconds) seconds")

            let playResult = PlayedTrack(
                id: track.id.value,
                finishEvent: .trackFinished(
                    trackId: track.id.value, timestamp: getISONow(), totalPlayedSeconds: 0
                )
            )
            playedTracks.append(playResult)
        }
        return playedTracks
    }

    static func playPlaylist(
        with api: YandexMusicClient,
        playlistLink: String,
        limit: Int
    ) async throws -> [PlayedTrack] {
        let playlistURL = YandexMusicURL(playlistLink)!
        var playlist: Playlist?
        switch playlistURL {
        case let .playlist(uuid):
            playlist = try await api.getPlaylist(uuid: uuid)
        case let .userPlaylist(ownerUID, kind):
            playlist = try await api.getPlaylist(ownerUID: ownerUID, kind: kind)
        default:
            fatalError("Unsupported playlist URL: \(playlistLink)")
        }
        guard let playlist else {
            fatalError("Failed to get playlist: \(playlistLink)")
        }

        let storagePath = Self().demoStoragePath.appendingPathComponent("playlist")
        try? FileManager.default.createDirectory(
            at: storagePath,
            withIntermediateDirectories: true
        )
        var playedTracks: [PlayedTrack] = []

        guard let tracks = playlist.tracks else {
            fatalError("Playlist has no tracks")
        }

        for (trackIndex, track) in tracks.enumerated() {
            if trackIndex + 1 > limit {
                break
            }
            print("Downloading track \(track.id.value)")
            let trackData = try await api.getTrackData(
                id: track.id.value,
                quality: .normal
            )
            let fileName = "\(track.id.value).\(trackData.codec.fileExtension)"
            let trackURL = storagePath.appendingPathComponent(fileName)
            try trackData.data.write(to: trackURL)

            print("Playing track \(track.id.value)")
            let playedSeconds = try await simulateProcrastinatoryListening()
            print("Stopped playing track \(track.id.value) at \(playedSeconds) seconds")

            let playResult = PlayedTrack(
                id: track.id.value,
                finishEvent: .trackFinished(
                    trackId: track.id.value, timestamp: getISONow(),
                    totalPlayedSeconds: playedSeconds
                )
            )
            playedTracks.append(playResult)
        }
        return playedTracks
    }

    static func playAlbum(
        with api: YandexMusicClient,
        albumLink: String,
        limit: Int
    ) async throws -> [PlayedTrack] {
        let albumURL = YandexMusicURL(albumLink)!
        guard case let .album(albumID: albumID) = albumURL else {
            fatalError("Unsupported album URL: \(albumLink)")
        }
        let storagePath = Self().demoStoragePath.appendingPathComponent("album")
        try? FileManager.default.createDirectory(
            at: storagePath,
            withIntermediateDirectories: true
        )
        var playedTracks: [PlayedTrack] = []

        let album = try await api.getAlbumWithTracks(albumID: albumID)
        for (trackIndex, track) in album.allTracks.enumerated() {
            if trackIndex + 1 > limit {
                break
            }
            print("Downloading track \(track.id.value)")
            let trackData = try await api.getTrackData(
                id: track.id.value,
                quality: .normal
            )
            let fileName = "\(track.id.value).\(trackData.codec.fileExtension)"
            let trackURL = storagePath.appendingPathComponent(fileName)
            try trackData.data.write(to: trackURL)

            print("Playing track \(track.id.value)")
            let playedSeconds = try await simulateProcrastinatoryListening()
            print("Stopped playing track \(track.id.value) at \(playedSeconds) seconds")

            let playResult = PlayedTrack(
                id: track.id.value,
                finishEvent: .trackFinished(
                    trackId: track.id.value, timestamp: getISONow(),
                    totalPlayedSeconds: playedSeconds
                )
            )
            playedTracks.append(playResult)
        }
        return playedTracks
    }

    static func playArtist(
        with api: YandexMusicClient,
        artistLink: String,
        limit: Int
    ) async throws -> [PlayedTrack] {
        let artistURL = YandexMusicURL(artistLink)!
        guard case let .artist(artistID: artistID) = artistURL else {
            fatalError("Unsupported artist URL: \(artistLink)")
        }
        let storagePath = Self().demoStoragePath.appendingPathComponent("artist")
        try? FileManager.default.createDirectory(
            at: storagePath,
            withIntermediateDirectories: true
        )
        var playedTracks: [PlayedTrack] = []

        let artist = try await api.getArtistTracks(artistID: artistID)
        for (trackIndex, track) in artist.enumerated() {
            if trackIndex + 1 > limit {
                break
            }
            print("Downloading track \(track.id.value)")
            let trackData = try await api.getTrackData(
                id: track.id.value,
                quality: .normal
            )
            let fileName = "\(track.id.value).\(trackData.codec.fileExtension)"
            let trackURL = storagePath.appendingPathComponent(fileName)
            try trackData.data.write(to: trackURL)

            print("Playing track \(track.id.value)")
            let playedSeconds = try await simulateProcrastinatoryListening()
            print("Stopped playing track \(track.id.value) at \(playedSeconds) seconds")

            let playResult = PlayedTrack(
                id: track.id.value,
                finishEvent: .trackFinished(
                    trackId: track.id.value, timestamp: getISONow(),
                    totalPlayedSeconds: playedSeconds
                )
            )
            playedTracks.append(playResult)
        }
        return playedTracks
    }

    static func printFavoriteAlbums(
        with api: YandexMusicClient
    ) async throws {
        let albums = try await api.getUserAlbums(pageSize: 50)
        for album in albums {
            print("Album: \(album.title ?? "Unknown") by \(album.artistNames)")
        }
    }

    static func printFavoriteArtists(
        with api: YandexMusicClient
    ) async throws {
        let artists = try await api.getLikedArtists(pageSize: 50)
        for artist in artists {
            print("Artist: \(artist.name)")
        }
    }

    static func printPersonalPlaylists(
        with api: YandexMusicClient
    ) async throws {
        let items = try await api.getPersonalPlaylists()
        for item in items {
            guard let playlist = item.data?.playlist else {
                continue
            }
            let title = playlist.title ?? "Unknown"
            let playlistType = item.data?.playlistType ?? "unknown"
            print("Playlist: \(title) (type: \(playlistType), kind: \(playlist.kind))")
        }
    }

    static func printArtistAlbums(
        with api: YandexMusicClient,
        artistLink: String
    ) async throws {
        let artistURL = YandexMusicURL(artistLink)!
        guard case let .artist(artistID: artistID) = artistURL else {
            fatalError("Unsupported artist URL: \(artistLink)")
        }
        let albums = try await api.getArtistAlbums(artistID: artistID)
        for album in albums {
            print("Album: \(album.title ?? "Unknown") by \(album.artistNames)")
        }
    }

    static func printSearchResults(
        with api: YandexMusicClient,
        text: String
    ) async throws {
        let response = try await api.search(text: text)
        print("Search text: \(response.text ?? text)")
        print(
            "Total: \(response.total ?? 0), results: \(response.results.count), bestResults: \(response.bestResults.count)"
        )

        if !response.bestResults.isEmpty {
            print("Best results:")
            for result in response.bestResults {
                switch result {
                case let .album(bestAlbum):
                    let title = bestAlbum.album.title ?? "Unknown album"
                    let artists =
                        bestAlbum.artists?.map(\.name).joined(separator: ", ") ?? "Unknown artist"
                    print("  best album: \(title) - \(artists)")
                case let .artist(bestArtist):
                    print("  best artist: \(bestArtist.artist.name)")
                case let .track(track):
                    print("  best track: \(describeTrack(track))")
                }
            }
        }

        if !response.results.isEmpty {
            print("Results:")
            for result in response.results.prefix(10) {
                switch result {
                case let .track(track):
                    print("  \(describeTrack(track))")
                case let .album(album):
                    let title = album.title ?? "Unknown album"
                    let artists =
                        album.artistNames.isEmpty
                            ? "Unknown artist"
                            : album
                            .artistNames
                    print("  album: \(title) - \(artists)")
                case let .artist(artist):
                    print("  artist: \(artist.name)")
                }
            }
            if response.results.count > 10 {
                print("  ... and \(response.results.count - 10) more")
            }
        }
    }

    static func describeTrack(_ track: Track) -> String {
        let title = track.title ?? "Unknown track"
        let artists = track.artistNames.isEmpty ? "Unknown artist" : track.artistNames
        return "track: \(title) - \(artists)"
    }

    static func getTrackLyrics(with api: YandexMusicClient, _ url: String) async throws {
        let trackURL = YandexMusicURL(url)!
        guard case .track(trackID: let (_, trackID)) = trackURL else {
            fatalError("Unsupported track URL: \(url)")
        }
        let trackInfo = try await api.getTrack(id: trackID)
        guard let lyricsInfo = trackInfo?.lyricsInfo else {
            fatalError("Track has no lyrics: \(url)")
        }
        var format: LyricsFormat
        if lyricsInfo.hasAvailableSyncLyrics {
            format = .lrc
            print("  track has sync lyrics.")
        } else {
            format = .text
            print("  track has text lyrics.")
        }

        let lyrics = try await api.getTrackLyrics(id: trackID, format: format)
        print(lyrics)
    }

    static func simulateProcrastinatoryListening() async throws -> Double {
        let playedSeconds = Double.random(in: 0 ..< 15)
        try await Task.sleep(for: .seconds(playedSeconds))
        return playedSeconds
    }
}
