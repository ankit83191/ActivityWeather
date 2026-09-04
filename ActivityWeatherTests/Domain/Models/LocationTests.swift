import XCTest
@testable import ActivityWeather

final class LocationTests: XCTestCase {
    func testIdentityDependsOnlyOnGeocodingIdentifier() throws {
        let coordinate = try Coordinate(latitude: 51.5, longitude: -0.1)
        let original = Location(
            id: 42,
            displayName: "London",
            region: "England",
            country: "United Kingdom",
            coordinate: coordinate,
            elevationMetres: 11,
            geocodingTimeZoneIdentifier: "Europe/London"
        )
        let renamed = Location(
            id: 42,
            displayName: "Greater London",
            region: nil,
            country: "UK",
            coordinate: coordinate,
            elevationMetres: nil,
            geocodingTimeZoneIdentifier: nil
        )

        XCTAssertEqual(original, renamed)
        XCTAssertEqual(Set([original, renamed]).count, 1)
    }
}
