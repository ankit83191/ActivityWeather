import Foundation

enum OpenMeteoGeocodingEndpoint {
    static func search(name: String) -> APIEndpoint {
        APIEndpoint(
            scheme: "https",
            host: "geocoding-api.open-meteo.com",
            path: "/v1/search",
            queryItems: [
                URLQueryItem(name: "name", value: name),
                URLQueryItem(name: "count", value: "10"),
                URLQueryItem(name: "language", value: "en"),
                URLQueryItem(name: "format", value: "json")
            ]
        )
    }
}
