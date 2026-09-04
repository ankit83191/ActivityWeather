protocol ForecastRepository: Sendable {
    func forecast(for location: Location) async throws -> WeeklyForecast
}
