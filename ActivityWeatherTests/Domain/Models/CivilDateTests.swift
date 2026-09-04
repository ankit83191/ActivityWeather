import XCTest
@testable import ActivityWeather

final class CivilDateTests: XCTestCase {
    func testValidatesGregorianDatesIncludingLeapYears() throws {
        XCTAssertEqual(try CivilDate(year: 2028, month: 2, day: 29).day, 29)
        XCTAssertThrowsError(try CivilDate(year: 2027, month: 2, day: 29))
        XCTAssertThrowsError(try CivilDate(year: 2026, month: 13, day: 1))
    }

    func testComparesByCalendarComponents() throws {
        let earlier = try CivilDate(year: 2026, month: 12, day: 31)
        let later = try CivilDate(year: 2027, month: 1, day: 1)

        XCTAssertLessThan(earlier, later)
    }

    func testRecognizesOnlyTheNextConsecutiveCivilDay() throws {
        let februaryEnd = try CivilDate(year: 2028, month: 2, day: 29)
        let marchStart = try CivilDate(year: 2028, month: 3, day: 1)
        let marchSecond = try CivilDate(year: 2028, month: 3, day: 2)

        XCTAssertTrue(februaryEnd.isImmediatelyBefore(marchStart))
        XCTAssertFalse(februaryEnd.isImmediatelyBefore(marchSecond))
    }
}
