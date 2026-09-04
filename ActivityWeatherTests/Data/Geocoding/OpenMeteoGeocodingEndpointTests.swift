import XCTest
@testable import ActivityWeather

final class OpenMeteoGeocodingEndpointTests: XCTestCase {
    func testSearchUsesHTTPSPathAndExplicitQueryItems() throws {
        let endpoint = OpenMeteoGeocodingEndpoint.search(name: "Berlin")
        let components = try XCTUnwrap(URLComponents(url: try endpoint.url(), resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "geocoding-api.open-meteo.com")
        XCTAssertEqual(components.path, "/v1/search")
        XCTAssertEqual(queryValue("name", in: components), "Berlin")
        XCTAssertEqual(queryValue("count", in: components), "10")
        XCTAssertEqual(queryValue("language", in: components), "en")
        XCTAssertEqual(queryValue("format", in: components), "json")
        XCTAssertNil(queryValue("countryCode", in: components))
    }

    func testSearchPercentEncodesSpacesReservedCharactersAndUnicode() throws {
        let endpoint = OpenMeteoGeocodingEndpoint.search(name: "Zürich a&b 東京")
        let url = try endpoint.url()
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertEqual(queryValue("name", in: components), "Zürich a&b 東京")
        XCTAssertTrue(url.absoluteString.contains("%20"))
        XCTAssertTrue(url.absoluteString.contains("%26"))
    }

    private func queryValue(_ name: String, in components: URLComponents) -> String? {
        components.queryItems?.first(where: { $0.name == name })?.value
    }
}
