import XCTest
@testable import SchulteDomain

final class PlayerTests: XCTestCase {
    func testNameIsTrimmedAndBoundedToMaxLength() {
        let long = "   12345678901234567890   "
        let player = Player(name: long)
        XCTAssertEqual(player.name, "1234567890123456")
    }

    func testDecodedLegacyNameIsSanitized() throws {
        let data = #"{"name":"  abcdefghijklmnopqrst  "}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Player.self, from: data)
        XCTAssertEqual(decoded.name, "abcdefghijklmnop")
    }
}
