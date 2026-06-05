import Foundation

public struct WheelResponse: Sendable, Decodable {
    public let wheelId: String
    public let items: [WheelItem]

    private enum CodingKeys: String, CodingKey {
        case wheelId
        case items
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wheelId = try container.decode(String.self, forKey: .wheelId)
        let rawItems = try container.decode([RawWheelItem].self, forKey: .items)
        items = rawItems.compactMap(\.item)
    }
}

public struct WheelItem: Sendable, Decodable {
    public let id: String
    public let type: String
    public let style: String
    public let description: String?
    public let data: WheelItemData
}

public struct WheelItemData: Sendable, Decodable {
    public let wave: WheelWave
    public let agent: WheelAgent
}

public struct WheelWave: Sendable, Decodable {
    public let name: String
    public let description: String?
    public let seeds: [String]
}

public struct WheelAgent: Sendable, Decodable {
    public let animationUri: String
    public let cover: WheelCover
}

public struct WheelCover: Sendable, Decodable {
    public let uri: URLTemplate
    public let color: String
}

public enum WheelFeedbackEventType: String, Sendable, Encodable {
    case view = "VIEW"
}

public struct WheelFeedbackItem: Sendable, Encodable {
    public let type: String
    public let id: String

    public init(type: String, id: String) {
        self.type = type
        self.id = id
    }
}

public struct WheelFeedback: Sendable, Encodable {
    public let wheelId: String
    public let timestamp: Int64
    public let eventType: WheelFeedbackEventType
    public let item: WheelFeedbackItem
    public let position: Int

    public init(
        wheelId: String,
        timestamp: Int64,
        eventType: WheelFeedbackEventType,
        item: WheelFeedbackItem,
        position: Int
    ) {
        self.wheelId = wheelId
        self.timestamp = timestamp
        self.eventType = eventType
        self.item = item
        self.position = position
    }

    public static func view(
        wheelId: String,
        item: WheelItem,
        position: Int,
        timestamp: Int64
    ) -> Self {
        Self(
            wheelId: wheelId,
            timestamp: timestamp,
            eventType: .view,
            item: WheelFeedbackItem(type: item.type, id: item.id),
            position: position
        )
    }

    public static func view(
        wheelId: String,
        item: WheelItem,
        position: Int
    ) -> Self {
        view(
            wheelId: wheelId,
            item: item,
            position: position,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }
}

private struct RawWheelItem: Decodable {
    let item: WheelItem?

    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type)

        if type == "WAVE" {
            item = try WheelItem(from: decoder)
        } else {
            item = nil
        }
    }
}
