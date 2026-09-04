import Foundation
@testable import ActivityWeather

enum UseCaseFixture {
    static func location(id: Int = 1, name: String = "Paris") throws -> Location {
        Location(
            id: id,
            displayName: name,
            region: nil,
            country: "France",
            coordinate: try Coordinate(latitude: 48.8566, longitude: 2.3522),
            elevationMetres: nil,
            geocodingTimeZoneIdentifier: "Europe/Paris"
        )
    }
}

actor LocationRepositorySpy: LocationRepository {
    private(set) var queries: [String] = []
    private let result: Result<[Location], Error>

    init(result: Result<[Location], Error>) {
        self.result = result
    }

    func locations(matching query: String) async throws -> [Location] {
        queries.append(query)
        return try result.get()
    }
}

actor ForecastRepositorySpy: ForecastRepository {
    private(set) var locations: [Location] = []
    private let result: Result<WeeklyForecast, Error>

    init(result: Result<WeeklyForecast, Error>) {
        self.result = result
    }

    func forecast(for location: Location) async throws -> WeeklyForecast {
        locations.append(location)
        return try result.get()
    }
}

final class ScoringSpy: ActivityScoring, @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [(date: CivilDate, activity: Activity)] = []

    var calls: [(date: CivilDate, activity: Activity)] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func suitability(for forecast: DailyForecast, activity: Activity) -> DailyActivitySuitability {
        lock.lock()
        recorded.append((forecast.date, activity))
        lock.unlock()
        return DailyActivitySuitability(
            day: forecast,
            activity: activity,
            score: SuitabilityScore(clamping: 50),
            reasons: []
        )
    }
}
