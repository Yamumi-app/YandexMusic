extension API {
    /// Fetches the current user's account status
    func getAccountStatus() async throws -> AccountStatus {
        try await request("account/status") as AccountStatus
    }
}
