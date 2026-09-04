# AI usage

AI is a **reviewed assistant**, not an authority. Generated suggestions are compiled, tested, and checked against official Apple documentation (and this repository’s recorded decisions) before they are accepted. Rejected or materially changed suggestions are logged here.

## Policy

- Prefer Apple platform documentation over training-data defaults when they disagree.
- Do not add third-party packages, secrets, or generated build output because an assistant suggested them.
- Behavioural code follows Red-Green-Refactor; scaffold and documentation milestones are verified by build/test, not by dummy assertions.
- The human reviewer accepts or rejects each milestone commit.

## Milestone 1

**Accepted (after review and local verification):**

- Hand-authored `ActivityWeather.xcodeproj` (no SPM, no CocoaPods, no XcodeGen).
- Swift **6 language mode** (`SWIFT_VERSION = 6.0`) chosen from the inspected toolchain (Xcode 26.2 / Swift 6.2.3) rather than leaving the setting blank.
- Display name “Activity Weather” vs module/target `ActivityWeather`.
- Empty UI test target retained as Xcode convention, documented as unused until milestone 11.
- Project-local `-derivedDataPath .derivedData` for command-line verification.

**Rejected / not used:**

- Dummy unit tests such as `XCTAssertTrue(true)` to force a non-zero test count.
- Pre-creating Domain/Data/Features placeholder types or empty groups “for later.”
- Swift Package Manager or third-party project generators.
- Combine/`ObservableObject` samples in the placeholder app.
- Setting or changing Git `user.name` / `user.email`.

**Documentation check:** Swift 6 language mode and Observation (`@Observable`) align with current Apple guidance for new SwiftUI apps; TCA was not introduced (third-party, out of scope).
