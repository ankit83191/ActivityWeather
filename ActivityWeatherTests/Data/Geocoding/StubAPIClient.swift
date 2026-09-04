import Foundation

@testable import ActivityWeather

actor StubAPIClient: APIClient {
    enum Behaviour: Sendable {
        case success(GeocodingResponseDTO)
        case api(APIError)
        case cancellation
        case url(URLError)
    }

    private let behaviour: Behaviour
    private(set) var endpoints: [APIEndpoint] = []

    init(behaviour: Behaviour) {
        self.behaviour = behaviour
    }

    func execute<Response: Decodable & Sendable>(_ endpoint: APIEndpoint) async throws -> Response {
        endpoints.append(endpoint)
        switch behaviour {
        case let .success(dto):
            guard let response = dto as? Response else {
                throw APIError.decoding
            }
            return response
        case let .api(error):
            throw error
        case .cancellation:
            throw CancellationError()
        case let .url(error):
            throw error
        }
    }
}
