import XCTest

@MainActor
final class ActivityWeatherUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchAndMinimumQueryAccessibilityJourney() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.navigationBars["Find a location"].waitForExistence(timeout: 5)
        )

        let searchField = app.textFields["location-search-field"]
        XCTAssertTrue(searchField.exists)
        XCTAssertTrue(searchField.isHittable)
        XCTAssertEqual(
            searchField.label,
            "Search for a city or place"
        )

        searchField.tap()
        searchField.typeText("P")

        XCTAssertTrue(
            app.staticTexts["Enter at least 2 characters"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertFalse(app.activityIndicators["location-search-loading"].exists)
        XCTAssertFalse(
            app.descendants(matching: .any)["location-search-results"].exists
        )
    }
}
