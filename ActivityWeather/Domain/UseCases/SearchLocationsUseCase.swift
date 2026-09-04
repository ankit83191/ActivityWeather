import Foundation

struct SearchLocationsUseCase: Sendable {
    private let repository: any LocationRepository

    init(repository: any LocationRepository) {
        self.repository = repository
    }

    func execute(query: String) async throws -> [Location] {
        try await repository.locations(
            matching: query.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
