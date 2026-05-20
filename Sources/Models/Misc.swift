/// Response wrapper. Sometime Yandex Music API returns { result: ... } structure.
struct Result<T: Decodable>: Decodable {
    let result: T
}

/// Helper to decode either String or Int from JSON.
public struct StringOrInt: Sendable, Codable {
    public let value: String

    init(_ value: String) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = String(intValue)
        } else {
            value = try container.decode(String.self)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

struct Pager: Decodable {
    let total: Int
    let page: Int
    let perPage: Int
}
