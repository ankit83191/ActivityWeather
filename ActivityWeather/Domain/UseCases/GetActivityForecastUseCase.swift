struct GetActivityForecastUseCase: Sendable {
    private let forecastRepository: any ForecastRepository
    private let scoring: any ActivityScoring

    init(
        forecastRepository: any ForecastRepository,
        scoring: any ActivityScoring
    ) {
        self.forecastRepository = forecastRepository
        self.scoring = scoring
    }

    func execute(location: Location) async throws -> LocationActivityForecast {
        let forecast = try await forecastRepository.forecast(for: location)
        let rankings = Activity.allCases.map { activity in
            ActivityDayRanking(
                activity: activity,
                days: scoring.rankedSuitability(for: forecast, activity: activity)
            )
        }
        return LocationActivityForecast(
            location: location,
            forecast: forecast,
            rankings: rankings
        )
    }
}
