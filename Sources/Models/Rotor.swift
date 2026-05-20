/// Language for rotor stations.
public enum RotorLanguage: String, Sendable {
    case russian = "ru"
    case english = "en"
}

/// Identifier for a rotor station.
public struct StationSeed: Sendable, Codable {
    public let type: String
    public let tag: String

    public static let onYourWave = Self(type: "user", tag: "onyourwave")

    public var full: String {
        "\(type):\(tag)"
    }
}

/// Information about a rotor station.
public struct StationInfo: Sendable, Codable {
    public let id: StationSeed
    public let name: String
}

/// A rotor station with its information.
public struct RotorStation: Sendable, Codable {
    public let station: StationInfo
}

/// A single item in the rotor sequence (usually a track).
public struct StationSequenceItem: Sendable, Decodable {
    public let type: String
    public let track: Track?
    public let liked: Bool
}

public enum RotorSettingActivity: String, Sendable, Codable {
    case wakingUp = "wake-up"
    case traveling = "road-trip"
    case working = "work-background"
    case workingOut = "workout"
    case fallingAsleep = "fall-asleep"
}

public enum RotorSettingDiversity: String, Sendable, Codable {
    case favorite
    case unfamiliar = "diverse"
    case popular
}

public enum RotorSettingMood: String, Sendable, Codable {
    case energetic = "active"
    case cheerful = "fun"
    case calm
    case sad
}

public enum RotorSettingLanguage: String, Sendable, Codable {
    case any
    case russian
    case notRussian = "not-russian"
    case withoutWords = "without-words"
}

public struct RotorSettings: Sendable {
    public let activity: RotorSettingActivity?
    public let diversity: RotorSettingDiversity?
    public let mood: RotorSettingMood?
    public let language: RotorSettingLanguage?

    public init(
        activity: RotorSettingActivity?,
        diversity: RotorSettingDiversity?,
        mood: RotorSettingMood?,
        language: RotorSettingLanguage?
    ) {
        self.activity = activity
        self.diversity = diversity
        self.mood = mood
        self.language = language
    }

    public static let onYourWave = Self(
        activity: nil,
        diversity: nil,
        mood: nil,
        language: nil
    )

    var seeds: [StationSeed] {
        var settingSeeds: [StationSeed] = []
        if let activity {
            settingSeeds.append(StationSeed(type: "activity", tag: activity.rawValue))
        } else {
            settingSeeds.append(StationSeed.onYourWave)
        }

        if let diversity {
            settingSeeds.append(StationSeed(
                type: "settingDiversity",
                tag: diversity.rawValue
            ))
        }
        if let mood {
            settingSeeds.append(StationSeed(
                type: "settingMoodEnergy",
                tag: mood.rawValue
            ))
        }
        if let language {
            settingSeeds.append(StationSeed(
                type: "settingLanguage",
                tag: language.rawValue
            ))
        }

        return settingSeeds
    }
}

/// Request to create a new rotor session.
struct NewRotorSessionRequest: Codable {
    let seeds: [String]
    let queue: [String]
    let includeTracksInResponse: Bool
    let includeWaveModel: Bool
    let interactive: Bool

    init(seeds: [String], queue: [String]) {
        self.seeds = seeds
        self.queue = queue
        includeTracksInResponse = true
        includeWaveModel = true
        interactive = true
    }
}

/// Result containing a batch of tracks from a rotor station.
public struct RotorSessionBatch: Sendable, Decodable {
    public let sequence: [StationSequenceItem]
    public let batchId: String
}

public enum RotorSessionEventType: String, Sendable, Encodable {
    case radioStarted
    case trackStarted
    case trackFinished
    case skip
}

public struct RotorSessionEvent: Sendable, Encodable {
    public let type: RotorSessionEventType
    /// ISO 8601 UTC aligned string
    public let timestamp: String
    public let trackId: String?
    public let totalPlayedSeconds: Double?
    public let trackLengthSeconds: Double?

    public static func trackStarted(trackId: String, timestamp: String) -> Self {
        Self(
            type: .trackStarted,
            timestamp: timestamp,
            trackId: trackId,
            totalPlayedSeconds: nil,
            trackLengthSeconds: nil
        )
    }

    public static func trackFinished(
        trackId: String,
        timestamp: String,
        totalPlayedSeconds: Double
    ) -> Self {
        Self(
            type: .trackFinished,
            timestamp: timestamp,
            trackId: trackId,
            totalPlayedSeconds: totalPlayedSeconds,
            trackLengthSeconds: nil
        )
    }

    public static func skip(
        trackId: String,
        timestamp: String,
        totalPlayedSeconds: Double
    ) -> Self {
        Self(
            type: .skip,
            timestamp: timestamp,
            trackId: trackId,
            totalPlayedSeconds: totalPlayedSeconds,
            trackLengthSeconds: nil
        )
    }

    public static func radioStarted(timestamp: String) -> Self {
        Self(
            type: .radioStarted,
            timestamp: timestamp,
            trackId: nil,
            totalPlayedSeconds: nil,
            trackLengthSeconds: nil
        )
    }
}

//   {
//             "batchId": "9238dc33-9feb-4d48-b7e1-32226334fa64.4Wql",
//             "event": {
//                 "type": "skip",
//                 "timestamp": "2026-01-19T15:51:28.220Z",
//                 "trackId": "48591434:2718352",
//                 "totalPlayedSeconds": 3.442
//             },
//             "from": "web-home-rup_main-radio-default"
//         }

// {
//     "event": {
//         "type": "radioStarted",
//         "timestamp": "2026-01-19T17:17:09.781Z",
//         "from": "web-home-rup_main-radio-default"
//     },
//     "from": "web-home-rup_main-radio-default"
// }

// {
//     "event": {
//         "type": "trackStarted",
//         "timestamp": "2026-01-19T17:17:25.564Z",
//         "trackId": "136683512:35643719"
//     },
//     "batchId": "4bd4f81e-9fa7-4254-86e7-6264511cdd6c.7TkS",
//     "from": "web-home-rup_main-radio-default"
// }
