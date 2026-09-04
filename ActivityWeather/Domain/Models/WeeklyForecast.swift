import Foundation

struct WeeklyForecast: Equatable, Sendable {
    let timeZoneIdentifier: String
    let days: [DailyForecast]

    init(timeZoneIdentifier: String, days: [DailyForecast]) throws {
        guard TimeZone(identifier: timeZoneIdentifier) != nil else {
            throw DomainError.invalidForecastTimezone
        }
        guard days.count == 7,
              zip(days, days.dropFirst()).allSatisfy({ current, next in
                  current.date.isImmediatelyBefore(next.date)
              }) else {
            throw DomainError.invalidForecastWindow
        }

        self.timeZoneIdentifier = timeZoneIdentifier
        self.days = days
    }
}
