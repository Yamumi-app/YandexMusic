import Foundation

public let kDefaultBaseURL: URL = {
    guard let url = URL(string: "https://api.music.yandex.net") else {
        preconditionFailure("Invalid default Yandex Music API URL")
    }
    return url
}()

enum APIError: Error {
    case invalidResponse
    case httpError(statusCode: Int)
    case invalidURL(String)
    case requestBuildFailed(String)
}

actor API {
    private let baseURL: URL
    private let session: URLSession
    private let language: YandexMusicLanguage
    var token: String?

    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init(
        token: String? = nil,
        baseURL: URL = kDefaultBaseURL,
        session: URLSession = .shared,
        language: YandexMusicLanguage = .english
    ) {
        self.baseURL = baseURL
        self.session = session
        self.language = language
        self.token = token
    }

    /// Updates the token and resets cached account info.
    func updateToken(_ token: String) {
        self.token = token
    }

    func request<T: Decodable>(
        _ path: String,
        fullURL: Bool = false,
        _ transform: RequestTransformer? = nil
    ) async throws -> T {
        let (data, _) = try await requestDataWithResponse(
            path,
            fullURL: fullURL,
            transform
        )

        // Try to decode the response as a Result<T> and then directly
        if let decoded = try? jsonDecoder.decode(Result<T>.self, from: data) {
            return decoded.result
        }
        return try jsonDecoder.decode(T.self, from: data)
    }

    func request(
        _ path: String,
        fullURL: Bool = false,
        _ transform: RequestTransformer? = nil
    ) async throws -> Data {
        let (data, _) = try await requestDataWithResponse(
            path,
            fullURL: fullURL,
            transform
        )
        return data
    }

    /// Requests data from the API
    /// - Parameters:
    ///   - path: The path to the API endpoint
    ///   - transform: A transform function to modify the request builder
    ///   - fullURL: If active, the path will be used as a full URL (baseURL will be
    /// ignored)
    /// - Returns: The data from the API
    func requestData(
        _ path: String,
        fullURL: Bool = false,
        _ transform: RequestTransformer? = nil
    ) async throws -> Data {
        let (data, _) = try await requestDataWithResponse(
            path,
            fullURL: fullURL,
            transform
        )
        return data
    }

    func requestDataWithResponse(
        _ path: String,
        fullURL: Bool = false,
        _ transform: RequestTransformer? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        var builder = RequestBuilder(path, token: token, language: language)
        if let transform {
            builder = transform(builder)
        }
        let request: URLRequest
        do {
            request = try builder.build(baseURL: fullURL ? nil : baseURL)
        } catch let error as RequestError {
            switch error {
            case let .invalidURL(path):
                throw APIError.invalidURL(path)
            case let .invalidURLComponents(url):
                throw APIError.invalidURL(url)
            case let .encodingError(message):
                throw APIError.requestBuildFailed(message)
            }
        } catch {
            throw APIError.requestBuildFailed(error.localizedDescription)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 206 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        return (data, httpResponse)
    }
}
