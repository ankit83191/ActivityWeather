import XCTest
@testable import ActivityWeather

final class SuitabilityScoringEngineTests: XCTestCase {
    private let engine = SuitabilityScoringEngine()

    func testSkiWorkedExampleScores77() throws {
        let day = try ScoringFixture.day(
            weatherCode: 71,
            maximumTemperatureCelsius: 3,
            rainMillimetres: 0,
            snowfallCentimetres: 4,
            maximumWindSpeedKilometresPerHour: 30,
            maximumWindGustKilometresPerHour: 40,
            sunshineDurationSeconds: 7_200
        )

        let result = engine.suitability(for: day, activity: .skiing)

        XCTAssertEqual(result.score.value, 77)
        XCTAssertEqual(result.activity, .skiing)
        XCTAssertEqual(result.date, day.date)
        XCTAssertEqual(result.reasons, [.snowWeather, .snowfallAmount, .freezeMax])
    }

    func testSurfWorkedExampleScores90() throws {
        let day = try ScoringFixture.day(
            weatherCode: 1,
            maximumTemperatureCelsius: 22,
            rainMillimetres: 1,
            snowfallCentimetres: 0,
            maximumWindSpeedKilometresPerHour: 20,
            maximumWindGustKilometresPerHour: 28
        )

        let result = engine.suitability(for: day, activity: .surfing)

        XCTAssertEqual(result.score.value, 90)
        XCTAssertEqual(result.reasons, [.windProxy, .airTempComfort, .fairSky])
    }

    func testOutdoorWorkedExampleScores68() throws {
        let day = try ScoringFixture.day(
            weatherCode: 61,
            maximumApparentTemperatureCelsius: 18,
            precipitationMillimetres: 3,
            maximumWindGustKilometresPerHour: 20,
            sunshineDurationSeconds: 12_000,
            daylightDurationSeconds: 40_000,
            maximumUVIndex: 5
        )

        let result = engine.suitability(for: day, activity: .outdoorSightseeing)

        XCTAssertEqual(result.score.value, 68)
        XCTAssertEqual(result.reasons, [.comfortTemp, .dry, .sunRatio, .uv])
    }

    func testIndoorOrdinaryRainWorkedExampleScores82() throws {
        let day = try ScoringFixture.day(
            weatherCode: 63,
            maximumApparentTemperatureCelsius: 12,
            precipitationMillimetres: 12,
            precipitationHours: 7,
            maximumWindGustKilometresPerHour: 25,
            sunshineDurationSeconds: 2_000
        )

        let result = engine.suitability(for: day, activity: .indoorSightseeing)

        XCTAssertEqual(result.score.value, 82)
        XCTAssertEqual(result.reasons, [.wetDay, .longPrecip, .rainCodes])
        XCTAssertFalse(result.reasons.contains(.dangerousTravelCap))
    }

    func testIndoorThunderstormCapsAt40WithLeadingTravelReason() throws {
        let day = try ScoringFixture.day(
            weatherCode: 95,
            maximumApparentTemperatureCelsius: 20,
            precipitationMillimetres: 15,
            precipitationHours: 4,
            maximumWindGustKilometresPerHour: 40
        )

        let result = engine.suitability(for: day, activity: .indoorSightseeing)

        XCTAssertEqual(result.score.value, 40)
        XCTAssertEqual(result.reasons.first, .dangerousTravelCap)
        XCTAssertEqual(result.reasons, [.dangerousTravelCap, .wetDay, .stayInside])
        XCTAssertNotEqual(result.score.value, 0)
    }

    func testOutdoorVetoSkipsAdditiveSkiingRules() throws {
        let day = try ScoringFixture.day(
            weatherCode: 95,
            maximumTemperatureCelsius: -5,
            snowfallCentimetres: 10,
            maximumWindSpeedKilometresPerHour: 20
        )

        let result = engine.suitability(for: day, activity: .skiing)

        XCTAssertEqual(result.score.value, 0)
        XCTAssertEqual(result.reasons, [.criticalThunderstorm])
    }

    func testIndoorNeverAppliesOutdoorVeto() throws {
        let storm = try ScoringFixture.day(weatherCode: 95, precipitationMillimetres: 15)
        let outdoor = engine.suitability(for: storm, activity: .outdoorSightseeing)
        let indoor = engine.suitability(for: storm, activity: .indoorSightseeing)

        XCTAssertEqual(outdoor.score.value, 0)
        XCTAssertEqual(outdoor.reasons, [.criticalThunderstorm])
        XCTAssertGreaterThan(indoor.score.value, 0)
        XCTAssertFalse(indoor.reasons.contains(.criticalThunderstorm))
    }

    func testIndoorCapIsNotEmittedWhenRawAlreadyAtOrBelow40() throws {
        let day = try ScoringFixture.day(
            weatherCode: 56,
            maximumApparentTemperatureCelsius: 20,
            precipitationMillimetres: 0,
            sunshineDurationSeconds: 20_000,
            daylightDurationSeconds: 40_000
        )

        let result = engine.suitability(for: day, activity: .indoorSightseeing)

        XCTAssertLessThanOrEqual(result.score.value, 40)
        XCTAssertFalse(result.reasons.contains(.dangerousTravelCap))
        XCTAssertTrue(result.reasons.contains(.beautifulOutdoor))
    }

    func testVetoPriorityIsThunderstormThenFreezingRainThenExtremeGust() throws {
        let thunderAndGust = try ScoringFixture.day(
            weatherCode: 95,
            maximumWindGustKilometresPerHour: 90
        )
        let freezeAndGust = try ScoringFixture.day(
            weatherCode: 66,
            maximumWindGustKilometresPerHour: 90
        )
        let gustOnly = try ScoringFixture.day(
            weatherCode: 0,
            maximumWindGustKilometresPerHour: 90
        )

        XCTAssertEqual(
            engine.suitability(for: thunderAndGust, activity: .surfing).reasons,
            [.criticalThunderstorm]
        )
        XCTAssertEqual(
            engine.suitability(for: freezeAndGust, activity: .surfing).reasons,
            [.criticalFreezingRain]
        )
        XCTAssertEqual(
            engine.suitability(for: gustOnly, activity: .surfing).reasons,
            [.criticalExtremeWind]
        )
    }

    func testEqualMagnitudeReasonsOrderByRawValue() throws {
        let day = try ScoringFixture.day(
            weatherCode: 0,
            maximumTemperatureCelsius: 0,
            rainMillimetres: 2,
            snowfallCentimetres: 0,
            maximumWindSpeedKilometresPerHour: 20
        )

        let reasons = engine.suitability(for: day, activity: .skiing).reasons

        XCTAssertEqual(reasons, [.freezeMax, .rainOnSnow])
        XCTAssertLessThan(
            SuitabilityReason.freezeMax.rawValue,
            SuitabilityReason.rainOnSnow.rawValue
        )
    }

    func testZeroDaylightProducesDeterministicOutdoorScore() throws {
        let polarNight = try ScoringFixture.day(
            weatherCode: 61,
            maximumApparentTemperatureCelsius: 18,
            precipitationMillimetres: 0,
            sunshineDurationSeconds: 0,
            daylightDurationSeconds: 0,
            maximumUVIndex: 1
        )

        let first = engine.suitability(for: polarNight, activity: .outdoorSightseeing)
        let second = engine.suitability(for: polarNight, activity: .outdoorSightseeing)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.score.value, 76)
        XCTAssertTrue(first.reasons.contains(.sunRatio))
    }

    func testScoreClampsToInclusiveBounds() throws {
        let tooLow = try ScoringFixture.day(
            weatherCode: 0,
            maximumTemperatureCelsius: 20,
            rainMillimetres: 5,
            snowfallCentimetres: 0,
            maximumWindSpeedKilometresPerHour: 70
        )
        let tooHigh = try ScoringFixture.day(
            weatherCode: 71,
            maximumTemperatureCelsius: -5,
            rainMillimetres: 0,
            snowfallCentimetres: 20,
            maximumWindSpeedKilometresPerHour: 10,
            sunshineDurationSeconds: 20_000
        )

        XCTAssertEqual(engine.suitability(for: tooLow, activity: .skiing).score.value, 0)
        XCTAssertEqual(engine.suitability(for: tooHigh, activity: .skiing).score.value, 100)
    }

    func testSkiingWarmRainAndGustVetoCombination() throws {
        let warmRain = try ScoringFixture.day(
            weatherCode: 71,
            maximumTemperatureCelsius: 10,
            rainMillimetres: 3,
            snowfallCentimetres: 4,
            maximumWindSpeedKilometresPerHour: 30
        )
        let gustVeto = try ScoringFixture.day(
            weatherCode: 71,
            snowfallCentimetres: 4,
            maximumWindGustKilometresPerHour: 90
        )

        let rainResult = engine.suitability(for: warmRain, activity: .skiing)
        XCTAssertEqual(rainResult.score.value, 29)
        XCTAssertTrue(rainResult.reasons.contains(.rainOnSnow))
        XCTAssertTrue(rainResult.reasons.contains(.freezeMax))

        let veto = engine.suitability(for: gustVeto, activity: .skiing)
        XCTAssertEqual(veto.score.value, 0)
        XCTAssertEqual(veto.reasons, [.criticalExtremeWind])
    }

    func testSurfingComfortStormAndWindProxy() throws {
        let comfortable = try ScoringFixture.day(
            weatherCode: 1,
            maximumTemperatureCelsius: 22,
            rainMillimetres: 0,
            maximumWindSpeedKilometresPerHour: 20
        )
        let storm = try ScoringFixture.day(weatherCode: 99, maximumWindSpeedKilometresPerHour: 20)
        let severeWind = try ScoringFixture.day(
            weatherCode: 1,
            maximumTemperatureCelsius: 22,
            maximumWindSpeedKilometresPerHour: 56,
            maximumWindGustKilometresPerHour: 60
        )

        XCTAssertEqual(engine.suitability(for: comfortable, activity: .surfing).score.value, 90)
        XCTAssertEqual(engine.suitability(for: storm, activity: .surfing).score.value, 0)
        XCTAssertTrue(
            engine.suitability(for: severeWind, activity: .surfing).reasons.contains(.windProxy)
        )
    }

    func testOutdoorMildVersusIndoorWetTravelCap() throws {
        let mildOutdoor = try ScoringFixture.day(
            weatherCode: 0,
            maximumApparentTemperatureCelsius: 18,
            precipitationMillimetres: 0,
            sunshineDurationSeconds: 22_000,
            daylightDurationSeconds: 40_000,
            maximumUVIndex: 5
        )
        let wetTravel = try ScoringFixture.day(
            weatherCode: 82,
            maximumApparentTemperatureCelsius: 12,
            precipitationMillimetres: 12,
            precipitationHours: 7
        )

        let outdoor = engine.suitability(for: mildOutdoor, activity: .outdoorSightseeing)
        let indoor = engine.suitability(for: wetTravel, activity: .indoorSightseeing)

        XCTAssertGreaterThanOrEqual(outdoor.score.value, 75)
        XCTAssertEqual(indoor.score.value, 40)
        XCTAssertEqual(indoor.reasons.first, .dangerousTravelCap)
    }

    func testScoringIsDeterministicForTheSameInputs() throws {
        let day = try ScoringFixture.day(weatherCode: 71, snowfallCentimetres: 4)

        XCTAssertEqual(
            engine.suitability(for: day, activity: .skiing),
            engine.suitability(for: day, activity: .skiing)
        )
    }
}
