let kRotorFeedbackFrom = "web-home-rup_main-radio-default"

extension API {
    /// Creates a new rotor session.
    ///
    /// - Parameters:
    ///   - seeds: Seeds to create the session.
    ///   - queue: Queue to create the session.
    /// - Returns: A tuple containing the session ID and the first batch of tracks.
    func createRotorSession(
        seeds: [StationSeed],
        queue: [String]
    ) async throws -> (String, RotorSessionBatch) {
        try await createRotorSession(
            seeds: seeds.map(\.full),
            queue: queue
        )
    }

    func createRotorSession(
        seeds: [String],
        queue: [String]
    ) async throws -> (String, RotorSessionBatch) {
        let response: RotorSessionNewResponse = try await request("rotor/session/new") {
            $0
                .body(
                    .json(
                        NewRotorSessionRequest(
                            seeds: seeds,
                            queue: queue
                        )
                    )
                )
                .userAgent(.desktopApp)
        }
        return (response.radioSessionId, RotorSessionBatch(
            sequence: response.sequence,
            batchId: response.batchId
        ))
    }

    func sendRotorSessionFeedback(
        sessionID: String,
        batchID: String,
        event: RotorSessionEvent
    ) async throws {
        _ = try await request("rotor/session/\(sessionID)/feedback") {
            $0.body(
                .json(
                    RotorSessionFeedback(
                        batchId: batchID,
                        event: event,
                        from: kRotorFeedbackFrom
                    )
                )
            )
        }
    }

    func getRotorSessionBatch(
        sessionID: String,
        previousBatchID: String,
        events: [RotorSessionEvent],
        queue: [String]
    ) async throws -> RotorSessionBatch {
        let feedbacks: [RotorSessionFeedback] = events.map { event in
            .init(batchId: previousBatchID, event: event, from: kRotorFeedbackFrom)
        }
        return try await request("rotor/session/\(sessionID)/tracks") {
            $0.body(.json(RotorSessionTracksRequest(
                queue: queue,
                feedbacks: feedbacks
            )))
        } as RotorSessionBatch
    }
}

private struct RotorSessionFeedback: Encodable {
    let batchId: String
    let event: RotorSessionEvent
    let from: String
}

private struct RotorSessionTracksRequest: Encodable {
    let queue: [String]
    let feedbacks: [RotorSessionFeedback]
}

/// Result containing a batch of tracks from a rotor station.
private struct RotorSessionNewResponse: Decodable {
    let radioSessionId: String
    let sequence: [StationSequenceItem]
    let batchId: String
}
