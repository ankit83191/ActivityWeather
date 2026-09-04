protocol ActivityScoring: Sendable {
    func suitability(
        for forecast: DailyForecast,
        activity: Activity
    ) -> DailyActivitySuitability
}
