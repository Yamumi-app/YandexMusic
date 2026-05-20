import CommonCrypto
import Foundation

/// Errors that can occur during decryption.
public enum DecryptionError: LocalizedError {
    case invalidKey
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "Invalid encryption key"
        case .invalidData:
            return "Invalid encrypted data"
        }
    }
}

/// Decrypts data encrypted with AES-CTR using the provided hex key.
/// Uses 12-byte zero nonce as per Yandex `encraw` (encrypted raw) format.
/// - Parameters:
///   - data: Encrypted data
///   - hexKey: Hex-encoded encryption key (32 hex chars = 16 bytes)
/// - Returns: Decrypted data
public func decryptEncraw(data: Data, hexKey: String) throws -> Data {
    // Convert hex key to bytes
    guard let keyData = Data(hexString: hexKey) else {
        throw DecryptionError.invalidKey
    }

    // AES-CTR: plaintext = ciphertext XOR AES_encrypt(nonce || counter)
    // Uses 12-byte zero nonce with 4-byte counter (all zeros initially)
    return try decryptAESCTR(data: data, key: keyData)
}

/// Decrypts a range with a byte offset into the encrypted stream.
/// - Parameters:
///   - data: Encrypted data range
///   - hexKey: Hex-encoded encryption key
///   - offset: Byte offset from the start of the full file
public func decryptEncraw(data: Data, hexKey: String, offset: Int) throws -> Data {
    // Convert hex key to bytes
    guard let keyData = Data(hexString: hexKey) else {
        throw DecryptionError.invalidKey
    }

    // AES-CTR: plaintext = ciphertext XOR AES_encrypt(nonce || counter)
    // Counter starts at block offset for the given byte offset
    return try decryptAESCTR(data: data, key: keyData, offset: offset)
}

/// Decrypts data using AES-CTR mode.
private func decryptAESCTR(data: Data, key: Data) throws -> Data {
    var result = Data(count: data.count)
    let blockSize = kCCBlockSizeAES128

    // 12-byte nonce + 4-byte counter (all zeros initially)
    var counter = Data(repeating: 0, count: 16)

    var offset = 0
    while offset < data.count {
        var keystreamBlock = Data(count: blockSize)
        var numBytesEncrypted: size_t = 0

        let status = keystreamBlock.withUnsafeMutableBytes { keystreamBytes in
            counter.withUnsafeBytes { counterBytes in
                key.withUnsafeBytes { keyBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionECBMode),
                        keyBytes.baseAddress, key.count,
                        nil,
                        counterBytes.baseAddress, blockSize,
                        keystreamBytes.baseAddress, blockSize,
                        &numBytesEncrypted
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw DecryptionError.invalidData
        }

        // XOR data with keystream
        let blockEnd = min(offset + blockSize, data.count)
        for idx in offset ..< blockEnd {
            result[idx] = data[idx] ^ keystreamBlock[idx - offset]
        }

        incrementCounter(&counter)
        offset += blockSize
    }

    return result
}

/// Decrypts data using AES-CTR mode from a specific byte offset.
private func decryptAESCTR(data: Data, key: Data, offset: Int) throws -> Data {
    var result = Data(count: data.count)
    let blockSize = kCCBlockSizeAES128
    let blockOffset = max(0, offset) / blockSize
    let byteOffset = max(0, offset) % blockSize

    // 12-byte nonce + 4-byte counter (big-endian block index)
    var counter = Data(repeating: 0, count: 16)
    var blockIndex = UInt32(blockOffset)
    for idx in stride(from: 15, through: 12, by: -1) {
        counter[idx] = UInt8(blockIndex & 0xFF)
        blockIndex >>= 8
    }

    var dataOffset = 0
    while dataOffset < data.count {
        var keystreamBlock = Data(count: blockSize)
        var numBytesEncrypted: size_t = 0

        let status = keystreamBlock.withUnsafeMutableBytes { keystreamBytes in
            counter.withUnsafeBytes { counterBytes in
                key.withUnsafeBytes { keyBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionECBMode),
                        keyBytes.baseAddress, key.count,
                        nil,
                        counterBytes.baseAddress, blockSize,
                        keystreamBytes.baseAddress, blockSize,
                        &numBytesEncrypted
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw DecryptionError.invalidData
        }

        let keystreamStart = dataOffset == 0 ? byteOffset : 0
        let available = blockSize - keystreamStart
        let remaining = data.count - dataOffset
        let toProcess = min(available, remaining)
        if toProcess <= 0 {
            break
        }

        for idx in 0 ..< toProcess {
            result[dataOffset + idx] =
                data[dataOffset + idx]
                    ^ keystreamBlock[keystreamStart + idx]
        }

        incrementCounter(&counter)
        dataOffset += toProcess
    }

    return result
}

/// Increments a 16-byte counter (last 4 bytes, big-endian).
private func incrementCounter(_ counter: inout Data) {
    for idx in stride(from: 15, through: 12, by: -1) {
        counter[idx] = counter[idx] &+ 1
        if counter[idx] != 0 {
            break
        }
    }
}

extension Data {
    /// Initializes Data from a hex-encoded string.
    nonisolated init?(hexString: String) {
        let hex = hexString.replacingOccurrences(of: " ", with: "")
        guard hex.count.isMultiple(of: 2) else { return nil }

        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex

        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index ..< nextIndex], radix: 16) else {
                return nil
            }
            data.append(byte)
            index = nextIndex
        }

        self = data
    }
}
