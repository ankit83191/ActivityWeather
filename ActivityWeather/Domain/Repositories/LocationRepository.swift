protocol LocationRepository: Sendable {
    func locations(matching query: String) async throws -> [Location]
}
