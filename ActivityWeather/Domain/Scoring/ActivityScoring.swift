protocol ActivityScoring: Sendable {
    func suitability(
        for forecast: DailyForecast,
        activity: Activity
    ) -> DailyActivitySuitability
}

extension ActivityScoring {
    func rankedSuitability(
        for week: WeeklyForecast,
        activity: Activity
    ) -> [DailyActivitySuitability] {
        week.days
            .map { suitability(for: $0, activity: activity) }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                return lhs.date < rhs.date
            }
    }
}
