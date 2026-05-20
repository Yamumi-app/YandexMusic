import Foundation

enum RequestError: Error {
    case encodingError(String)
    case invalidURL(String)
    case invalidURLComponents(String)
}

/// Content type options for API requests.
enum ContentType: String {
    case json = "application/json"
    case formUrlEncoded = "application/x-www-form-urlencoded"
}

/// Identifier of Yandex Music client
enum UserAgent: String {
    /// Android client User-Agent for most endpoints.
    case oldAndroid = "YandexMusicAndroid/24023621"
    /// Desktop client User-Agent (required for new requests).
    case desktopApp = "YandexMusicWebNext/1.0.0"
}

/// Language used for localized Yandex Music API responses.
public enum YandexMusicLanguage: Sendable {
    case english
    case russian

    var acceptLanguageHeader: String {
        switch self {
        case .english:
            return "en"
        case .russian:
            return "ru"
        }
    }
}

/// HTTP method
enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
}

/// HTTP header
struct HttpHeader {
    let name: String
    let value: String
}

struct URLFormValue {
    let name: String
    let value: String
}

let kEscapedComma = "%2C"

enum RequestBody {
    case json(Encodable)
    case urlForm([URLFormValue])

    var contentType: ContentType {
        switch self {
        case .urlForm:
            return .formUrlEncoded
        case .json:
            return .json
        }
    }

    func data() throws -> Data {
        switch self {
        case let .json(value):
            return try JSONEncoder().encode(value)
        case let .urlForm(values):
            let data =
                values
                    .map { "\($0.name)=\($0.value)" }
                    .joined(separator: "&")
                    .data(using: .utf8)
            guard let data else {
                throw RequestError.encodingError("Failed to encode URL form values")
            }
            return data
        }
    }
}

typealias RequestTransformer = (RequestBuilder) -> RequestBuilder

/// Builder for Yandex Music API requests
final class RequestBuilder {
    let path: String

    private var headers: [HttpHeader]
    private var queryItems: [URLQueryItem]
    private var token: String?
    private let language: YandexMusicLanguage
    private var userAgent: UserAgent = .oldAndroid
    private var body: RequestBody?

    private var method: HttpMethod {
        if body != nil {
            return .post
        }
        return .get
    }

    init(_ path: String, token: String?, language: YandexMusicLanguage) {
        self.path = path
        self.token = token
        self.language = language
        headers = []
        queryItems = []
    }

    /// Adds query items to the request.
    func queryItems(_ items: URLQueryItem...) -> Self {
        queryItems.append(contentsOf: items)
        return self
    }

    /// Sets the user agent of the request.
    func userAgent(_ userAgent: UserAgent) -> Self {
        self.userAgent = userAgent
        return self
    }

    /// Sets the body of the request.
    func body(_ body: RequestBody) -> Self {
        self.body = body
        return self
    }

    /// Adds headers to the request.
    func headers(_ headers: HttpHeader...) -> Self {
        self.headers.append(contentsOf: headers)
        return self
    }

    /// Builds the request.
    func build(baseURL: URL?) throws -> URLRequest {
        let url: URL
        if let baseURL {
            guard let resolvedURL = URL(string: path, relativeTo: baseURL) else {
                throw RequestError.invalidURL(path)
            }
            url = resolvedURL
        } else {
            guard let resolvedURL = URL(string: path) else {
                throw RequestError.invalidURL(path)
            }
            url = resolvedURL
        }
        guard var components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: true
        )
        else {
            throw RequestError.invalidURLComponents(url.absoluteString)
        }
        if !queryItems.isEmpty {
            components.percentEncodedQueryItems = queryItems
        }

        guard let requestURL = components.url else {
            throw RequestError.invalidURLComponents(url.absoluteString)
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue

        request.setValue(userAgent.rawValue, forHTTPHeaderField: "X-Yandex-Music-Client")
        request.setValue(
            language.acceptLanguageHeader,
            forHTTPHeaderField: "Accept-Language"
        )

        if let token {
            request.setValue("OAuth \(token)", forHTTPHeaderField: "Authorization")
        }
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }

        if let body {
            request.setValue(
                body.contentType.rawValue,
                forHTTPHeaderField: "Content-Type"
            )
            request.httpBody = try body.data()
        }

        return request
    }
}
