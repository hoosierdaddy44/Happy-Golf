import XCTest
@testable import Happy

final class TeeTimeModelTests: XCTestCase {

    private let futureDate = Date().addingTimeInterval(86400 * 7)  // 7 days from now
    private let pastDate   = Date().addingTimeInterval(-86400)      // yesterday

    func testIsCompletedFalseForFutureRound() {
        let tt = makeTeeTime(date: futureDate)
        XCTAssertFalse(tt.isCompleted)
    }

    func testIsCompletedTrueForPastRound() {
        let tt = makeTeeTime(date: pastDate)
        XCTAssertTrue(tt.isCompleted)
    }

    func testIsFullWhenNoOpenSpots() {
        let tt = makeTeeTime(openSpots: 0)
        XCTAssertTrue(tt.isFull)
    }

    func testIsNotFullWhenOpenSpotsRemain() {
        let tt = makeTeeTime(openSpots: 2)
        XCTAssertFalse(tt.isFull)
    }

    func testDateDisplayFormat() {
        // Create a fixed known date: Tuesday April 21 2026
        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 21
        let date = Calendar.current.date(from: comps)!
        let tt = makeTeeTime(date: date)
        XCTAssertEqual(tt.dateDisplay, "Tue, Apr 21")
    }

    func testConfirmedPlayerIdsIncludesHost() {
        let hostId = UUID()
        let playerId = UUID()
        let tt = makeTeeTime(hostId: hostId, players: [playerId])
        XCTAssertTrue(tt.confirmedPlayerIds.contains(hostId))
        XCTAssertTrue(tt.confirmedPlayerIds.contains(playerId))
        XCTAssertEqual(tt.confirmedPlayerIds.count, 2)
    }

    func testParIsDefaultSeventyTwo() {
        let tt = makeTeeTime()
        XCTAssertEqual(tt.par, 72)
    }

    func testScoreDefaultsToNil() {
        let tt = makeTeeTime()
        XCTAssertNil(tt.score)
    }

    func testScoreCanBeSet() {
        var tt = makeTeeTime()
        tt.score = 78
        XCTAssertEqual(tt.score, 78)
    }

    // MARK: - Helpers

    private func makeTeeTime(
        hostId: UUID = UUID(),
        date: Date = Date().addingTimeInterval(86400),
        openSpots: Int = 2,
        players: [UUID] = []
    ) -> TeeTime {
        TeeTime(
            hostId: hostId,
            courseName: "Bethpage Black",
            courseLocation: "Farmingdale, NY",
            date: date,
            teeTimeString: "7:00 AM",
            openSpots: openSpots,
            totalSpots: openSpots + 1,
            players: players
        )
    }
}

final class UserModelTests: XCTestCase {

    func testInitialsTwoWordName() {
        let user = makeUser(name: "James Kim")
        XCTAssertEqual(user.initials, "JK")
    }

    func testInitialsSingleName() {
        let user = makeUser(name: "Madonna")
        XCTAssertEqual(user.initials, "M")
    }

    func testInitialsThreeWordNameTakesFirstTwo() {
        let user = makeUser(name: "Mary Jane Watson")
        XCTAssertEqual(user.initials, "MJ")
    }

    func testHandicapDisplayOneDecimal() {
        let user = makeUser(handicap: 8.4)
        XCTAssertEqual(user.handicapDisplay, "8.4")
    }

    func testHandicapDisplayZero() {
        let user = makeUser(handicap: 0.0)
        XCTAssertEqual(user.handicapDisplay, "0.0")
    }

    func testRatingDisplayWhenNil() {
        let user = makeUser(rating: nil)
        XCTAssertEqual(user.ratingDisplay, "—")
    }

    func testRatingDisplayWithValue() {
        let user = makeUser(rating: 4.7)
        XCTAssertEqual(user.ratingDisplay, "4.7")
    }

    // MARK: - Helpers

    private func makeUser(name: String = "Test User", handicap: Double = 10.0, rating: Double? = nil) -> User {
        User(name: name, username: "testuser", handicapIndex: handicap, industry: "Tech", rating: rating)
    }
}

final class JoinRequestModelTests: XCTestCase {

    func testDefaultStatusIsPending() {
        let req = JoinRequest(teeTimeId: UUID(), requesterId: UUID())
        XCTAssertEqual(req.status, .pending)
    }

    func testStatusCanBeSetToApproved() {
        var req = JoinRequest(teeTimeId: UUID(), requesterId: UUID())
        req.status = .approved
        XCTAssertEqual(req.status, .approved)
    }

    func testStatusCanBeSetToDeclined() {
        var req = JoinRequest(teeTimeId: UUID(), requesterId: UUID())
        req.status = .declined
        XCTAssertEqual(req.status, .declined)
    }

    func testNoteDefaultsToNil() {
        let req = JoinRequest(teeTimeId: UUID(), requesterId: UUID())
        XCTAssertNil(req.note)
    }

    func testNoteCanBeSet() {
        let req = JoinRequest(teeTimeId: UUID(), requesterId: UUID(), note: "Looking forward to it!")
        XCTAssertEqual(req.note, "Looking forward to it!")
    }
}
