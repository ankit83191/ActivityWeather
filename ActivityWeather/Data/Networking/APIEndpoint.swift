import Foundation

struct APIEndpoint: Sendable, Equatable {
    let scheme: String
    let host: String
    let path: String
    let queryItems: [URLQueryItem]

    func url() throws -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidRequest
        }
        return url
    }

    func urlRequest() throws -> URLRequest {
        URLRequest(url: try url())
    }
}
