struct OpenMeteoForecastRepository: ForecastRepository {
    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func forecast(for location: Location) async throws -> WeeklyForecast {
        let response: ForecastResponseDTO = try await client.execute(
            OpenMeteoForecastEndpoint.forecast(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        )
        return try ForecastMapper.weeklyForecast(from: response)
    }
}
