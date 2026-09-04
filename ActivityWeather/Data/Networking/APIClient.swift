import Foundation

protocol APIClient: Sendable {
    func execute<Response: Decodable & Sendable>(_ endpoint: APIEndpoint) async throws -> Response
}
