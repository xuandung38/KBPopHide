@testable import KSAPDismiss
import XCTest

final class LanguageManagerTests: XCTestCase {
    // Testing logic of enum
    func testAppLanguageEnum() {
        XCTAssertEqual(AppLanguage.english.rawValue, "en")
        XCTAssertEqual(AppLanguage.vietnamese.rawValue, "vi")
        XCTAssertEqual(AppLanguage.system.rawValue, "system")

        XCTAssertEqual(AppLanguage.english.displayName, "English")
        XCTAssertEqual(AppLanguage.vietnamese.displayName, "Tiếng Việt")
    }
}
