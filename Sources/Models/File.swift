import Foundation

/// Quality of audio file
public enum AudioQuality: String, Sendable, Decodable {
    case lossless
    case normal = "nq"
    case low = "lq"
}

/// Audio codec types.
public enum AudioCodec: String, Sendable, Decodable {
    case flac
    case flacMp4 = "flac-mp4"
    case aac
    case aacMp4 = "aac-mp4"
    case heAac = "he-aac"
    case heAacMp4 = "he-aac-mp4"
    case mp3

    public var fileExtension: String {
        switch self {
        case .flac:
            return "flac"
        case .flacMp4:
            return "m4a"
        case .aac, .aacMp4, .heAac, .heAacMp4:
            return "m4a"
        case .mp3:
            return "mp3"
        }
    }
}

extension [AudioCodec] {
    public static let all: [AudioCodec] = [
        .mp3,
        .aac,
        .heAac,
        .aacMp4,
        .heAacMp4,
        .flac,
        .flacMp4,
    ]
}

/// Transport type for the file info response.
public enum FileInfoTransport: String, Sendable, Decodable {
    case encrypted = "encraw"
    case raw
}

/// Information about a single file download.
public struct FileDownloadInfo: Sendable, Decodable {
    public let codec: AudioCodec
    public let bitrate: Int
    public let quality: AudioQuality
    /// Audio file download URL
    public let url: String
    /// Encryption key (hex-encoded)
    public let key: String?
}

/// Range of data to download from a file.
public struct FileDataRange: Sendable, Codable {
    public let start: Int
    public let end: Int?

    /// Full range of the file bytes.
    public static let full: FileDataRange = Self(start: 0, end: nil)

    /// Header value for the range.
    var headerValue: String {
        if let end {
            return "bytes=\(start)-\(end)"
        }
        return "bytes=\(start)-"
    }

    /// Header value for the range.
    var header: HttpHeader {
        HttpHeader(name: "Range", value: headerValue)
    }
}

public struct FileDownloadResult: Sendable {
    public let trackID: String
    public let data: Data
    public let codec: AudioCodec
    public let bitrate: Int
    public let contentLength: Int64?
}
