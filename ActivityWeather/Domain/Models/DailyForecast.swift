struct DailyForecast: Equatable, Sendable {
    let date: CivilDate
    let weatherCode: Int
    let maximumTemperatureCelsius: Double
    let minimumTemperatureCelsius: Double
    let maximumApparentTemperatureCelsius: Double
    let precipitationMillimetres: Double
    let rainMillimetres: Double
    let snowfallCentimetres: Double
    let precipitationHours: Double
    let maximumWindSpeedKilometresPerHour: Double
    let maximumWindGustKilometresPerHour: Double
    let sunshineDurationSeconds: Double
    let daylightDurationSeconds: Double
    let maximumUVIndex: Double
}
