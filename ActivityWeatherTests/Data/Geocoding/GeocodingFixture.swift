import Foundation
import XCTest
@testable import ActivityWeather

enum GeocodingFixture {
    static func data(named name: String, file: StaticString = #filePath, line: UInt = #line) throws -> Data {
        let bundle = Bundle(for: GeocodingFixtureMarker.self)
        let url = try XCTUnwrap(
            bundle.url(forResource: name, withExtension: "json"),
            "Missing test-bundle fixture \(name).json",
            file: file,
            line: line
        )
        return try Data(contentsOf: url)
    }

    static func decodeResponse(named name: String) throws -> GeocodingResponseDTO {
        try JSONDecoder().decode(GeocodingResponseDTO.self, from: data(named: name))
    }
}

private final class GeocodingFixtureMarker {}
