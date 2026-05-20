import CryptoKit
import Foundation

/// Secret key for HMAC signature generation
private let kSignatureSecret = "7tvSmFbyf5hJnIHhCimDDD"

public enum FileInfoSigningError: Error {
    case invalidSecretEncoding
    case invalidMessageEncoding
    case percentEncodingFailed
}

/// Signs the file info request
/// - Returns: The request signature
public func signFileInfoRequest(
    timestamp: String,
    trackIDs: [String],
    quality: AudioQuality,
    codecs: [AudioCodec],
    transport: FileInfoTransport
) throws -> String {
    // Message format: {ts}{trackID,trackID}{quality}{codeccodec}{transport}
    let codecsValue = codecs.map(\.rawValue).joined()
    let transportsValue = transport.rawValue
    let trackIDsValue = trackIDs.joined(separator: ",")
    let message = "\(timestamp)\(trackIDsValue)\(quality.rawValue)\(codecsValue)\(transportsValue)"

    var sign = try signMessage(message: message)
    // Remove last character as per API requirement
    if !sign.isEmpty {
        sign.removeLast()
    }

    return try percentEncode(sign)
}

public func signLyricsInfoRequest(timestamp: String, trackID: String) throws -> String {
    let message = "\(trackID)\(timestamp)"
    let sign = try signMessage(message: message)
    return try percentEncode(sign)
}

private func signMessage(message: String) throws -> String {
    guard let secretData = kSignatureSecret.data(using: .utf8) else {
        throw FileInfoSigningError.invalidSecretEncoding
    }
    guard let messageData = message.data(using: .utf8) else {
        throw FileInfoSigningError.invalidMessageEncoding
    }

    let key = SymmetricKey(data: secretData)
    let signature = HMAC<SHA256>.authenticationCode(
        for: messageData,
        using: key
    )

    return Data(signature).base64EncodedString()
}

private func percentEncode(_ input: String) throws -> String {
    var cs = CharacterSet.urlQueryAllowed
    cs.remove("+")
    cs.remove("/")
    cs.remove("=")
    guard let encoded = input.addingPercentEncoding(withAllowedCharacters: cs) else {
        throw FileInfoSigningError.percentEncodingFailed
    }
    return encoded
}
