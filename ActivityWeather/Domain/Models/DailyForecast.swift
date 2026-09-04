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

    init(
        date: CivilDate,
        weatherCode: Int,
        maximumTemperatureCelsius: Double,
        minimumTemperatureCelsius: Double,
        maximumApparentTemperatureCelsius: Double,
        precipitationMillimetres: Double,
        rainMillimetres: Double,
        snowfallCentimetres: Double,
        precipitationHours: Double,
        maximumWindSpeedKilometresPerHour: Double,
        maximumWindGustKilometresPerHour: Double,
        sunshineDurationSeconds: Double,
        daylightDurationSeconds: Double,
        maximumUVIndex: Double
    ) throws {
        let temperatures = [
            maximumTemperatureCelsius,
            minimumTemperatureCelsius,
            maximumApparentTemperatureCelsius
        ]
        let nonNegative = [
            precipitationMillimetres,
            rainMillimetres,
            snowfallCentimetres,
            maximumWindSpeedKilometresPerHour,
            maximumWindGustKilometresPerHour,
            sunshineDurationSeconds,
            daylightDurationSeconds,
            maximumUVIndex
        ]

        guard temperatures.allSatisfy(\.isFinite),
              nonNegative.allSatisfy({ $0.isFinite && $0 >= 0 }),
              precipitationHours.isFinite,
              (0...24).contains(precipitationHours),
              sunshineDurationSeconds <= daylightDurationSeconds else {
            throw DomainError.invalidForecastValues
        }

        self.date = date
        self.weatherCode = weatherCode
        self.maximumTemperatureCelsius = maximumTemperatureCelsius
        self.minimumTemperatureCelsius = minimumTemperatureCelsius
        self.maximumApparentTemperatureCelsius = maximumApparentTemperatureCelsius
        self.precipitationMillimetres = precipitationMillimetres
        self.rainMillimetres = rainMillimetres
        self.snowfallCentimetres = snowfallCentimetres
        self.precipitationHours = precipitationHours
        self.maximumWindSpeedKilometresPerHour = maximumWindSpeedKilometresPerHour
        self.maximumWindGustKilometresPerHour = maximumWindGustKilometresPerHour
        self.sunshineDurationSeconds = sunshineDurationSeconds
        self.daylightDurationSeconds = daylightDurationSeconds
        self.maximumUVIndex = maximumUVIndex
    }
}
