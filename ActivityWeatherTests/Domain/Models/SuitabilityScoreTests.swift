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

    func testClampingFactoryStaysWithinBoundsWithoutThrowing() {
        XCTAssertEqual(SuitabilityScore(clamping: -8).value, 0)
        XCTAssertEqual(SuitabilityScore(clamping: 0).value, 0)
        XCTAssertEqual(SuitabilityScore(clamping: 77).value, 77)
        XCTAssertEqual(SuitabilityScore(clamping: 100).value, 100)
        XCTAssertEqual(SuitabilityScore(clamping: 140).value, 100)
    }
}
