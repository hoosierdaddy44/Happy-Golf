import XCTest
@testable import Happy

@MainActor
final class AppStateTests: XCTestCase {

    private var state: AppState!
    private let userId = UUID()

    override func setUp() async throws {
        state = AppState()
        state.devUserId = UUID()
        state.currentUser = User(
            id: userId,
            name: "Test User",
            username: "testuser",
            handicapIndex: 10.0,
            industry: "Tech"
        )
    }

    // MARK: - hostedRounds (via currentUserTeeTimes)

    func testCurrentUserTeeTimesIncludesHostedRounds() {
        let hosted = makeTeeTime(hostId: userId)
        state.teeTimes = [hosted]
        XCTAssertTrue(state.currentUserTeeTimes.contains(hosted))
    }

    func testCurrentUserTeeTimesIncludesJoinedRounds() {
        let otherId = UUID()
        let joined = makeTeeTime(hostId: otherId, players: [userId])
        state.teeTimes = [joined]
        XCTAssertTrue(state.currentUserTeeTimes.contains(joined))
    }

    func testCurrentUserTeeTimesExcludesUnrelatedRounds() {
        let otherId = UUID()
        let unrelated = makeTeeTime(hostId: otherId)
        state.teeTimes = [unrelated]
        XCTAssertTrue(state.currentUserTeeTimes.isEmpty)
    }

    func testCurrentUserTeeTimesEmptyWhenNoUser() {
        state.currentUser = nil
        state.teeTimes = [makeTeeTime(hostId: userId)]
        XCTAssertTrue(state.currentUserTeeTimes.isEmpty)
    }

    // MARK: - pendingRequestsForHost

    func testPendingRequestsForHostReturnsOnlyPending() {
        let ttId = UUID()
        state.teeTimes = [makeTeeTime(id: ttId, hostId: userId)]
        let pending = JoinRequest(teeTimeId: ttId, requesterId: UUID(), status: .pending)
        let approved = JoinRequest(teeTimeId: ttId, requesterId: UUID(), status: .approved)
        state.joinRequests = [pending, approved]
        XCTAssertEqual(state.pendingRequestsForHost.count, 1)
        XCTAssertEqual(state.pendingRequestsForHost.first?.id, pending.id)
    }

    func testPendingRequestsForHostExcludesOtherHosts() {
        let otherId = UUID()
        let otherTTId = UUID()
        state.teeTimes = [makeTeeTime(id: otherTTId, hostId: otherId)]
        let req = JoinRequest(teeTimeId: otherTTId, requesterId: UUID(), status: .pending)
        state.joinRequests = [req]
        XCTAssertTrue(state.pendingRequestsForHost.isEmpty)
    }

    func testPendingRequestsForHostEmptyWhenNoRequests() {
        let ttId = UUID()
        state.teeTimes = [makeTeeTime(id: ttId, hostId: userId)]
        state.joinRequests = []
        XCTAssertTrue(state.pendingRequestsForHost.isEmpty)
    }

    // MARK: - hostTeeTime (dev mode)

    func testHostTeeTimeAddsTeeTimeInDevMode() async {
        let tt = makeTeeTime(hostId: userId)
        let initialCount = state.teeTimes.count
        await state.hostTeeTime(tt)
        XCTAssertEqual(state.teeTimes.count, initialCount + 1)
        XCTAssertTrue(state.teeTimes.contains(tt))
    }

    func testHostTeeTimeInsertsAtFront() async {
        let existing = makeTeeTime(hostId: userId)
        state.teeTimes = [existing]
        let newTT = makeTeeTime(hostId: userId)
        await state.hostTeeTime(newTT)
        XCTAssertEqual(state.teeTimes.first?.id, newTT.id)
    }

    // MARK: - requestToJoin (dev mode)

    func testRequestToJoinAddsJoinRequestInDevMode() async {
        let tt = makeTeeTime(hostId: UUID())
        state.teeTimes = [tt]
        await state.requestToJoin(teeTime: tt, note: "Can't wait!")
        XCTAssertEqual(state.joinRequests.count, 1)
        XCTAssertEqual(state.joinRequests.first?.requesterId, userId)
        XCTAssertEqual(state.joinRequests.first?.note, "Can't wait!")
        XCTAssertEqual(state.joinRequests.first?.status, .pending)
    }

    func testRequestToJoinWithNilNote() async {
        let tt = makeTeeTime(hostId: UUID())
        state.teeTimes = [tt]
        await state.requestToJoin(teeTime: tt, note: nil)
        XCTAssertNil(state.joinRequests.first?.note)
    }

    // MARK: - deleteTeeTime (dev mode)

    func testDeleteTeeTimeRemovesFromArray() async {
        let tt = makeTeeTime(hostId: userId)
        state.teeTimes = [tt]
        await state.deleteTeeTime(id: tt.id)
        XCTAssertTrue(state.teeTimes.isEmpty)
    }

    func testDeleteTeeTimeOnlyRemovesMatchingId() async {
        let tt1 = makeTeeTime(hostId: userId)
        let tt2 = makeTeeTime(hostId: userId)
        state.teeTimes = [tt1, tt2]
        await state.deleteTeeTime(id: tt1.id)
        XCTAssertEqual(state.teeTimes.count, 1)
        XCTAssertEqual(state.teeTimes.first?.id, tt2.id)
    }

    // MARK: - updateProfile (dev mode)

    func testUpdateProfileUpdatesCurrentUser() async {
        await state.updateProfile(
            name: "Updated Name",
            username: "updated",
            handicap: 5.0,
            industry: "Finance",
            pace: .fast,
            homeCourse: "Augusta National"
        )
        XCTAssertEqual(state.currentUser?.name, "Updated Name")
        XCTAssertEqual(state.currentUser?.username, "updated")
        XCTAssertEqual(state.currentUser?.handicapIndex, 5.0)
        XCTAssertEqual(state.currentUser?.industry, "Finance")
        XCTAssertEqual(state.currentUser?.pacePreference, .fast)
        XCTAssertEqual(state.currentUser?.homeCourses, ["Augusta National"])
    }

    // MARK: - searchUsers (dev mode)

    func testSearchUsersReturnsMatchingResults() async {
        let results = await state.searchUsers(query: "james")
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.allSatisfy { $0.name.lowercased().contains("james") || $0.username.lowercased().contains("james") })
    }

    func testSearchUsersEmptyQueryReturnsEmpty() async {
        let results = await state.searchUsers(query: "")
        XCTAssertTrue(results.isEmpty)
    }

    func testSearchUsersNoMatchReturnsEmpty() async {
        let results = await state.searchUsers(query: "xyzzy_no_match_9999")
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - sendFriendRequest (dev mode)

    func testSendFriendRequestAddsPendingFriendship() async {
        let targetId = UUID()
        await state.sendFriendRequest(to: targetId)
        XCTAssertFalse(state.friendships.isEmpty)
        let friendship = state.friendships.first { $0.addresseeId == targetId }
        XCTAssertNotNil(friendship)
        XCTAssertEqual(friendship?.status, .pending)
        XCTAssertEqual(friendship?.requesterId, userId)
    }

    func testIsFriendRequestSentByMe() async {
        let targetId = UUID()
        await state.sendFriendRequest(to: targetId)
        XCTAssertTrue(state.isFriendRequestSentByMe(to: targetId))
    }

    // MARK: - Helpers

    private func makeTeeTime(id: UUID = UUID(), hostId: UUID, players: [UUID] = []) -> TeeTime {
        TeeTime(
            id: id,
            hostId: hostId,
            courseName: "Test Course",
            courseLocation: "Test, NY",
            date: Date().addingTimeInterval(86400),
            teeTimeString: "8:00 AM",
            openSpots: 2,
            totalSpots: 3,
            players: players
        )
    }
}
