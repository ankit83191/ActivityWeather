import SwiftUI

struct LocationSearchView: View {
    let viewModel: LocationSearchViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                content
            }
            .navigationTitle("Find a location")
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
        case let .results(locations):
            List(locations) { location in
                locationRow(location)
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.interactively)
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
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(locationSubtitle(location))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(locationAccessibilityLabel(location))
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var failureContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("Couldn’t search locations")
                .font(.headline)
            Text("Check your connection and try again.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again", action: viewModel.retry)
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Repeats the previous location search")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func message(_ text: String, systemImage: String) -> some View {
        ContentUnavailableView(
            text,
            systemImage: systemImage
        )
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
