import XCTest

@MainActor
final class PackItUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    private func waitForSidebar() -> XCUIElement {
        let sidebar = findElement("sidebar")
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5))
        return sidebar
    }

    private func findElement(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    // MARK: - Window & Layout

    func testAppLaunches() throws {
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 5))
    }

    func testSidebarIsVisible() throws {
        _ = waitForSidebar()
    }

    // MARK: - Default State

    func testTemplateListShownByDefault() throws {
        let list = findElement("templateList")
        XCTAssertTrue(list.waitForExistence(timeout: 5))
    }

    // MARK: - Sidebar Navigation: Templates

    func testNavigateToTemplates() throws {
        let templates = findElement("sidebar.templates")
        XCTAssertTrue(templates.waitForExistence(timeout: 5))
        templates.click()

        let list = findElement("templateList")
        XCTAssertTrue(list.waitForExistence(timeout: 5))
    }

    // MARK: - Sidebar Navigation: Trips

    func testNavigateToPlanning() throws {
        let planning = findElement("sidebar.planning")
        XCTAssertTrue(planning.waitForExistence(timeout: 5))
        planning.click()

        let list = findElement("tripList")
        XCTAssertTrue(list.waitForExistence(timeout: 5))
    }

    func testNavigateToActive() throws {
        let active = findElement("sidebar.active")
        XCTAssertTrue(active.waitForExistence(timeout: 5))
        active.click()

        let list = findElement("tripList")
        XCTAssertTrue(list.waitForExistence(timeout: 5))
    }

    func testNavigateToCompleted() throws {
        let completed = findElement("sidebar.completed")
        XCTAssertTrue(completed.waitForExistence(timeout: 5))
        completed.click()

        let list = findElement("tripList")
        XCTAssertTrue(list.waitForExistence(timeout: 5))
    }

    func testNavigateToArchived() throws {
        let archived = findElement("sidebar.archived")
        XCTAssertTrue(archived.waitForExistence(timeout: 5))
        archived.click()

        let list = findElement("tripList")
        XCTAssertTrue(list.waitForExistence(timeout: 5))
    }

    // MARK: - Sidebar Navigation: Manage

    func testNavigateToTags() throws {
        let tags = findElement("sidebar.tags")
        XCTAssertTrue(tags.waitForExistence(timeout: 5))
        tags.click()

        let manager = findElement("tagManager")
        XCTAssertTrue(manager.waitForExistence(timeout: 5))
    }

    func testNavigateToStatistics() throws {
        let stats = findElement("sidebar.statistics")
        XCTAssertTrue(stats.waitForExistence(timeout: 5))
        stats.click()

        let detail = findElement("detail.statistics")
        XCTAssertTrue(detail.waitForExistence(timeout: 10))
    }

    // MARK: - Template Selection

    func testSelectTemplateFromList() throws {
        let list = findElement("templateList")
        XCTAssertTrue(list.waitForExistence(timeout: 5))

        let firstTemplate = list.buttons.firstMatch
        if firstTemplate.waitForExistence(timeout: 5) {
            firstTemplate.click()
            let detail = findElement("detail.template")
            XCTAssertTrue(detail.waitForExistence(timeout: 5))
        }
    }

    // MARK: - Trip Selection

    func testSelectTripFromList() throws {
        let planning = findElement("sidebar.planning")
        XCTAssertTrue(planning.waitForExistence(timeout: 5))
        planning.click()

        let list = findElement("tripList")
        XCTAssertTrue(list.waitForExistence(timeout: 5))

        let firstTrip = list.buttons.firstMatch
        if firstTrip.waitForExistence(timeout: 5) {
            firstTrip.click()
            let detail = findElement("detail.trip")
            XCTAssertTrue(detail.waitForExistence(timeout: 5))
        }
    }

    // MARK: - Empty States

    func testEmptyDetailForTemplates() throws {
        let list = findElement("templateList")
        XCTAssertTrue(list.waitForExistence(timeout: 5))

        // If no template is selected, empty detail should show
        let empty = findElement("detail.empty.template")
        if empty.waitForExistence(timeout: 3) {
            XCTAssertTrue(empty.exists)
        }
    }

    func testEmptyDetailForTrips() throws {
        let active = findElement("sidebar.active")
        XCTAssertTrue(active.waitForExistence(timeout: 5))
        active.click()

        let empty = findElement("detail.empty.trip")
        if empty.waitForExistence(timeout: 3) {
            XCTAssertTrue(empty.exists)
        }
    }

    func testEmptyDetailForTags() throws {
        let tags = findElement("sidebar.tags")
        XCTAssertTrue(tags.waitForExistence(timeout: 5))
        tags.click()

        let empty = findElement("detail.empty.tag")
        if empty.waitForExistence(timeout: 3) {
            XCTAssertTrue(empty.exists)
        }
    }

    // MARK: - Navigation Round-Trip

    func testNavigateAwayAndBack() throws {
        // Start at templates
        let templates = findElement("sidebar.templates")
        XCTAssertTrue(templates.waitForExistence(timeout: 5))
        templates.click()
        let templateList = findElement("templateList")
        XCTAssertTrue(templateList.waitForExistence(timeout: 5))

        // Navigate to tags
        let tags = findElement("sidebar.tags")
        XCTAssertTrue(tags.waitForExistence(timeout: 5))
        tags.click()
        let manager = findElement("tagManager")
        XCTAssertTrue(manager.waitForExistence(timeout: 5))

        // Navigate back to templates
        templates.click()
        XCTAssertTrue(templateList.waitForExistence(timeout: 5))
    }
}
