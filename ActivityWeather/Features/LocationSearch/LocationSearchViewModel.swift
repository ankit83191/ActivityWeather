import Observation
import Foundation

enum LocationSearchStatus: Equatable {
    case idle
    case loading
    case results([Location])
    case empty
    case failure
}

@MainActor
@Observable
final class LocationSearchViewModel {
    private(set) var query = ""
    private(set) var status: LocationSearchStatus = .idle
    private(set) var selectedLocation: Location?

    @ObservationIgnored private let searchLocations: SearchLocationsUseCase
    @ObservationIgnored private let sleeper: any SearchSleeping
    @ObservationIgnored private var activeSearchTask: Task<Void, Never>?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var failedQuery: String?

    init(
        searchLocations: SearchLocationsUseCase,
        sleeper: any SearchSleeping = TaskSearchSleeper()
    ) {
        self.searchLocations = searchLocations
        self.sleeper = sleeper
    }

    func updateQuery(_ query: String) {
        guard query != self.query else {
            return
        }

        self.query = query
        selectedLocation = nil
        failedQuery = nil
        cancelActiveSearch()

        let normalized = normalizedQuery
        guard normalized.count >= 2 else {
            status = .idle
            return
        }

        status = .idle
        startSearch(for: normalized, debounced: true)
    }

    func submit() {
        cancelActiveSearch()
        let normalized = normalizedQuery
        guard normalized.count >= 2 else {
            status = .idle
            failedQuery = nil
            return
        }

        startSearch(for: normalized, debounced: false)
    }

    func retry() {
        guard case .failure = status, let failedQuery else {
            return
        }

        cancelActiveSearch()
        startSearch(for: failedQuery, debounced: false)
    }

    func select(_ location: Location) {
        selectedLocation = location
    }

    var helperText: String {
        showsMinimumLengthHint
            ? "Enter at least 2 characters"
            : "Search for a city"
    }

    var showsMinimumLengthHint: Bool {
        normalizedQuery.count == 1
    }

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cancelActiveSearch() {
        generation += 1
        activeSearchTask?.cancel()
        activeSearchTask = nil
    }

    private func startSearch(for normalizedQuery: String, debounced: Bool) {
        generation += 1
        let requestGeneration = generation
        let searchLocations = searchLocations
        let sleeper = sleeper

        activeSearchTask = Task { [weak self, searchLocations, sleeper] in
            do {
                if debounced {
                    try await sleeper.sleep()
                }
                try Task.checkCancellation()

                guard self?.generation == requestGeneration else {
                    return
                }
                self?.status = .loading

                let locations = try await searchLocations.execute(query: normalizedQuery)
                try Task.checkCancellation()

                guard self?.generation == requestGeneration else {
                    return
                }
                self?.failedQuery = nil
                self?.status = locations.isEmpty ? .empty : .results(locations)
                self?.activeSearchTask = nil
            } catch is CancellationError {
                // Cancellation is expected when the query changes, submit is
                // pressed, or retry begins. It is not a user-visible failure.
            } catch {
                guard !Task.isCancelled,
                      self?.generation == requestGeneration else {
                    return
                }
                self?.failedQuery = normalizedQuery
                self?.status = .failure
                self?.activeSearchTask = nil
            }
        }
    }
}
