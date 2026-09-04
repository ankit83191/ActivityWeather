struct ActivityDayRanking: Sendable, Equatable {
    let activity: Activity
    let days: [DailyActivitySuitability]
}

struct LocationActivityForecast: Sendable, Equatable {
    let location: Location
    let forecast: WeeklyForecast
    let rankings: [ActivityDayRanking]
}
