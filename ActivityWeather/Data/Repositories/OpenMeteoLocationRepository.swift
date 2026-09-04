import Foundation

struct OpenMeteoLocationRepository: LocationRepository {
    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func locations(matching query: String) async throws -> [Location] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            return []
        }

        do {
            let response: GeocodingResponseDTO = try await client.execute(
                OpenMeteoGeocodingEndpoint.search(name: trimmed)
            )
            return try GeocodingLocationMapper.locations(from: response)
        } catch {
            throw RepositoryFailureMapping.map(error)
        }
    }
}
