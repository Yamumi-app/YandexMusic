private let kWheelNewURL = "https://api.music.yandex.com/wheel/new"

extension API {
    func getWheel(
        seeds: [String],
        feedbacks: [WheelFeedback]
    ) async throws -> WheelResponse {
        try await request(kWheelNewURL, fullURL: true) {
            $0
                .body(.json(NewWheelRequest(seeds: seeds, feedbacks: feedbacks)))
                .userAgent(.desktopApp)
        }
    }
}

private struct NewWheelRequest: Encodable {
    let context: WheelRequestContext
    let feedbacks: [WheelFeedback]

    init(seeds: [String], feedbacks: [WheelFeedback]) {
        context = WheelRequestContext(seeds: seeds)
        self.feedbacks = feedbacks
    }
}

private struct WheelRequestContext: Encodable {
    let type: String
    let data: WheelRequestData

    init(seeds: [String]) {
        type = "WAVE"
        data = WheelRequestData(seeds: seeds)
    }
}

private struct WheelRequestData: Encodable {
    let seeds: [String]
}
