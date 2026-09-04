import XCTest
@testable import ActivityWeather

final class SuitabilityScoreTests: XCTestCase {
    func testRejectsValuesOutsideBoundsWithDomainError() {
        XCTAssertThrowsError(try SuitabilityScore(-1)) {
            XCTAssertEqual($0 as? DomainError, .invalidScore(-1))
        }
        XCTAssertThrowsError(try SuitabilityScore(101)) {
            XCTAssertEqual($0 as? DomainError, .invalidScore(101))
        }
    }
}
