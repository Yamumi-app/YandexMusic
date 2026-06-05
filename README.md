# YandexMusic

Unofficial Swift SDK for the Yandex Music streaming service API.

## Requirements

- Swift 6.2+
- macOS 15+

## Installation

Add the package dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/Yamumi-app/YandexMusic.git", from: "1.0.0")
```

Or add it via Xcode: **File → Add Package Dependencies**.

## Usage

```swift
import YandexMusic

let client = YandexMusicClient(
    token: "<YOUR_API_TOKEN>",
    codecs: [.flac, .aac, .mp3]
)

// Fetch track metadata
let track = try await client.getTrack(id: "12345678")

// Search
let results = try await client.search(text: "The Beatles")

// Get your liked tracks
let liked = try await client.getLikedTracks()

// Download and decrypt audio
let data = try await client.getTrackData(id: "12345678", quality: .lossless)
try data.data.write(to: URL(fileURLWithPath: "~/Music/track.flac"))

// Start a radio session
let (sessionID, batch) = try await client.createRotorSession(
    settings: .onYourWave, queue: []
)

// Get Wave seed suggestions and start a radio session from one of them
let wheel = try await client.getWheel()
let item = wheel.items[0]
let (wheelSessionID, wheelBatch) = try await client.createRotorSession(
    wheelItem: item,
    queue: []
)
```

## Features

- **Catalog** — tracks, albums, artists, playlists
- **Library** — liked tracks, albums, artists; personal playlists
- **Search** — mixed results across all content types
- **Download** — resolve download URLs, decrypt `encraw` streams (AES-CTR), partial downloads
- **Wheel** — get Wave seed suggestions for Smart Radio sessions
- **Codecs & Quality** — FLAC, AAC, HE-AAC, MP3 at lossless / normal / low
- **Smart Radio (Rotor)** — create sessions, get track batches, send playback feedback
- **URL Parsing** — typed parsing of Yandex Music share links

## Playground

The included `Playground` target demonstrates real-world usage:

```bash
swift run Playground search "The Beatles"
swift run Playground liked
swift run Playground rotor
swift run Playground wheel
swift run Playground wheel-rotor
```

Set the `YA_MUSIC_API_TOKEN` environment variable before running.

## License

MIT
