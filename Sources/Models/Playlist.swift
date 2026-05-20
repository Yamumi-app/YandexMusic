import Foundation

/// Owner information for a playlist.
public struct PlaylistOwner: Sendable, Codable {
    public let uid: Int
    public let login: String?
    public let name: String?
}

/// Minimal cover info for a playlist.
public struct PlaylistCover: Sendable, Codable {
    public let uri: URLTemplate?

    public func coverURL(size: CoverSize) -> URL? {
        uri.flatMap { $0.render(with: size) }
    }
}

/// Represents a playlist from Yandex Music API.
public struct Playlist: Sendable, Codable {
    public let playlistUuid: String?
    public let uid: Int?
    public let kind: Int
    public let title: String?
    public let owner: PlaylistOwner?
    public let cover: PlaylistCover?
    public let trackCount: Int?
    public let durationMs: Int?
    public let tracks: [PlaylistTrack]?
    public let ogImage: String?

    /// Builds full cover URL from the og_image or cover.
    public func coverURL(size: CoverSize) -> URL? {
        if let url = cover?.coverURL(size: size) {
            return url
        }
        guard let ogImage else { return nil }
        return ogImage.render(with: size)
    }

    /// The owner UID (either from owner object or uid field).
    var ownerUid: Int {
        owner?.uid ?? uid ?? 0
    }
}

/// Trailer metadata for a personal playlist.
public struct PersonalPlaylistTrailer: Sendable, Codable {
    public let available: Bool?
}

/// Block payload for a personal playlist.
public struct PersonalPlaylistData: Sendable, Codable {
    public let playlist: Playlist?
    public let playlistType: String?
    public let description: String?
    public let notify: Bool?
    public let idForFrom: String?
    public let trailer: PersonalPlaylistTrailer?
}

/// Item from /landing-blocks/personal-playlists.
public struct PersonalPlaylistItem: Sendable, Codable {
    public let type: String?
    public let data: PersonalPlaylistData?
}

/// Response wrapper for user playlists list.
struct PlaylistsListResponse: Codable {
    let result: [Playlist]
}

/// Response wrapper for a single playlist.
struct PlaylistResponse: Codable {
    let result: Playlist
}

/// Liked playlist wrapper (from /users/{uid}/likes/playlists).
struct LikedPlaylist: Codable {
    let playlist: Playlist?
}

/// Response wrapper for liked playlists.
struct LikedPlaylistsResponse: Codable {
    let result: [LikedPlaylist]
}

/// Response wrapper for personal playlists landing block.
struct PersonalPlaylistsResponse: Codable {
    let items: [PersonalPlaylistItem]
}
