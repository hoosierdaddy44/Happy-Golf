import XCTest

class HappyUITests: XCTestCase {

    let app = XCUIApplication(bundleIdentifier: "com.joinhappygolf.app")

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    // MARK: - Helpers

    /// Navigate from Welcome → Email Auth → Skip Auth (Dev) → Onboarding
    func skipToOnboarding() {
        // Welcome screen
        XCTAssertTrue(app.staticTexts["Golf on your"].waitForExistence(timeout: 5))
        app.buttons["Dev Login"].tap()

        // Dev login sheet
        XCTAssertTrue(app.staticTexts["Email Sign In"].waitForExistence(timeout: 3))
        app.buttons["Skip Auth (Dev)"].tap()
    }

    /// Complete both onboarding steps with test data
    func completeOnboarding(firstName: String = "Test", lastName: String = "User") {
        // Step 1
        XCTAssertTrue(app.staticTexts["STEP 1 OF 2"].waitForExistence(timeout: 5))

        let firstField = app.textFields.element(boundBy: 0)
        firstField.tap(); firstField.typeText(firstName)

        let lastField = app.textFields.element(boundBy: 1)
        lastField.tap(); lastField.typeText(lastName)

        let usernameField = app.textFields.element(boundBy: 2)
        usernameField.tap(); usernameField.typeText("testuser99")

        let handicapField = app.textFields.element(boundBy: 3)
        handicapField.tap(); handicapField.typeText("12.0")

        app.buttons["Continue →"].tap()

        // Step 2
        XCTAssertTrue(app.staticTexts["STEP 2 OF 2"].waitForExistence(timeout: 3))

        let industryField = app.textFields.element(boundBy: 0)
        industryField.tap(); industryField.typeText("Tech")

        let courseField = app.textFields.element(boundBy: 1)
        courseField.tap(); courseField.typeText("Pebble Beach")

        // Wait for suggestion and tap first result if it appears
        let suggestion = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Pebble'")).firstMatch
        if suggestion.waitForExistence(timeout: 3) { suggestion.tap() }

        app.buttons["Join Happy →"].tap()
    }

    /// Go from Welcome all the way into the main app
    func enterApp() {
        skipToOnboarding()
        completeOnboarding()
        XCTAssertTrue(app.staticTexts["Discover"].waitForExistence(timeout: 5))
    }
}

// MARK: - Auth Flow Tests

final class AuthFlowTests: HappyUITests {

    func testWelcomeScreenElements() {
        XCTAssertTrue(app.staticTexts["Golf on your"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Sign in with Apple"].exists)
        XCTAssertTrue(app.buttons["Continue with Email →"].exists)
        XCTAssertTrue(app.buttons["Dev Login"].exists)
    }

    func testDevLoginOpensEmailSheet() {
        XCTAssertTrue(app.staticTexts["Golf on your"].waitForExistence(timeout: 5))
        app.buttons["Dev Login"].tap()
        XCTAssertTrue(app.staticTexts["Email Sign In"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Skip Auth (Dev)"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
    }

    func testSkipAuthNavigatesToOnboarding() {
        skipToOnboarding()
        XCTAssertTrue(app.staticTexts["STEP 1 OF 2"].waitForExistence(timeout: 5))
    }

    func testCancelEmailSheetReturnsToWelcome() {
        app.buttons["Dev Login"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["Golf on your"].waitForExistence(timeout: 3))
    }
}

// MARK: - Onboarding Tests

final class OnboardingTests: HappyUITests {

    func testStep1RequiredFieldsEnableContinue() {
        skipToOnboarding()
        XCTAssertTrue(app.staticTexts["STEP 1 OF 2"].waitForExistence(timeout: 5))

        // Continue should be disabled initially
        XCTAssertFalse(app.buttons["Continue →"].isEnabled)

        app.textFields.element(boundBy: 0).tap()
        app.textFields.element(boundBy: 0).typeText("John")
        app.textFields.element(boundBy: 1).tap()
        app.textFields.element(boundBy: 1).typeText("Doe")
        app.textFields.element(boundBy: 2).tap()
        app.textFields.element(boundBy: 2).typeText("johndoe")
        app.textFields.element(boundBy: 3).tap()
        app.textFields.element(boundBy: 3).typeText("5.0")

        XCTAssertTrue(app.buttons["Continue →"].isEnabled)
    }

    func testStep1ContinueNavigatesToStep2() {
        skipToOnboarding()
        XCTAssertTrue(app.staticTexts["STEP 1 OF 2"].waitForExistence(timeout: 5))
        completeStep1()
        XCTAssertTrue(app.staticTexts["STEP 2 OF 2"].waitForExistence(timeout: 3))
    }

    func testStep2BackNavigatesToStep1() {
        skipToOnboarding()
        completeStep1()
        XCTAssertTrue(app.staticTexts["STEP 2 OF 2"].waitForExistence(timeout: 3))
        app.buttons["Back"].tap()
        XCTAssertTrue(app.staticTexts["STEP 1 OF 2"].waitForExistence(timeout: 3))
    }

    func testStep2PaceOfPlayButtons() {
        skipToOnboarding()
        completeStep1()
        XCTAssertTrue(app.staticTexts["PACE OF PLAY"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["⚡, Fast"].exists)
        XCTAssertTrue(app.buttons["🕐, Standard"].exists)
        XCTAssertTrue(app.buttons["😌, Chill"].exists)
    }

    func testFullOnboardingReachesMainApp() {
        skipToOnboarding()
        completeOnboarding()
        XCTAssertTrue(app.staticTexts["Discover"].waitForExistence(timeout: 8))
    }

    private func completeStep1() {
        app.textFields.element(boundBy: 0).tap()
        app.textFields.element(boundBy: 0).typeText("John")
        app.textFields.element(boundBy: 1).tap()
        app.textFields.element(boundBy: 1).typeText("Doe")
        app.textFields.element(boundBy: 2).tap()
        app.textFields.element(boundBy: 2).typeText("johndoe")
        app.textFields.element(boundBy: 3).tap()
        app.textFields.element(boundBy: 3).typeText("5.0")
        app.buttons["Continue →"].tap()
    }
}

// MARK: - Discovery Feed Tests

final class DiscoveryFeedTests: HappyUITests {

    override func setUpWithError() throws {
        try super.setUpWithError()
        enterApp()
    }

    func testDiscoveryScreenElements() {
        XCTAssertTrue(app.staticTexts["Discover"].exists)
        XCTAssertTrue(app.buttons["All"].exists)
        XCTAssertTrue(app.buttons["Today"].exists)
        XCTAssertTrue(app.buttons["This Week"].exists)
    }

    func testAllFilterShowsRounds() {
        XCTAssertTrue(app.buttons["All"].exists)
        app.buttons["All"].tap()
        // At least one "View Round →" should be visible for mock data
        XCTAssertTrue(app.staticTexts["View Round →"].waitForExistence(timeout: 3))
    }

    func testTodayFilterShowsCorrectState() {
        app.buttons["Today"].tap()
        // Either shows rounds or "No open rounds right now."
        let noRounds = app.staticTexts["No open rounds right now."]
        let viewRound = app.staticTexts["View Round →"]
        XCTAssertTrue(noRounds.waitForExistence(timeout: 3) || viewRound.exists)
    }

    func testThisWeekFilterShowsCorrectState() {
        app.buttons["This Week"].tap()
        let noRounds = app.staticTexts["No open rounds right now."]
        let viewRound = app.staticTexts["View Round →"]
        XCTAssertTrue(noRounds.waitForExistence(timeout: 3) || viewRound.exists)
    }

    func testFriendsRoundsSectionExists() {
        XCTAssertTrue(app.staticTexts["FRIENDS' ROUNDS"].exists)
    }

    func testExpandYourNetworkSectionExists() {
        XCTAssertTrue(app.staticTexts["EXPAND YOUR NETWORK"].exists)
    }

    func testTappingViewRoundOpensTeeTimeDetail() {
        app.buttons["All"].tap()
        let viewRound = app.staticTexts["View Round →"].firstMatch
        XCTAssertTrue(viewRound.waitForExistence(timeout: 3))
        viewRound.tap()
        XCTAssertTrue(app.staticTexts["PLAYERS"].waitForExistence(timeout: 3))
    }
}

// MARK: - Tee Time Detail Tests

final class TeeTimeDetailTests: HappyUITests {

    override func setUpWithError() throws {
        try super.setUpWithError()
        enterApp()
        // Navigate to first round's detail
        app.buttons["All"].tap()
        let viewRound = app.staticTexts["View Round →"].firstMatch
        XCTAssertTrue(viewRound.waitForExistence(timeout: 3))
        viewRound.tap()
        XCTAssertTrue(app.staticTexts["PLAYERS"].waitForExistence(timeout: 3))
    }

    func testDetailShowsPlayersSection() {
        XCTAssertTrue(app.staticTexts["PLAYERS"].exists)
    }

    func testDetailShowsRequestToJoinButton() {
        XCTAssertTrue(app.buttons["Request to Join →"].exists)
    }

    func testRequestToJoinOpensSheet() {
        app.buttons["Request to Join →"].tap()
        XCTAssertTrue(app.staticTexts["JOIN REQUEST"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Send Request →"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
    }

    func testSendRequestDismissesSheet() {
        app.buttons["Request to Join →"].tap()
        XCTAssertTrue(app.buttons["Send Request →"].waitForExistence(timeout: 3))
        app.buttons["Send Request →"].tap()
        // Sheet should dismiss, back to detail
        XCTAssertTrue(app.staticTexts["PLAYERS"].waitForExistence(timeout: 3))
    }

    func testCancelRequestDismissesSheet() {
        app.buttons["Request to Join →"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["PLAYERS"].waitForExistence(timeout: 3))
    }

    func testBackButtonReturnsToDiscovery() {
        app.buttons["Back"].tap()
        XCTAssertTrue(app.staticTexts["Discover"].waitForExistence(timeout: 3))
    }
}

// MARK: - Host a Round Tests

final class HostRoundTests: HappyUITests {

    override func setUpWithError() throws {
        try super.setUpWithError()
        enterApp()
        app.tabBars.buttons["Host"].tap()
    }

    func testHostFormElements() {
        XCTAssertTrue(app.staticTexts["HOST A ROUND"].exists)
        XCTAssertTrue(app.staticTexts["COURSE NAME *"].exists)
        XCTAssertTrue(app.staticTexts["DATE"].exists)
        XCTAssertTrue(app.staticTexts["TEE TIME"].exists)
        XCTAssertTrue(app.staticTexts["OPEN SPOTS"].exists)
        XCTAssertTrue(app.staticTexts["TEES"].exists)
        XCTAssertTrue(app.staticTexts["CARRY MODE"].exists)
    }

    func testPostRoundButtonDisabledWithoutCourseName() {
        XCTAssertFalse(app.buttons["Post Round →"].isEnabled)
    }

    func testCourseSearchShowsAutocompleteSuggestions() {
        let courseField = app.textFields.firstMatch
        courseField.tap()
        courseField.typeText("Pebble Beach")
        let suggestion = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Pebble'")).firstMatch
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5))
    }

    func testSelectingCourseSuggestionEnablesPostButton() {
        let courseField = app.textFields.firstMatch
        courseField.tap()
        courseField.typeText("Augusta National")
        let suggestion = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Augusta'")).firstMatch
        if suggestion.waitForExistence(timeout: 5) {
            suggestion.tap()
            XCTAssertTrue(app.buttons["Post Round →"].isEnabled)
        }
    }

    func testOpenSpotsSegmentButtons() {
        XCTAssertTrue(app.buttons["1"].exists)
        XCTAssertTrue(app.buttons["2"].exists)
        XCTAssertTrue(app.buttons["3"].exists)
        app.buttons["1"].tap()
        app.buttons["3"].tap()
        // No crash expected
    }

    func testTeesSegmentButtons() {
        XCTAssertTrue(app.buttons["Blue"].exists)
        XCTAssertTrue(app.buttons["White"].exists)
        XCTAssertTrue(app.buttons["Gold"].exists)
        XCTAssertTrue(app.buttons["Red"].exists)
        app.buttons["White"].tap()
    }

    func testCarryModeButtons() {
        XCTAssertTrue(app.buttons["🚶 Walking"].exists)
        XCTAssertTrue(app.buttons["🏎️ Riding"].exists)
        app.buttons["🏎️ Riding"].tap()
    }

    func testSuccessfulPostShowsConfirmationScreen() {
        let courseField = app.textFields.firstMatch
        courseField.tap()
        courseField.typeText("Augusta National")
        let suggestion = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Augusta'")).firstMatch
        if suggestion.waitForExistence(timeout: 5) { suggestion.tap() }

        // Scroll to Post Round button
        let postButton = app.buttons["Post Round →"]
        postButton.tap()

        XCTAssertTrue(app.staticTexts["Round Posted."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Post Another Round"].exists)
    }
}

// MARK: - My Rounds Tests

final class MyRoundsTests: HappyUITests {

    override func setUpWithError() throws {
        try super.setUpWithError()
        enterApp()
        app.tabBars.buttons["My Rounds"].tap()
    }

    func testMyRoundsTabBarElements() {
        XCTAssertTrue(app.staticTexts["My Rounds"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Hosting"].exists)
        XCTAssertTrue(app.buttons["Joined"].exists)
    }

    func testHostingTabShowsYourRoundsSection() {
        app.buttons["Hosting"].tap()
        XCTAssertTrue(app.staticTexts["YOUR ROUNDS"].waitForExistence(timeout: 3))
    }

    func testJoinedTabShowsEmptyOrRounds() {
        app.buttons["Joined"].tap()
        let empty = app.staticTexts["You haven't joined a round yet."]
        let rounds = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Confirmed'")).firstMatch
        XCTAssertTrue(empty.waitForExistence(timeout: 3) || rounds.exists)
    }

    func testSwitchingBetweenTabs() {
        app.buttons["Hosting"].tap()
        XCTAssertTrue(app.staticTexts["YOUR ROUNDS"].waitForExistence(timeout: 3))
        app.buttons["Joined"].tap()
        XCTAssertTrue(app.buttons["Hosting"].waitForExistence(timeout: 2))
        app.buttons["Hosting"].tap()
        XCTAssertTrue(app.staticTexts["YOUR ROUNDS"].waitForExistence(timeout: 3))
    }

    func testHostedRoundAppearsAfterPosting() {
        // First host a round
        app.tabBars.buttons["Host"].tap()
        let courseField = app.textFields.firstMatch
        courseField.tap()
        courseField.typeText("Augusta National")
        let suggestion = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Augusta'")).firstMatch
        if suggestion.waitForExistence(timeout: 5) { suggestion.tap() }

        let postButton = app.buttons["Post Round →"]
        postButton.tap()

        XCTAssertTrue(app.staticTexts["Round Posted."].waitForExistence(timeout: 5))

        // Now go to My Rounds and verify it shows up
        app.tabBars.buttons["My Rounds"].tap()
        app.buttons["Hosting"].tap()

        let courseName = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Augusta'")).firstMatch
        XCTAssertTrue(courseName.waitForExistence(timeout: 3))
    }

    func testTappingHostedRoundOpensDetail() {
        // Host a round first so there's something to tap
        app.tabBars.buttons["Host"].tap()
        let courseField = app.textFields.firstMatch
        courseField.tap()
        courseField.typeText("Augusta")
        let suggestion = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Augusta'")).firstMatch
        if suggestion.waitForExistence(timeout: 5) { suggestion.tap() }
        app.buttons["Post Round →"].tap()
        XCTAssertTrue(app.staticTexts["Round Posted."].waitForExistence(timeout: 5))

        app.tabBars.buttons["My Rounds"].tap()
        app.buttons["Hosting"].tap()

        let round = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Augusta'")).firstMatch
        if round.waitForExistence(timeout: 3) {
            round.tap()
            XCTAssertTrue(app.staticTexts["PLAYERS"].waitForExistence(timeout: 3))
        }
    }
}

// MARK: - Activity Feed Tests

final class ActivityFeedTests: HappyUITests {

    override func setUpWithError() throws {
        try super.setUpWithError()
        enterApp()
        app.tabBars.buttons["Activity"].tap()
    }

    func testActivityScreenTitle() {
        XCTAssertTrue(app.staticTexts["Activity"].waitForExistence(timeout: 3))
    }

    func testActivityEmptyState() {
        let emptyText = app.staticTexts["No activity yet."]
        let hasActivity = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'joined'")).firstMatch
        XCTAssertTrue(emptyText.waitForExistence(timeout: 3) || hasActivity.exists)
    }

    func testActivityScreenHasHappyGolfLabel() {
        XCTAssertTrue(app.staticTexts["HAPPY GOLF"].waitForExistence(timeout: 3))
    }
}

// MARK: - Profile Tests

final class ProfileTests: HappyUITests {

    override func setUpWithError() throws {
        try super.setUpWithError()
        enterApp()
        app.tabBars.buttons["Profile"].tap()
    }

    func testProfileShowsUserInfo() {
        // Name "Test User" from completeOnboarding()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Test'")).firstMatch.waitForExistence(timeout: 3))
    }

    func testProfileShowsStatBlocks() {
        XCTAssertTrue(app.staticTexts["Rounds"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Tour Card"].exists)
        XCTAssertTrue(app.staticTexts["Avg Rating"].exists)
    }

    func testProfileShowsTourCardSection() {
        XCTAssertTrue(app.staticTexts["TOUR CARD"].waitForExistence(timeout: 3))
    }

    func testProfileShowsRecentRoundsSection() {
        XCTAssertTrue(app.staticTexts["RECENT ROUNDS"].waitForExistence(timeout: 3))
    }

    func testProfileMenuOpens() {
        let menuButton = app.buttons["More"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 3))
        menuButton.tap()
        XCTAssertTrue(app.buttons["Edit Profile"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Sign Out"].exists)
    }

    func testEditProfileSheetOpens() {
        app.buttons["More"].tap()
        app.buttons["Edit Profile"].tap()
        XCTAssertTrue(app.staticTexts["Edit Profile"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.buttons["Save Changes →"].exists)
    }

    func testEditProfilePrePopulatesFields() {
        app.buttons["More"].tap()
        app.buttons["Edit Profile"].tap()
        XCTAssertTrue(app.staticTexts["Edit Profile"].waitForExistence(timeout: 3))
        // First name field should be pre-populated with "Test"
        let firstNameField = app.textFields.element(boundBy: 0)
        XCTAssertEqual(firstNameField.value as? String, "Test")
    }

    func testEditProfileCancelDismissesSheet() {
        app.buttons["More"].tap()
        app.buttons["Edit Profile"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
        XCTAssertFalse(app.staticTexts["Edit Profile"].exists)
    }

    func testPlayerSearchOpens() {
        let searchButton = app.buttons["person.badge.plus"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3))
        searchButton.tap()
        XCTAssertTrue(app.staticTexts["Find Players"].waitForExistence(timeout: 3))
    }

    func testPlayerSearchReturnsResults() {
        app.buttons["person.badge.plus"].tap()
        XCTAssertTrue(app.staticTexts["Find Players"].waitForExistence(timeout: 3))
        let searchField = app.textFields.firstMatch
        searchField.tap()
        searchField.typeText("james")
        XCTAssertTrue(app.staticTexts["James K."].waitForExistence(timeout: 3))
    }

    func testPlayerSearchTapOpensMemberProfile() {
        app.buttons["person.badge.plus"].tap()
        XCTAssertTrue(app.staticTexts["Find Players"].waitForExistence(timeout: 3))
        let searchField = app.textFields.firstMatch
        searchField.tap()
        searchField.typeText("james")
        let result = app.staticTexts["James K."].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 3))
        result.tap()
        XCTAssertTrue(app.buttons["Add Friend"].waitForExistence(timeout: 3))
    }

    func testSignOutButtonExists() {
        // Scroll down to see Sign Out
        app.swipeUp()
        XCTAssertTrue(app.buttons["Sign Out"].waitForExistence(timeout: 3))
    }
}

// MARK: - Tab Bar Navigation Tests

final class TabBarNavigationTests: HappyUITests {

    override func setUpWithError() throws {
        try super.setUpWithError()
        enterApp()
    }

    func testAllFiveTabsExist() {
        XCTAssertTrue(app.tabBars.buttons["Discover"].exists)
        XCTAssertTrue(app.tabBars.buttons["Host"].exists)
        XCTAssertTrue(app.tabBars.buttons["My Rounds"].exists)
        XCTAssertTrue(app.tabBars.buttons["Activity"].exists)
        XCTAssertTrue(app.tabBars.buttons["Profile"].exists)
    }

    func testDiscoverTabNavigates() {
        app.tabBars.buttons["Discover"].tap()
        XCTAssertTrue(app.staticTexts["Discover"].waitForExistence(timeout: 3))
    }

    func testHostTabNavigates() {
        app.tabBars.buttons["Host"].tap()
        XCTAssertTrue(app.staticTexts["HOST A ROUND"].waitForExistence(timeout: 3))
    }

    func testMyRoundsTabNavigates() {
        app.tabBars.buttons["My Rounds"].tap()
        XCTAssertTrue(app.staticTexts["My Rounds"].waitForExistence(timeout: 3))
    }

    func testActivityTabNavigates() {
        app.tabBars.buttons["Activity"].tap()
        XCTAssertTrue(app.staticTexts["Activity"].waitForExistence(timeout: 3))
    }

    func testProfileTabNavigates() {
        app.tabBars.buttons["Profile"].tap()
        // Profile shows user name
        XCTAssertTrue(app.staticTexts["Rounds"].waitForExistence(timeout: 3))
    }
}
