import SwiftUI

@main
@MainActor
struct ActivityWeatherApp: App {
    @State private var locationSearchViewModel: LocationSearchViewModel
    private let getActivityForecast: GetActivityForecastUseCase

    init() {
        let dependencies = AppDependencies.live()
        getActivityForecast = dependencies.getActivityForecast
        _locationSearchViewModel = State(
            initialValue: LocationSearchViewModel(
                searchLocations: dependencies.searchLocations
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            LocationSearchView(
                viewModel: locationSearchViewModel
            ) { location in
                ActivityForecastView(
                    viewModel: ActivityForecastViewModel(
                        location: location,
                        getActivityForecast: getActivityForecast
                    )
                )
            }
        }
    }
}
