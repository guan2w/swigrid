import XCTest

final class SchulteGridUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCoreFlowSavesRecord() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        configureHome(app: app, playerName: "UITester", gridLabel: "5x5", dualOn: false)

        let startButton = app.buttons["home.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let nextButton = app.buttons["game.next"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForEnabled(nextButton, timeout: 6), "Game did not start in time")

        for number in 1 ... 25 {
            XCTAssertTrue(tapCell(number: number, in: app), "Missing tappable cell \(number)")
        }

        let resultAlert = app.alerts["Round Complete"]
        XCTAssertTrue(resultAlert.waitForExistence(timeout: 5), "Result alert did not appear")

        let okButton = resultAlert.buttons["OK"]
        XCTAssertTrue(okButton.waitForExistence(timeout: 2))
        okButton.tap()

        let recordsButton = app.buttons["home.records"]
        XCTAssertTrue(recordsButton.waitForExistence(timeout: 5))
        recordsButton.tap()

        let recordsList = app.collectionViews["records.list"].firstMatch
        XCTAssertTrue(recordsList.waitForExistence(timeout: 5))
        XCTAssertTrue(recordsList.cells.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(recordsList.staticTexts["UITester"].firstMatch.exists)
    }

    @MainActor
    func testMutePersistsAfterRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let muteSwitch = app.switches["home.audio.mute"]
        XCTAssertTrue(muteSwitch.waitForExistence(timeout: 5))

        let initialOn = isSwitchOn(muteSwitch)
        muteSwitch.tap()
        let toggledOn = isSwitchOn(muteSwitch)
        XCTAssertNotEqual(initialOn, toggledOn)

        app.terminate()
        app.launch()

        let relaunchedMuteSwitch = app.switches["home.audio.mute"]
        XCTAssertTrue(relaunchedMuteSwitch.waitForExistence(timeout: 5))
        XCTAssertEqual(isSwitchOn(relaunchedMuteSwitch), toggledOn)
    }

    @MainActor
    private func configureHome(app: XCUIApplication, playerName: String, gridLabel: String, dualOn: Bool) {
        let playerField = app.textFields["home.player.textfield"]
        XCTAssertTrue(playerField.waitForExistence(timeout: 5))
        playerField.tap()
        clearCurrentText(in: playerField)
        playerField.typeText(playerName)

        let savePlayerButton = app.buttons["home.player.save"]
        if savePlayerButton.exists {
            savePlayerButton.tap()
        }

        let dualSwitch = app.switches["home.grid.dual"]
        if dualSwitch.waitForExistence(timeout: 2) {
            setSwitch(dualSwitch, to: dualOn)
        }

        let scaleButton = app.buttons[gridLabel]
        if scaleButton.exists {
            scaleButton.tap()
        }
    }

    @MainActor
    private func tapCell(number: Int, in app: XCUIApplication) -> Bool {
        let target = String(number)
        let deadline = Date().addingTimeInterval(2.5)

        while Date() < deadline {
            let cells = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "game.cell."))
            for index in 0 ..< cells.count {
                let cell = cells.element(boundBy: index)
                if cell.label == target && cell.isHittable {
                    cell.tap()
                    return true
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        return false
    }

    @MainActor
    private func waitForEnabled(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "enabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func setSwitch(_ element: XCUIElement, to expectedOn: Bool) {
        if isSwitchOn(element) != expectedOn {
            element.tap()
        }
    }

    @MainActor
    private func isSwitchOn(_ element: XCUIElement) -> Bool {
        let raw = String(describing: element.value ?? "")
        switch raw.lowercased() {
        case "1", "on", "true":
            return true
        default:
            return false
        }
    }

    @MainActor
    private func clearCurrentText(in field: XCUIElement) {
        guard let current = field.value as? String,
            !current.isEmpty,
            current != "Enter your name"
        else {
            return
        }

        let deleteText = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)
        field.typeText(deleteText)
    }
}
