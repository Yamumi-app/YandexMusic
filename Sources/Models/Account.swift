/// Represents the account status from Yandex Music API.
struct AccountStatus: Decodable {
    let account: Account
}

/// Represents the account information from Yandex Music API.
struct Account: Decodable {
    let uid: Int
}
