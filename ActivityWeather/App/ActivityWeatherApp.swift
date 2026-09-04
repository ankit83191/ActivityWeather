import SwiftUI

@main
@MainActor
struct ActivityWeatherApp: App {
    @State private var locationSearchViewModel: LocationSearchViewModel

    init() {
        let dependencies = AppDependencies.live()
        _locationSearchViewModel = State(
            initialValue: LocationSearchViewModel(
                searchLocations: dependencies.searchLocations
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            LocationSearchView(viewModel: locationSearchViewModel)
        }
    }
}
