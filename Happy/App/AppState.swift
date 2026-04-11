import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var isOnboarded: Bool = false
    @Published var teeTimes: [TeeTime] = TeeTime.mockData
    @Published var joinRequests: [JoinRequest] = []
    @Published var activityEvents: [ActivityEvent] = ActivityEvent.mockData

    var currentUserTeeTimes: [TeeTime] {
        guard let user = currentUser else { return [] }
        return teeTimes.filter { $0.hostId == user.id || $0.players.contains(user.id) }
    }

    var pendingRequestsForHost: [JoinRequest] {
        guard let user = currentUser else { return [] }
        let myTeeTimeIds = teeTimes.filter { $0.hostId == user.id }.map { $0.id }
        return joinRequests.filter { myTeeTimeIds.contains($0.teeTimeId) && $0.status == .pending }
    }

    func createProfile(name: String, handicap: Double, industry: String, pace: PacePref, homeCourse: String) {
        let user = User(
            name: name,
            handicapIndex: handicap,
            industry: industry,
            interests: [],
            pacePreference: pace,
            homeCourses: homeCourse.isEmpty ? [] : [homeCourse]
        )
        currentUser = user
        isOnboarded = true
    }

    func hostTeeTime(_ teeTime: TeeTime) {
        teeTimes.insert(teeTime, at: 0)
        let event = ActivityEvent(
            type: .newTeeTime,
            actorId: teeTime.hostId,
            teeTimeId: teeTime.id
        )
        activityEvents.insert(event, at: 0)
    }

    func requestToJoin(teeTime: TeeTime, note: String?) {
        guard let user = currentUser else { return }
        let request = JoinRequest(teeTimeId: teeTime.id, requesterId: user.id, note: note)
        joinRequests.append(request)
        let event = ActivityEvent(type: .requestSent, actorId: user.id, teeTimeId: teeTime.id)
        activityEvents.insert(event, at: 0)
    }

    func approveRequest(_ request: JoinRequest) {
        if let idx = joinRequests.firstIndex(where: { $0.id == request.id }) {
            joinRequests[idx].status = .approved
        }
        if let ttIdx = teeTimes.firstIndex(where: { $0.id == request.teeTimeId }) {
            if !teeTimes[ttIdx].players.contains(request.requesterId) {
                teeTimes[ttIdx].players.append(request.requesterId)
                teeTimes[ttIdx].openSpots = max(0, teeTimes[ttIdx].openSpots - 1)
            }
        }
        let event = ActivityEvent(type: .approved, actorId: request.requesterId, teeTimeId: request.teeTimeId)
        activityEvents.insert(event, at: 0)
    }

    func declineRequest(_ request: JoinRequest) {
        if let idx = joinRequests.firstIndex(where: { $0.id == request.id }) {
            joinRequests[idx].status = .declined
        }
        let event = ActivityEvent(type: .declined, actorId: request.requesterId, teeTimeId: request.teeTimeId)
        activityEvents.insert(event, at: 0)
    }

    func user(for id: UUID) -> User? {
        if currentUser?.id == id { return currentUser }
        return User.mockUsers.first(where: { $0.id == id })
    }

    func teeTime(for id: UUID) -> TeeTime? {
        teeTimes.first(where: { $0.id == id })
    }
}
