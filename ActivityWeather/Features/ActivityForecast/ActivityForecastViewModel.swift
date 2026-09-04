import Observation

enum ActivityForecastStatus: Equatable {
    case idle
    case loading
    case loaded(LocationActivityForecast)
    case failure
}

@MainActor
@Observable
final class ActivityForecastViewModel {
    private(set) var status: ActivityForecastStatus = .idle
    private(set) var selectedActivity: Activity = .skiing
    private(set) var failure: UserFacingFailure?

    @ObservationIgnored private let location: Location
    @ObservationIgnored private let getActivityForecast: GetActivityForecastUseCase
    @ObservationIgnored private var activeLoadTask: Task<Void, Never>?
    @ObservationIgnored private var generation = 0

    init(
        location: Location,
        getActivityForecast: GetActivityForecastUseCase
    ) {
        self.location = location
        self.getActivityForecast = getActivityForecast
    }

    func load() {
        guard case .idle = status else {
            return
        }
        startLoad()
    }

    func retry() {
        guard case .failure = status else {
            return
        }
        startLoad()
    }

    func cancel() {
        generation += 1
        activeLoadTask?.cancel()
        activeLoadTask = nil
        if case .loading = status {
            status = .idle
        }
    }

    func selectActivity(_ activity: Activity) {
        selectedActivity = activity
    }

    var loadedForecast: LocationActivityForecast? {
        guard case let .loaded(forecast) = status else {
            return nil
        }
        return forecast
    }

    var selectedRanking: ActivityDayRanking? {
        loadedForecast?.rankings.first { $0.activity == selectedActivity }
    }

    var bestDay: DailyActivitySuitability? {
        selectedRanking?.days.first
    }

    var locationName: String {
        location.displayName
    }

    private func startLoad() {
        generation += 1
        activeLoadTask?.cancel()
        failure = nil
        status = .loading

        let requestGeneration = generation
        let getActivityForecast = getActivityForecast
        let location = location

        activeLoadTask = Task { [weak self, getActivityForecast, location] in
            do {
                let result = try await getActivityForecast.execute(location: location)
                try Task.checkCancellation()
                guard self?.generation == requestGeneration else {
                    return
                }
                self?.failure = nil
                self?.status = .loaded(result)
                self?.activeLoadTask = nil
            } catch is CancellationError {
                // View teardown and obsolete loads are expected cancellation.
            } catch {
                guard !Task.isCancelled,
                      self?.generation == requestGeneration else {
                    return
                }
                self?.failure = UserFacingFailure.classify(error)
                self?.status = .failure
                self?.activeLoadTask = nil
            }
        }
    }
}
