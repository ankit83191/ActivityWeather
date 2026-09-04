import Foundation

struct AppDependencies: Sendable {
    let searchLocations: SearchLocationsUseCase
    let getActivityForecast: GetActivityForecastUseCase

    private init(
        searchLocations: SearchLocationsUseCase,
        getActivityForecast: GetActivityForecastUseCase
    ) {
        self.searchLocations = searchLocations
        self.getActivityForecast = getActivityForecast
    }

    /// Production composition. The app root uses these values to construct
    /// narrow feature dependencies; this container is never passed to a View.
    static func live(
        client: any APIClient = URLSessionAPIClient(session: .shared)
    ) -> AppDependencies {
        AppDependencies(
            searchLocations: SearchLocationsUseCase(
                repository: OpenMeteoLocationRepository(client: client)
            ),
            getActivityForecast: GetActivityForecastUseCase(
                forecastRepository: OpenMeteoForecastRepository(client: client),
                scoring: SuitabilityScoringEngine()
            )
        )
    }
}
