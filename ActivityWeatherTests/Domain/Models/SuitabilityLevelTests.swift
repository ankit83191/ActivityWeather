import XCTest
@testable import ActivityWeather

final class SuitabilityLevelTests: XCTestCase {
    func testDerivesExactInclusiveBoundariesFromScore() throws {
        XCTAssertEqual(try SuitabilityScore(0).level, .poor)
        XCTAssertEqual(try SuitabilityScore(24).level, .poor)
        XCTAssertEqual(try SuitabilityScore(25).level, .fair)
        XCTAssertEqual(try SuitabilityScore(49).level, .fair)
        XCTAssertEqual(try SuitabilityScore(50).level, .good)
        XCTAssertEqual(try SuitabilityScore(74).level, .good)
        XCTAssertEqual(try SuitabilityScore(75).level, .great)
        XCTAssertEqual(try SuitabilityScore(100).level, .great)
    }
}
