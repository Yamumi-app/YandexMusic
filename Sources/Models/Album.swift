import Foundation

/// Represents an album from Yandex Music API (with tracks).
public struct Album: Sendable, Decodable {
    public let id: Int
    public let title: String?
    public let artists: [Artist]
    public let coverUri: URLTemplate?
    public let trackCount: Int?
    public let volumes: [[Track]]?

    /// Builds full cover URL from the cover_uri template.
    public func coverURL(size: CoverSize) -> URL? {
        coverUri.flatMap { $0.render(with: size) }
    }

    /// Flattens all volumes into a single track list.
    public var allTracks: [Track] {
        volumes?.flatMap(\.self) ?? []
    }

    /// Comma-separated artist names.
    public var artistNames: String {
        artists.map(\.name).joined(separator: ", ")
    }
}

/// Minimal album info embedded in a track.
public struct TrackAlbum: Sendable, Codable {
    public let id: Int
    public let title: String?
}
