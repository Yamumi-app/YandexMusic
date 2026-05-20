import AppKit
import Foundation

/// Represents a parsed Yandex Music URL.
public enum YandexMusicURL: Equatable {
    /// Album link: /album/{albumId}
    case album(albumID: String)

    /// Track link: /album/{albumId}/track/{trackId}
    case track(albumID: String, trackID: String)

    /// Playlist link: /playlists/{uuid}
    case playlist(uuid: String)

    /// User playlist link: /users/{uid}/playlists/{kind}
    case userPlaylist(ownerUID: Int, kind: Int)

    /// Artist link: /artist/{artistId}
    case artist(artistID: String)
}

/// Valid Yandex Music hosts.
private let kKnownHosts = ["music.yandex.ru", "music.yandex.com"]

extension YandexMusicURL {
    /// Parses a URL string into a YandexMusicLink.
    /// - Parameter urlString: The URL string to parse
    /// - Returns: A parsed link, or nil if the URL is invalid or not a Yandex Music URL
    public init?(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return nil
        }

        if let maybeValue: YandexMusicURL = Self.parse(url: url) {
            self = maybeValue
            return
        }
        return nil
    }

    public init?(url: URL) {
        if let maybeValue = Self.parse(url: url) {
            self = maybeValue
            return
        }
        return nil
    }

    // MARK: - Private Parsers

    /// Parses a URL into a YandexMusicLink.
    /// - Parameter url: The URL to parse
    /// - Returns: A parsed link, or nil if the URL is invalid
    private static func parse(url: URL) -> Self? {
        guard let host = url.host, kKnownHosts.contains(host) else {
            return nil
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        // Match patterns:
        // /album/{albumId}
        // /album/{albumId}/track/{trackId}
        // /playlists/{uuid}
        // /users/{uid}/playlists/{kind}
        // /artist/{artistId}

        guard !pathComponents.isEmpty else {
            return nil
        }

        switch pathComponents[0] {
        case "album":
            return .parseAlbumPath(pathComponents)
        case "playlists":
            return parsePlaylistPath(pathComponents)
        case "users":
            return parseUserPath(pathComponents)
        case "artist":
            return parseArtistPath(pathComponents)
        default:
            return nil
        }
    }

    /// Parses /album/{albumId} or /album/{albumId}/track/{trackId}
    private static func parseAlbumPath(_ components: [String]) -> Self? {
        guard components.count >= 2 else {
            return nil
        }

        let albumId = components[1]

        // Check if it's a track link: /album/{albumId}/track/{trackId}
        if components.count >= 4,
           components[2] == "track"
        {
            let trackId = components[3]
            return .track(albumID: albumId, trackID: trackId)
        }

        // Just album link
        return .album(albumID: albumId)
    }

    /// Parses /playlists/{uuid}
    private static func parsePlaylistPath(_ components: [String]) -> Self? {
        guard components.count >= 2 else {
            return nil
        }

        let uuid = components[1]
        return .playlist(uuid: uuid)
    }

    /// Parses /users/{uid}/playlists/{kind}
    private static func parseUserPath(_ components: [String]) -> Self? {
        // /users/{uid}/playlists/{kind}
        guard components.count >= 4,
              components[2] == "playlists",
              let uid = Int(components[1]),
              let kind = Int(components[3])
        else {
            return nil
        }

        return .userPlaylist(ownerUID: uid, kind: kind)
    }

    /// Parses /artist/{artistId}
    private static func parseArtistPath(_ components: [String]) -> Self? {
        guard components.count >= 2 else {
            return nil
        }

        let artistId = components[1]
        return .artist(artistID: artistId)
    }
}
