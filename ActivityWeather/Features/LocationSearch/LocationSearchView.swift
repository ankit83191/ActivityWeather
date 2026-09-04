import SwiftUI

struct LocationSearchView<ForecastDestination: View>: View {
    let viewModel: LocationSearchViewModel
    @State private var navigationLocation: Location?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let forecastDestination: (Location) -> ForecastDestination

    init(
        viewModel: LocationSearchViewModel,
        @ViewBuilder forecastDestination: @escaping (Location) -> ForecastDestination
    ) {
        self.viewModel = viewModel
        self.forecastDestination = forecastDestination
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                content
            }
            .navigationTitle("Find a location")
            .navigationBarTitleDisplayMode(
                dynamicTypeSize.isAccessibilitySize ? .inline : .large
            )
            .navigationDestination(item: $navigationLocation) { location in
                forecastDestination(location)
            }
        }
    }

    private var searchField: some View {
        TextField(
            "City or place",
            text: Binding(
                get: { viewModel.query },
                set: { viewModel.updateQuery($0) }
            )
        )
        .textFieldStyle(.roundedBorder)
        .textInputAutocapitalization(.words)
        .autocorrectionDisabled()
        .submitLabel(.search)
        .onSubmit(viewModel.submit)
        .accessibilityLabel("Search for a city or place")
        .accessibilityIdentifier("location-search-field")
        .padding()
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.status {
        case .idle:
            message(
                viewModel.helperText,
                systemImage: viewModel.showsMinimumLengthHint
                    ? "textformat.abc"
                    : "magnifyingglass"
            )
        case .loading:
            ProgressView("Searching locations")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Searching locations")
                .accessibilityIdentifier("location-search-loading")
        case let .results(locations):
            List {
                Section {
                    ForEach(locations) { location in
                        locationRow(location)
                    }
                } footer: {
                    Text("Location data by [Open-Meteo](https://open-meteo.com/) and [GeoNames](https://www.geonames.org/)")
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("location-data-attribution")
                }
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.interactively)
            .accessibilityIdentifier("location-search-results")
        case .empty:
            message("No locations found", systemImage: "mappin.slash")
        case .failure:
            failureContent
        }
    }

    private func locationRow(_ location: Location) -> some View {
        let selected = viewModel.selectedLocation == location

        return Button {
            viewModel.select(location)
            navigationLocation = location
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(locationSubtitle(location))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                if selected {
                    VStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.tint)
                        Text("Selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(locationAccessibilityLabel(location))
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("location-result-\(location.id)")
    }

    private var failureContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("Couldn’t search locations")
                .font(.headline)
            Text((viewModel.failure ?? .generic).recoveryMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again", action: viewModel.retry)
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Repeats the previous location search")
                .accessibilityIdentifier("location-search-retry")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func message(_ text: String, systemImage: String) -> some View {
        ContentUnavailableView(
            text,
            systemImage: systemImage
        )
        .accessibilityIdentifier("location-search-message")
    }

    private func locationSubtitle(_ location: Location) -> String {
        [location.region, location.country]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private func locationAccessibilityLabel(_ location: Location) -> String {
        [location.displayName, location.region, location.country]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}
