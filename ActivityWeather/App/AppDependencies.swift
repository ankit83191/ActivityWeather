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

    /// Production composition. Milestone 9 will construct the search ViewModel
    /// from these use cases; `ContentView` is not given this container.
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
