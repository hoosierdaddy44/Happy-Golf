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
    @Published var pendingRatingPrompts: [TeeTime] = []
    @Published var accolades: [UUID: [Accolade]] = [:]

    // Cached profiles for displaying other users
    var profileCache: [UUID: User] = [:]

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
            checkPendingRatingPrompts(userId: userId)
            await fetchAccolades(for: userId)
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

    // MARK: - Ratings & Accolades

    func submitRating(teeTimeId: UUID, rateeId: UUID, score: Int) async {
        guard let user = currentUser else { return }
        do {
            try await supabase
                .from("round_ratings")
                .insert([
                    "tee_time_id": teeTimeId.uuidString,
                    "rater_id": user.id.uuidString,
                    "ratee_id": rateeId.uuidString,
                    "score": String(score)
                ])
                .execute()
            pendingRatingPrompts.removeAll { $0.id == teeTimeId }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func claimAccolade(type: AccoladeType, teeTimeId: UUID?) async {
        guard let user = currentUser else { return }
        if devUserId != nil { return } // skip in dev mode
        do {
            var body: [String: String] = [
                "user_id": user.id.uuidString,
                "type": type.rawValue
            ]
            if let ttId = teeTimeId { body["tee_time_id"] = ttId.uuidString }
            let response = try await supabase
                .from("accolades")
                .insert(body)
                .single()
                .execute()
            let row = try decoder.decode(AccoladeRow.self, from: response.data)
            accolades[user.id, default: []].insert(row.toAccolade(), at: 0)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func verifyAccolade(_ accolade: Accolade) async {
        guard let user = currentUser else { return }
        if devUserId != nil { return }
        do {
            let response = try await supabase
                .from("accolade_verifications")
                .insert([
                    "accolade_id": accolade.id.uuidString,
                    "verifier_id": user.id.uuidString
                ])
                .single()
                .execute()
            let row = try decoder.decode(AccoladeVerificationRow.self, from: response.data)
            let ver = row.toVerification()
            if let idx = accolades[accolade.userId]?.firstIndex(where: { $0.id == accolade.id }) {
                accolades[accolade.userId]?[idx].verifications.append(ver)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func fetchAccolades(for userId: UUID) async {
        if devUserId != nil { return }
        do {
            let aResponse = try await supabase
                .from("accolades")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
            let rows = try decoder.decode([AccoladeRow].self, from: aResponse.data)
            guard !rows.isEmpty else { accolades[userId] = []; return }

            let vResponse = try await supabase
                .from("accolade_verifications")
                .select()
                .in("accolade_id", values: rows.map { $0.id.uuidString })
                .execute()
            let verRows = try decoder.decode([AccoladeVerificationRow].self, from: vResponse.data)
            let verifications = verRows.map { $0.toVerification() }

            accolades[userId] = rows.map { row in
                let vers = verifications.filter { $0.accoladeId == row.id }
                return row.toAccolade(verifications: vers)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func fetchCachedProfile(userId: UUID) async {
        guard profileCache[userId] == nil, devUserId == nil else { return }
        do {
            let response = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
            let row = try decoder.decode(ProfileRow.self, from: response.data)
            profileCache[userId] = row.toUser()
        } catch { }
    }

    private func checkPendingRatingPrompts(userId: UUID) {
        pendingRatingPrompts = teeTimes.filter {
            ($0.players.contains(userId) || $0.hostId == userId) && $0.date < Date()
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
