import Foundation

extension API {
    /// Fetches track download info.
    /// - Parameters:
    ///   - trackID: The numeric track ID (without album part) or UUID
    ///   - quality: The desired quality level
    ///   - transport: Transport type for the file info response
    /// - Returns: Download info with direct URL and key
    func getFileDownloadInfo(
        trackID: String,
        quality: AudioQuality,
        transport: FileInfoTransport,
        codecs: [AudioCodec],
        timestamp: String
    ) async throws -> FileDownloadInfo {
        let signature = try signFileInfoRequest(
            timestamp: timestamp,
            trackIDs: [trackID],
            quality: quality,
            codecs: codecs,
            transport: transport
        )

        let codecValues = codecs.map(\.rawValue).joined(separator: kEscapedComma)
        let response: FileDownloadInfoResponse = try await request("get-file-info") {
            $0
                .queryItems(
                    .init(name: "ts", value: timestamp),
                    .init(name: "trackId", value: trackID),
                    .init(name: "quality", value: quality.rawValue),
                    .init(name: "codecs", value: codecValues),
                    .init(name: "transports", value: transport.rawValue),
                    .init(name: "sign", value: signature)
                )
                .userAgent(.desktopApp)
        }
        return response.downloadInfo
    }

    func getFileDownloadInfoBatch(
        trackIDs: [String],
        quality: AudioQuality,
        transport: FileInfoTransport,
        codecs: [AudioCodec],
        timestamp: String
    ) async throws -> [FileDownloadInfo] {
        let signature = try signFileInfoRequest(
            timestamp: timestamp,
            trackIDs: trackIDs,
            quality: quality,
            codecs: codecs,
            transport: transport
        )

        let codecValues = codecs.map(\.rawValue).joined(separator: kEscapedComma)
        let response: FileDownloadInfoBatchResponse =
            try await request("get-file-info/batch") {
                $0
                    .queryItems(
                        .init(name: "ts", value: timestamp),
                        .init(
                            name: "trackIds",
                            value: trackIDs.joined(separator: kEscapedComma)
                        ),
                        .init(name: "quality", value: quality.rawValue),
                        .init(name: "codecs", value: codecValues),
                        .init(name: "transports", value: transport.rawValue),
                        .init(name: "sign", value: signature)
                    )
                    .userAgent(.desktopApp)
            }
        return response.downloadInfos
    }

    /// Downloads data from a URL
    /// - Parameters:
    ///   - url: The URL to download from
    ///   - range: Range of data to download
    /// - Returns: Downloaded data
    func getFileData(from url: String, range: FileDataRange) async throws -> Data {
        try await request(url, fullURL: true) { $0.headers(range.header) }
    }

    /// Downloads data from a URL with HTTP response metadata.
    /// - Parameters:
    ///   - url: The URL to download from
    ///   - range: Range of data to download
    /// - Returns: Downloaded data and HTTP response
    func getFileDataWithResponse(
        from url: String,
        range: FileDataRange
    ) async throws -> (Data, HTTPURLResponse) {
        try await requestDataWithResponse(url, fullURL: true) {
            $0.headers(range.header)
        }
    }
}

/// FileDownloadInfo wrapper response.
private struct FileDownloadInfoResponse: Decodable {
    let downloadInfo: FileDownloadInfo
}

/// FileDownloadInfo wrapper batch response.
private struct FileDownloadInfoBatchResponse: Decodable {
    let downloadInfos: [FileDownloadInfo]
}
