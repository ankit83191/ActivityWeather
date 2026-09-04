import XCTest
@testable import ActivityWeather

final class GeocodingLocationMapperTests: XCTestCase {
    func testMissingResultsKeyMapsToEmptyList() throws {
        let dto = try GeocodingFixture.decodeResponse(named: "geocoding_missing_results")
        XCTAssertEqual(try GeocodingLocationMapper.locations(from: dto), [])
    }

    func testEmptyResultsArrayMapsToEmptyList() throws {
        let dto = try GeocodingFixture.decodeResponse(named: "geocoding_empty_results")
        XCTAssertEqual(try GeocodingLocationMapper.locations(from: dto), [])
    }

    func testPreservesMultipleAmbiguousMatchesInAPIOrder() throws {
        let locations = try GeocodingLocationMapper.locations(
            from: GeocodingFixture.decodeResponse(named: "geocoding_success_ambiguous")
        )

        XCTAssertEqual(locations.map(\.id), [2950159, 5083330])
        XCTAssertEqual(locations[0].displayName, "Berlin")
        XCTAssertEqual(locations[0].region, "State of Berlin")
        XCTAssertEqual(locations[0].country, "Germany")
        XCTAssertEqual(locations[0].coordinate.latitude, 52.52437)
        XCTAssertEqual(locations[0].coordinate.longitude, 13.41053)
        XCTAssertEqual(locations[0].elevationMetres, 74)
        XCTAssertEqual(locations[0].geocodingTimeZoneIdentifier, "Europe/Berlin")
        XCTAssertEqual(locations[1].region, "New Hampshire")
        XCTAssertEqual(locations[1].country, "United States")
    }

    func testReturnsValidRecordsAndSkipsInvalidOnes() throws {
        let locations = try GeocodingLocationMapper.locations(
            from: GeocodingFixture.decodeResponse(named: "geocoding_mixed")
        )

        XCTAssertEqual(locations.map(\.id), [2950159])
        XCTAssertEqual(locations[0].displayName, "Berlin")
    }

    func testThrowsWhenEveryRecordIsInvalid() throws {
        let dto = try GeocodingFixture.decodeResponse(named: "geocoding_all_invalid")
        XCTAssertThrowsError(try GeocodingLocationMapper.locations(from: dto)) { error in
            XCTAssertEqual(error as? GeocodingError, .noValidLocations)
        }
    }

    func testBlankRequiredNameOrCountryIsInvalid() throws {
        let dto = try GeocodingFixture.decodeResponse(named: "geocoding_blank_required")
        XCTAssertThrowsError(try GeocodingLocationMapper.locations(from: dto)) { error in
            XCTAssertEqual(error as? GeocodingError, .noValidLocations)
        }
    }

    func testTrimsTextAndTreatsBlankOptionalMetadataAsNil() throws {
        let locations = try GeocodingLocationMapper.locations(
            from: GeocodingFixture.decodeResponse(named: "geocoding_blank_optional")
        )

        XCTAssertEqual(locations.count, 1)
        XCTAssertEqual(locations[0].id, 2950159)
        XCTAssertEqual(locations[0].displayName, "Berlin")
        XCTAssertNil(locations[0].region)
        XCTAssertEqual(locations[0].country, "Germany")
        XCTAssertNil(locations[0].geocodingTimeZoneIdentifier)
    }

    func testInvalidCoordinatesMakeTheRecordInvalid() throws {
        let dto = try GeocodingFixture.decodeResponse(named: "geocoding_invalid_coordinates")
        XCTAssertThrowsError(try GeocodingLocationMapper.locations(from: dto)) { error in
            XCTAssertEqual(error as? GeocodingError, .noValidLocations)
        }
    }

    func testWrongJSONTypesFailDecoding() {
        XCTAssertThrowsError(
            try GeocodingFixture.decodeResponse(named: "geocoding_wrong_types")
        )
    }
}
