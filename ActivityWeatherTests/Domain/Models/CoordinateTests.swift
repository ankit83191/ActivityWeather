import XCTest
@testable import ActivityWeather

final class CoordinateTests: XCTestCase {
    func testAcceptsBoundaryCoordinates() throws {
        XCTAssertEqual(try Coordinate(latitude: -90, longitude: -180).latitude, -90)
        XCTAssertEqual(try Coordinate(latitude: 90, longitude: 180).longitude, 180)
    }

    func testRejectsOutOfRangeAndNonFiniteCoordinates() {
        XCTAssertThrowsError(try Coordinate(latitude: -90.1, longitude: 0))
        XCTAssertThrowsError(try Coordinate(latitude: 0, longitude: 180.1))
        XCTAssertThrowsError(try Coordinate(latitude: .nan, longitude: 0))
        XCTAssertThrowsError(try Coordinate(latitude: 0, longitude: .infinity))
    }
}
