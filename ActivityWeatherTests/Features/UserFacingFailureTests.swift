import XCTest
@testable import ActivityWeather

final class UserFacingFailureTests: XCTestCase {
    func testMapsEveryRepositoryFailureToPresentationCategory() {
        XCTAssertEqual(
            UserFacingFailure.classify(RepositoryFailure.offline),
            .connection
        )
        XCTAssertEqual(
            UserFacingFailure.classify(RepositoryFailure.serviceUnavailable),
            .service
        )
        XCTAssertEqual(
            UserFacingFailure.classify(RepositoryFailure.invalidData),
            .invalidData
        )
        XCTAssertEqual(
            UserFacingFailure.classify(RepositoryFailure.unknown),
            .generic
        )
    }

    func testClassifiesUnknownErrorsAsGeneric() {
        XCTAssertEqual(
            UserFacingFailure.classify(TestFailure.expected),
            .generic
        )
    }
}

private enum TestFailure: Error {
    case expected
}
