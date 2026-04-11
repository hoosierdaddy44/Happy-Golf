import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var isOnboarded: Bool = false
    @Published var teeTimes: [TeeTime] = []
    @Published var joinRequests: [JoinRequest] = []
    @Published var activityEvents: [ActivityEvent] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    // Cached profiles for displaying other users
    private var profileCache: [UUID: User] = [:]

    // Set when using dev bypass (no real Supabase session)
    var devUserId: UUID?

    var currentUserTeeTimes: [TeeTime] {
        guard let user = currentUser else { return [] }
        return teeTimes.filter { $0.hostId == user.id || $0.players.contains(user.id) }
    }

    var pendingRequestsForHost: [JoinRequest] {
        guard let user = currentUser else { return [] }
        let myTeeTimeIds = teeTimes.filter { $0.hostId == user.id }.map { $0.id }
        return joinRequests.filter { myTeeTimeIds.contains($0.teeTimeId) && $0.status == .pending }
    }

    // MARK: - Bootstrap

    func load(userId: UUID) async {
        isLoading = true
        async let profileTask: () = fetchProfile(userId: userId)
        async let teeTimesTask: () = fetchTeeTimes()
        async let activityTask: () = fetchActivity()
        _ = await (profileTask, teeTimesTask, activityTask)
        if currentUser != nil {
            await fetchJoinRequests(userId: userId)
        }
        isLoading = false
    }

    // MARK: - Fetch

    private func fetchProfile(userId: UUID) async {
        do {
            let response = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
            let row = try decoder.decode(ProfileRow.self, from: response.data)
            currentUser = row.toUser()
            profileCache[userId] = currentUser
            isOnboarded = true
        } catch {
            // Profile doesn't exist yet — user needs onboarding
            isOnboarded = false
        }
    }

    func fetchTeeTimes() async {
        do {
            let response = try await supabase
                .from("tee_times")
                .select()
                .eq("is_active", value: true)
                .order("tee_date", ascending: true)
                .execute()
            let rows = try decoder.decode([TeeTimeRow].self, from: response.data)

            // Fetch approved join requests to know player counts
            let requestRows: [JoinRequestRow]
            if let rr = try? await supabase
                .from("join_requests")
                .select()
                .eq("status", value: "approved")
                .execute(),
               let decoded = try? decoder.decode([JoinRequestRow].self, from: rr.data) {
                requestRows = decoded
            } else {
                requestRows = []
            }

            teeTimes = rows.map { row in
                let approvedIds = requestRows
                    .filter { $0.teeTimeId == row.id }
                    .map { $0.requesterId }
                return row.toTeeTime(approvedPlayerIds: approvedIds)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func fetchJoinRequests(userId: UUID) async {
        do {
            let response = try await supabase
                .from("join_requests")
                .select()
                .or("requester_id.eq.\(userId),tee_time_id.in.(\(myTeeTimeIdList()))")
                .execute()
            let rows = try decoder.decode([JoinRequestRow].self, from: response.data)
            joinRequests = rows.map { $0.toJoinRequest() }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func fetchActivity() async {
        do {
            let response = try await supabase
                .from("activity_events")
                .select()
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
            let rows = try decoder.decode([ActivityEventRow].self, from: response.data)
            activityEvents = rows.map { $0.toActivityEvent() }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Write

    func createProfile(name: String, handicap: Double, industry: String, pace: PacePref, homeCourse: String) async {
        guard let userId = (try? await supabase.auth.session.user.id) ?? devUserId else { return }

        // Dev bypass: skip Supabase, set user in-memory only
        if devUserId != nil {
            currentUser = User(
                id: userId,
                name: name,
                handicapIndex: handicap,
                industry: industry,
                pacePreference: pace,
                homeCourses: homeCourse.isEmpty ? [] : [homeCourse]
            )
            profileCache[userId] = currentUser
            isOnboarded = true
            return
        }

        do {
            let response = try await supabase
                .from("profiles")
                .upsert([
                    "id": userId.uuidString,
                    "name": name,
                    "handicap_index": String(handicap),
                    "industry": industry,
                    "pace_preference": pace.rawValue.lowercased(),
                    "home_courses": homeCourse.isEmpty ? "[]" : "[\"\(homeCourse)\"]"
                ])
                .single()
                .execute()
            let row = try decoder.decode(ProfileRow.self, from: response.data)
            currentUser = row.toUser()
            profileCache[userId] = currentUser
            isOnboarded = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func hostTeeTime(_ teeTime: TeeTime) async {
        guard let user = currentUser else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        do {
            let response = try await supabase
                .from("tee_times")
                .insert([
                    "host_id": user.id.uuidString,
                    "course_name": teeTime.courseName,
                    "location": teeTime.courseLocation,
                    "tee_date": dateFormatter.string(from: teeTime.date),
                    "tee_time": teeTime.teeTimeString,
                    "open_spots": String(teeTime.openSpots),
                    "carry_mode": teeTime.carryMode.rawValue.lowercased(),
                    "notes": teeTime.notes ?? ""
                ])
                .single()
                .execute()
            let row = try decoder.decode(TeeTimeRow.self, from: response.data)
            teeTimes.insert(row.toTeeTime(), at: 0)
            await logActivity(type: .newTeeTime, teeTimeId: row.id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func requestToJoin(teeTime: TeeTime, note: String?) async {
        guard let user = currentUser else { return }
        do {
            let response = try await supabase
                .from("join_requests")
                .insert([
                    "tee_time_id": teeTime.id.uuidString,
                    "requester_id": user.id.uuidString
                ])
                .single()
                .execute()
            let row = try decoder.decode(JoinRequestRow.self, from: response.data)
            joinRequests.append(row.toJoinRequest())
            await logActivity(type: .requestSent, teeTimeId: teeTime.id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func approveRequest(_ request: JoinRequest) async {
        do {
            try await supabase
                .from("join_requests")
                .update(["status": "approved"])
                .eq("id", value: request.id)
                .execute()
            if let idx = joinRequests.firstIndex(where: { $0.id == request.id }) {
                joinRequests[idx].status = .approved
            }
            if let ttIdx = teeTimes.firstIndex(where: { $0.id == request.teeTimeId }) {
                if !teeTimes[ttIdx].players.contains(request.requesterId) {
                    teeTimes[ttIdx].players.append(request.requesterId)
                    teeTimes[ttIdx].openSpots = max(0, teeTimes[ttIdx].openSpots - 1)
                }
            }
            await logActivity(type: .approved, teeTimeId: request.teeTimeId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func declineRequest(_ request: JoinRequest) async {
        do {
            try await supabase
                .from("join_requests")
                .update(["status": "declined"])
                .eq("id", value: request.id)
                .execute()
            if let idx = joinRequests.firstIndex(where: { $0.id == request.id }) {
                joinRequests[idx].status = .declined
            }
            await logActivity(type: .declined, teeTimeId: request.teeTimeId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Helpers

    func user(for id: UUID) -> User? {
        if currentUser?.id == id { return currentUser }
        return profileCache[id]
    }

    func teeTime(for id: UUID) -> TeeTime? {
        teeTimes.first(where: { $0.id == id })
    }

    private func myTeeTimeIdList() -> String {
        guard let user = currentUser else { return "" }
        let ids = teeTimes.filter { $0.hostId == user.id }.map { $0.id.uuidString }
        return ids.joined(separator: ",")
    }

    private func logActivity(type: ActivityType, teeTimeId: UUID) async {
        guard let user = currentUser else { return }
        let event = ActivityEvent(type: type, actorId: user.id, teeTimeId: teeTimeId)
        activityEvents.insert(event, at: 0)
        _ = try? await supabase
            .from("activity_events")
            .insert([
                "type": type.rawValue,
                "actor_id": user.id.uuidString,
                "tee_time_id": teeTimeId.uuidString
            ])
            .execute()
    }

    // MARK: - JSON Decoder

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let str = try decoder.singleValueContainer().decode(String.self)
            let formatters: [DateFormatter] = [
                { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"; return f }(),
                { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"; return f }(),
                { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f }()
            ]
            for f in formatters {
                if let date = f.date(from: str) { return date }
            }
            throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(),
                debugDescription: "Cannot decode date: \(str)")
        }
        return d
    }
}
