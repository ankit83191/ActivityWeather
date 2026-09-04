import XCTest
@testable import ActivityWeather

final class OpenMeteoForecastEndpointTests: XCTestCase {
    func testForecastQueryUsesMetricSevenDayAutoTimezoneAndDocumentedDailyFields() throws {
        let endpoint = OpenMeteoForecastEndpoint.forecast(latitude: 52.52, longitude: 13.41)
        let components = try XCTUnwrap(URLComponents(url: try endpoint.url(), resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "api.open-meteo.com")
        XCTAssertEqual(components.path, "/v1/forecast")
        XCTAssertEqual(queryValue("forecast_days", in: components), "7")
        XCTAssertEqual(queryValue("timezone", in: components), "auto")
        XCTAssertEqual(queryValue("temperature_unit", in: components), "celsius")
        XCTAssertEqual(queryValue("wind_speed_unit", in: components), "kmh")
        XCTAssertEqual(queryValue("precipitation_unit", in: components), "mm")

        let daily = try XCTUnwrap(queryValue("daily", in: components))
        let variables = Set(daily.split(separator: ",").map(String.init))
        XCTAssertEqual(variables, Set(OpenMeteoForecastEndpoint.dailyVariables))
        XCTAssertEqual(variables.count, 13)
        XCTAssertFalse(variables.contains("time"))
    }

    func testCoordinatesUsePOSIXDecimalPoint() throws {
        try assertRoundTrip(latitude: 52.52437, longitude: -13.41053)
        try assertRoundTrip(latitude: 13.419998, longitude: 151.2093)
        try assertRoundTrip(latitude: -33.8688, longitude: 139.6503)
    }

    private func assertRoundTrip(latitude: Double, longitude: Double) throws {
        let endpoint = OpenMeteoForecastEndpoint.forecast(latitude: latitude, longitude: longitude)
        let components = try XCTUnwrap(URLComponents(url: try endpoint.url(), resolvingAgainstBaseURL: false))
        let latitudeQuery = try XCTUnwrap(queryValue("latitude", in: components))
        let longitudeQuery = try XCTUnwrap(queryValue("longitude", in: components))

        XCTAssertFalse(latitudeQuery.contains(","))
        XCTAssertFalse(longitudeQuery.contains(","))
        XCTAssertEqual(Double(latitudeQuery), latitude)
        XCTAssertEqual(Double(longitudeQuery), longitude)
        XCTAssertNotEqual(latitudeQuery, String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), latitude))
    }

    private func queryValue(_ name: String, in components: URLComponents) -> String? {
        components.queryItems?.first(where: { $0.name == name })?.value
    }
}
