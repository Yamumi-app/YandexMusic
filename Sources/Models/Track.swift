import Foundation

public struct ArtistCover: Sendable, Codable {
    public let uri: URLTemplate?
}

/// Represents an artist from Yandex Music API.
public struct Artist: Sendable, Codable {
    public let id: StringOrInt?
    public let name: String
    public let cover: ArtistCover?

    public func coverURL(size: CoverSize) -> URL? {
        cover?.uri.flatMap { $0.render(with: size) }
    }
}

/// Represents the lyrics information of a track.
public struct TrackLyricsInfo: Sendable, Codable {
    public let hasAvailableTextLyrics: Bool
    public let hasAvailableSyncLyrics: Bool
}

/// Represents a track from Yandex Music API.
public struct Track: Sendable, Codable {
    public let id: StringOrInt
    public let title: String?
    public let artists: [Artist]
    public let albums: [TrackAlbum]?
    public let coverUri: String?
    public let durationMs: Int?
    /// Exists on self uploaded tracks
    public let filename: String?
    public let lyricsInfo: TrackLyricsInfo?

    /// Builds full cover URL from the cover_uri template.
    /// - Parameter size: Size string like "200x200", "400x400", etc.
    /// - Returns: Full URL to the cover image, or nil if no cover_uri.
    public func coverURL(size: String = "200x200") -> URL? {
        guard let uri = coverUri else { return nil }
        let urlString = "https://\(uri.replacingOccurrences(of: "%%", with: size))"
        return URL(string: urlString)
    }

    /// Builds full cover URL from the cover_uri template.
    public func coverURL(size: CoverSize) -> URL? {
        coverURL(size: size.rawValue)
    }

    /// Comma-separated artist names.
    public var artistNames: String {
        artists.map(\.name).joined(separator: ", ")
    }

    /// Returns the full track ID in "trackId:albumId" format.
    /// Uses the first album if available.
    public func fullTrackId(albumId: Int? = nil) -> String {
        let album = albumId ?? albums?.first?.id
        if let album {
            return "\(id.value):\(album)"
        }
        return id.value
    }
}

public struct TrackShort: Sendable, Codable {
    public let id: StringOrInt
    public let albumId: StringOrInt?
    public let timestamp: String?

    public var trackId: String {
        if let albumId {
            return "\(id.value):\(albumId.value)"
        }
        return id.value
    }
}

/// Represents a short track reference in a playlist.
/// The actual structure from API is: { id, timestamp, track: { ... full track data ... }
/// }
public struct PlaylistTrack: Sendable, Codable {
    public let id: StringOrInt
    public let timestamp: String?
    public let track: Track?

    /// Album ID extracted from the nested track data.
    public var albumID: Int? {
        track?.albums?.first?.id
    }

    /// Full track ID in "trackId:albumId" format.
    public var trackID: String {
        if let albumID {
            return "\(id.value):\(albumID)"
        }
        return id.value
    }
}

/// Inner result containing the artist's tracks.
public struct ArtistTracks: Codable {
    let tracks: [Track]
}

public struct LikedTracksLibrary: Sendable, Codable {
    public let uid: Int?
    public let revision: Int?
    public let tracks: [TrackShort]
}

public struct LikedTracksResult: Sendable, Codable {
    let library: LikedTracksLibrary
}

public struct SetTrackLikedResult: Sendable, Codable {
    let revision: Int
}

/// Represents a major label or publisher of a track.
public struct TrackMajor: Sendable, Codable {
    let id: Int
    let name: String
    let prettyName: String
}

/// Represents the lyrics information of a track.
public struct Lyrics: Sendable, Codable {
    let downloadUrl: String
    let lyricId: Int
    let externalLyricId: String
    let writers: [String]
    let major: TrackMajor
}

/// Track lyrics format.
public enum LyricsFormat: String, Sendable, Decodable {
    /// Line-by-line lyrics with timestamps.
    case lrc = "LRC"
    /// Plain text lyrics.
    case text = "TEXT"
}
