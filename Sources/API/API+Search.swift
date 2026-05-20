import Foundation

private let kSearchInstantMixedType = "album%2Cartist%2Cplaylist%2Ctrack"

extension API {
    func searchInstantMixed(
        text: String,
        page: Int = 0,
        pageSize: Int = 36
    ) async throws -> SearchMixedResponse {
        let encodedText = percentEncodeSearchText(text)

        return try await request("search/instant/mixed") {
            $0.queryItems(
                .init(name: "text", value: encodedText),
                .init(name: "type", value: kSearchInstantMixedType),
                .init(name: "page", value: String(page)),
                .init(name: "pageSize", value: String(pageSize)),
                .init(name: "withLikesCount", value: "true"),
                .init(name: "withBestResults", value: "true")
            )
            .userAgent(.desktopApp)
        }
    }
}

private let kSearchTextAllowedCharacters: CharacterSet = {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: ":#[]@!$&'()*+,;=?/%")
    return allowed
}()

private func percentEncodeSearchText(_ text: String) -> String {
    text
        .addingPercentEncoding(withAllowedCharacters: kSearchTextAllowedCharacters) ??
        text
}
