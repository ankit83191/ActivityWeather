import XCTest
@testable import ActivityWeather

/// Boundary matrix for every numeric threshold and discrete WMO set in `docs/SCORING.md`.
/// Assertions check public score/reason changes, not a cloned engine.
final class ScoringThresholdTests: XCTestCase {
    private let engine = SuitabilityScoringEngine()

    func testOutdoorVetoWeatherCodesAndGustBoundary() throws {
        XCTAssertEqual(try ski(weather: 94).score.value, try ski(weather: 0).score.value)
        XCTAssertEqual(try ski(weather: 95).score.value, 0)
        XCTAssertEqual(try ski(weather: 96).reasons, [.criticalThunderstorm])
        XCTAssertEqual(try ski(weather: 99).reasons, [.criticalThunderstorm])
        XCTAssertEqual(try ski(weather: 66).reasons, [.criticalFreezingRain])
        XCTAssertEqual(try ski(weather: 67).reasons, [.criticalFreezingRain])
        XCTAssertGreaterThan(try ski(weather: 65).score.value, 0)
        XCTAssertGreaterThan(try ski(weather: 56).score.value, 0)
        XCTAssertGreaterThan(try ski(weather: 75).score.value, 0)
        XCTAssertGreaterThan(try ski(weather: 82).score.value, 0)

        XCTAssertGreaterThan(try ski(gusts: 89).score.value, 0)
        XCTAssertFalse(try ski(gusts: 89).reasons.contains(.criticalExtremeWind))
        XCTAssertEqual(try ski(gusts: 90).score.value, 0)
        XCTAssertEqual(try ski(gusts: 91).reasons, [.criticalExtremeWind])
    }

    func testIndoorTravelCapCodesAndGustBoundary() throws {
        XCTAssertFalse(try indoor(weather: 0, gusts: 79).reasons.contains(.dangerousTravelCap))
        XCTAssertEqual(try indoor(weather: 0, precip: 12, gusts: 80).reasons.first, .dangerousTravelCap)
        XCTAssertEqual(try indoor(weather: 0, precip: 12, gusts: 81).score.value, 40)

        for code in [56, 57, 66, 67, 75, 82, 86, 95, 96, 99] {
            XCTAssertEqual(
                try indoor(weather: code, precip: 12).score.value,
                40,
                "code \(code) must apply the indoor travel cap"
            )
        }
        XCTAssertGreaterThan(try indoor(weather: 63, precip: 12).score.value, 40)
    }

    func testSkiingSnowfallRainWindSunshineAndFreezeBands() throws {
        XCTAssertFalse(try ski(snow: 0).reasons.contains(.snowfallAmount))
        XCTAssertTrue(try ski(snow: 1).reasons.contains(.snowfallAmount))
        XCTAssertGreaterThan(try ski(snow: 10).score.value, try ski(snow: 9).score.value)
        XCTAssertEqual(try ski(snow: 10).score.value, try ski(snow: 11).score.value)

        XCTAssertFalse(try ski(weather: 70).reasons.contains(.snowWeather))
        XCTAssertTrue(try ski(weather: 71).reasons.contains(.snowWeather))
        XCTAssertTrue(try ski(weather: 73).reasons.contains(.snowWeather))
        XCTAssertTrue(try ski(weather: 77).reasons.contains(.snowWeather))
        XCTAssertTrue(try ski(weather: 85).reasons.contains(.snowWeather))
        XCTAssertFalse(try ski(weather: 75).reasons.contains(.snowWeather))
        XCTAssertTrue(try ski(weather: 75).reasons.contains(.heavySnowPenalty))
        XCTAssertTrue(try ski(weather: 86).reasons.contains(.heavySnowPenalty))
        XCTAssertTrue(try ski(weather: 56).reasons.contains(.freezingDrizzlePenalty))
        XCTAssertTrue(try ski(weather: 57).reasons.contains(.freezingDrizzlePenalty))

        XCTAssertFalse(try ski(rain: 1.999).reasons.contains(.rainOnSnow))
        XCTAssertTrue(try ski(rain: 2).reasons.contains(.rainOnSnow))
        XCTAssertTrue(try ski(rain: 2.001).reasons.contains(.rainOnSnow))
        XCTAssertGreaterThan(try ski(rain: 1.999).score.value, try ski(rain: 2).score.value)

        XCTAssertFalse(try ski(wind: 45).reasons.contains(.skiWind))
        XCTAssertTrue(try ski(wind: 45.001).reasons.contains(.skiWind))
        XCTAssertGreaterThan(try ski(wind: 60).score.value, try ski(wind: 60.001).score.value)

        XCTAssertFalse(try ski(sunshine: 14_399).reasons.contains(.skiSunshine))
        XCTAssertTrue(try ski(sunshine: 14_400).reasons.contains(.skiSunshine))
        XCTAssertTrue(try ski(sunshine: 14_401).reasons.contains(.skiSunshine))

        XCTAssertTrue(try ski(maxTemp: -20.001).reasons.contains(.freezeMax))
        XCTAssertFalse(try ski(maxTemp: -20).reasons.contains(.freezeMax))
        XCTAssertFalse(try ski(maxTemp: -12.001).reasons.contains(.freezeMax))
        XCTAssertTrue(try ski(maxTemp: -12).reasons.contains(.freezeMax))
        XCTAssertEqual(try ski(maxTemp: -12).score.value, try ski(maxTemp: 1).score.value)
        XCTAssertGreaterThan(try ski(maxTemp: 1).score.value, try ski(maxTemp: 1.001).score.value)
        XCTAssertEqual(try ski(maxTemp: 1.001).score.value, try ski(maxTemp: 4).score.value)
        XCTAssertGreaterThan(try ski(maxTemp: 4).score.value, try ski(maxTemp: 4.001).score.value)
        XCTAssertEqual(try ski(maxTemp: 4.001).score.value, try ski(maxTemp: 8).score.value)
        XCTAssertGreaterThan(try ski(maxTemp: 8).score.value, try ski(maxTemp: 8.001).score.value)
    }

    func testSurfingWindRainAirTempAndSkyBands() throws {
        XCTAssertTrue(try surf(wind: 7.999).reasons.contains(.windProxy))
        XCTAssertTrue(try surf(wind: 8).reasons.contains(.windProxy))
        XCTAssertGreaterThan(try surf(wind: 12).score.value, try surf(wind: 11.999).score.value)
        XCTAssertEqual(try surf(wind: 12).score.value, try surf(wind: 28).score.value)
        XCTAssertGreaterThan(try surf(wind: 28).score.value, try surf(wind: 28.001).score.value)
        XCTAssertEqual(try surf(wind: 28.001).score.value, try surf(wind: 40).score.value)
        XCTAssertGreaterThan(try surf(wind: 40).score.value, try surf(wind: 40.001).score.value)
        XCTAssertEqual(try surf(wind: 40.001).score.value, try surf(wind: 55).score.value)
        XCTAssertGreaterThan(try surf(wind: 55).score.value, try surf(wind: 55.001).score.value)

        XCTAssertFalse(try surf(rain: 2).reasons.contains(.surfRain))
        XCTAssertTrue(try surf(rain: 2.001).reasons.contains(.surfRain))
        XCTAssertGreaterThan(try surf(rain: 10).score.value, try surf(rain: 10.001).score.value)
        XCTAssertGreaterThan(try surf(rain: 25).score.value, try surf(rain: 25.001).score.value)

        XCTAssertTrue(try surf(weather: 0).reasons.contains(.fairSky))
        XCTAssertTrue(try surf(weather: 1).reasons.contains(.fairSky))
        XCTAssertTrue(try surf(weather: 2).reasons.contains(.fairSky))
        XCTAssertTrue(try surf(weather: 3).reasons.contains(.fairSky))
        XCTAssertGreaterThan(try surf(weather: 2).score.value, try surf(weather: 3).score.value)
        XCTAssertFalse(try surf(weather: 4).reasons.contains(.fairSky))
        XCTAssertTrue(try surf(weather: 82).reasons.contains(.violentRain))
        XCTAssertTrue(try surf(weather: 56).reasons.contains(.freezingDrizzlePenalty))

        XCTAssertTrue(try surf(maxTemp: 11.999).reasons.contains(.airTempComfort))
        XCTAssertFalse(try surf(maxTemp: 12).reasons.contains(.airTempComfort))
        XCTAssertFalse(try surf(maxTemp: 13.999).reasons.contains(.airTempComfort))
        XCTAssertTrue(try surf(maxTemp: 14).reasons.contains(.airTempComfort))
        XCTAssertGreaterThan(try surf(maxTemp: 18).score.value, try surf(maxTemp: 17.999).score.value)
        XCTAssertEqual(try surf(maxTemp: 18).score.value, try surf(maxTemp: 28).score.value)
        XCTAssertGreaterThan(try surf(maxTemp: 28).score.value, try surf(maxTemp: 28.001).score.value)
        XCTAssertEqual(try surf(maxTemp: 28.001).score.value, try surf(maxTemp: 32).score.value)
        XCTAssertGreaterThan(try surf(maxTemp: 32).score.value, try surf(maxTemp: 32.001).score.value)

        XCTAssertFalse(try surf(snow: 0).reasons.contains(.snowAtCoast))
        XCTAssertTrue(try surf(snow: 0.001).reasons.contains(.snowAtCoast))
    }

    func testOutdoorComfortDrySunUVWindAndWalkPenalties() throws {
        XCTAssertGreaterThan(try outdoor(apparent: 12).score.value, try outdoor(apparent: 11.999).score.value)
        XCTAssertEqual(try outdoor(apparent: 12).score.value, try outdoor(apparent: 24).score.value)
        XCTAssertGreaterThan(try outdoor(apparent: 24).score.value, try outdoor(apparent: 24.001).score.value)
        XCTAssertEqual(try outdoor(apparent: 8).score.value, try outdoor(apparent: 24.001).score.value)
        XCTAssertGreaterThan(try outdoor(apparent: 8).score.value, try outdoor(apparent: 7.999).score.value)
        XCTAssertEqual(try outdoor(apparent: 4).score.value, try outdoor(apparent: 28.001).score.value)
        XCTAssertGreaterThan(try outdoor(apparent: 4).score.value, try outdoor(apparent: 3.999).score.value)
        XCTAssertEqual(try outdoor(apparent: 3.999).score.value, try outdoor(apparent: 32.001).score.value)

        XCTAssertGreaterThan(try outdoor(precip: 0).score.value, try outdoor(precip: 0.001).score.value)
        XCTAssertEqual(try outdoor(precip: 0.001).score.value, try outdoor(precip: 2).score.value)
        XCTAssertGreaterThan(try outdoor(precip: 2).score.value, try outdoor(precip: 2.001).score.value)
        XCTAssertEqual(try outdoor(precip: 2.001).score.value, try outdoor(precip: 8).score.value)
        XCTAssertGreaterThan(try outdoor(precip: 8).score.value, try outdoor(precip: 8.001).score.value)
        XCTAssertEqual(try outdoor(precip: 8.001).score.value, try outdoor(precip: 20).score.value)
        XCTAssertGreaterThan(try outdoor(precip: 20).score.value, try outdoor(precip: 20.001).score.value)

        let daylight = 10_000.0
        XCTAssertTrue(try outdoor(sunshine: 1_199, daylight: daylight).reasons.contains(.sunRatio))
        XCTAssertFalse(try outdoor(sunshine: 1_200, daylight: daylight).reasons.contains(.sunRatio))
        XCTAssertTrue(try outdoor(sunshine: 3_000, daylight: daylight).reasons.contains(.sunRatio))
        XCTAssertGreaterThan(
            try outdoor(sunshine: 5_500, daylight: daylight).score.value,
            try outdoor(sunshine: 5_499, daylight: daylight).score.value
        )

        XCTAssertFalse(try outdoor(uv: 2.999).reasons.contains(.uv))
        XCTAssertTrue(try outdoor(uv: 3).reasons.contains(.uv))
        XCTAssertTrue(try outdoor(uv: 7).reasons.contains(.uv))
        XCTAssertFalse(try outdoor(uv: 7.001).reasons.contains(.uv))
        XCTAssertTrue(try outdoor(uv: 11).reasons.contains(.uv))
        XCTAssertLessThan(try outdoor(uv: 11).score.value, try outdoor(uv: 10.999).score.value)

        XCTAssertFalse(try outdoor(gusts: 49.999).reasons.contains(.outdoorWind))
        XCTAssertTrue(try outdoor(gusts: 50).reasons.contains(.outdoorWind))
        XCTAssertGreaterThan(try outdoor(gusts: 69.999).score.value, try outdoor(gusts: 70).score.value)

        XCTAssertTrue(try outdoor(weather: 45).reasons.contains(.fog))
        XCTAssertTrue(try outdoor(weather: 48).reasons.contains(.fog))
        XCTAssertTrue(try outdoor(weather: 75).reasons.contains(.heavySnowWalk))
        XCTAssertTrue(try outdoor(weather: 86).reasons.contains(.heavySnowWalk))
        XCTAssertTrue(try outdoor(weather: 82).reasons.contains(.violentRain))
        XCTAssertTrue(try outdoor(weather: 56).reasons.contains(.freezingDrizzlePenalty))
    }

    func testIndoorWetHoursTempFogOvercastAndBeautifulOutdoorBands() throws {
        XCTAssertFalse(try indoor(precip: 2.999).reasons.contains(.wetDay))
        XCTAssertTrue(try indoor(precip: 3).reasons.contains(.wetDay))
        XCTAssertGreaterThan(try indoor(precip: 8).score.value, try indoor(precip: 7.999).score.value)

        XCTAssertFalse(try indoor(hours: 5.999).reasons.contains(.longPrecip))
        XCTAssertTrue(try indoor(hours: 6).reasons.contains(.longPrecip))
        XCTAssertTrue(try indoor(hours: 6.001).reasons.contains(.longPrecip))

        XCTAssertTrue(try indoor(weather: 51).reasons.contains(.rainCodes))
        XCTAssertFalse(try indoor(weather: 50).reasons.contains(.rainCodes))

        XCTAssertTrue(try indoor(apparent: 4.999).reasons.contains(.tempExtreme))
        XCTAssertFalse(try indoor(apparent: 5).reasons.contains(.tempExtreme))
        XCTAssertFalse(try indoor(apparent: 32).reasons.contains(.tempExtreme))
        XCTAssertTrue(try indoor(apparent: 32.001).reasons.contains(.tempExtreme))

        XCTAssertTrue(try indoor(weather: 45).reasons.contains(.fog))
        XCTAssertTrue(try indoor(weather: 3).reasons.contains(.overcast))
        XCTAssertTrue(try indoor(weather: 95, precip: 0).reasons.contains(.stayInside))

        XCTAssertFalse(
            try indoor(
                apparent: 20,
                precip: 0,
                sunshine: 4_999,
                daylight: 10_000
            ).reasons.contains(.beautifulOutdoor)
        )
        XCTAssertTrue(
            try indoor(
                apparent: 16,
                precip: 0,
                sunshine: 5_000,
                daylight: 10_000
            ).reasons.contains(.beautifulOutdoor)
        )
        XCTAssertTrue(
            try indoor(
                apparent: 26,
                precip: 0,
                sunshine: 5_000,
                daylight: 10_000
            ).reasons.contains(.beautifulOutdoor)
        )
        XCTAssertFalse(
            try indoor(
                apparent: 26.001,
                precip: 0,
                sunshine: 5_000,
                daylight: 10_000
            ).reasons.contains(.beautifulOutdoor)
        )
        XCTAssertFalse(
            try indoor(
                apparent: 20,
                precip: 0.001,
                sunshine: 5_000,
                daylight: 10_000
            ).reasons.contains(.beautifulOutdoor)
        )
    }

    private func ski(
        weather: Int = 0,
        maxTemp: Double = -15,
        rain: Double = 0,
        snow: Double = 0,
        wind: Double = 20,
        gusts: Double = 25,
        sunshine: Double = 0
    ) throws -> DailyActivitySuitability {
        engine.suitability(
            for: try ScoringFixture.day(
                weatherCode: weather,
                maximumTemperatureCelsius: maxTemp,
                rainMillimetres: rain,
                snowfallCentimetres: snow,
                maximumWindSpeedKilometresPerHour: wind,
                maximumWindGustKilometresPerHour: gusts,
                sunshineDurationSeconds: sunshine
            ),
            activity: .skiing
        )
    }

    private func surf(
        weather: Int = 61,
        maxTemp: Double = 13,
        rain: Double = 0,
        snow: Double = 0,
        wind: Double = 20
    ) throws -> DailyActivitySuitability {
        engine.suitability(
            for: try ScoringFixture.day(
                weatherCode: weather,
                maximumTemperatureCelsius: maxTemp,
                rainMillimetres: rain,
                snowfallCentimetres: snow,
                maximumWindSpeedKilometresPerHour: wind,
                maximumWindGustKilometresPerHour: min(wind + 5, 89)
            ),
            activity: .surfing
        )
    }

    private func outdoor(
        weather: Int = 61,
        apparent: Double = 18,
        precip: Double = 0,
        gusts: Double = 20,
        sunshine: Double = 8_000,
        daylight: Double = 40_000,
        uv: Double = 1
    ) throws -> DailyActivitySuitability {
        engine.suitability(
            for: try ScoringFixture.day(
                weatherCode: weather,
                maximumApparentTemperatureCelsius: apparent,
                precipitationMillimetres: precip,
                maximumWindGustKilometresPerHour: gusts,
                sunshineDurationSeconds: sunshine,
                daylightDurationSeconds: daylight,
                maximumUVIndex: uv
            ),
            activity: .outdoorSightseeing
        )
    }

    private func indoor(
        weather: Int = 0,
        apparent: Double = 12,
        precip: Double = 0,
        hours: Double = 0,
        gusts: Double = 25,
        sunshine: Double = 2_000,
        daylight: Double = 40_000
    ) throws -> DailyActivitySuitability {
        engine.suitability(
            for: try ScoringFixture.day(
                weatherCode: weather,
                maximumApparentTemperatureCelsius: apparent,
                precipitationMillimetres: precip,
                precipitationHours: hours,
                maximumWindGustKilometresPerHour: gusts,
                sunshineDurationSeconds: sunshine,
                daylightDurationSeconds: daylight
            ),
            activity: .indoorSightseeing
        )
    }
}
