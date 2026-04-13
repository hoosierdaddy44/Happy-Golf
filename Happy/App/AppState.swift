import SwiftUI
import Supabase

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
    @Published var friendships: [Friendship] = []

    // Cached profiles for displaying other users
    var profileCache: [UUID: User] = [:]

    // Set when using dev bypass (no real Supabase session)
    var devUserId: UUID?

    var currentUserTeeTimes: [TeeTime] {
        guard let user = currentUser else { return [] }
        return teeTimes.filter { $0.hostId == user.id || $0.players.contains(user.id) }
    }

    var friendIds: Set<UUID> {
        guard let me = currentUser else { return [] }
        return Set(friendships
            .filter { $0.status == .accepted }
            .map { $0.otherUserId(from: me.id) })
    }

    func friendshipStatus(with userId: UUID) -> FriendshipStatus? {
        guard let me = currentUser else { return nil }
        return friendships.first { $0.involves(me.id) && $0.involves(userId) }?.status
    }

    func isFriendRequestSentByMe(to userId: UUID) -> Bool {
        guard let me = currentUser else { return false }
        return friendships.first { $0.requesterId == me.id && $0.addresseeId == userId } != nil
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
            await fetchFriendships(userId: userId)
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
            var user = row.toUser()
            if let urlStr = row.avatarUrl, let url = URL(string: urlStr),
               let (data, _) = try? await URLSession.shared.data(from: url) {
                user.avatarImageData = data
            }
            currentUser = user
            profileCache[userId] = user
            isOnboarded = true
        } catch {
            // Profile doesn't exist yet — user needs onboarding
            isOnboarded = false
        }
    }

    func fetchTeeTimes() async {
        if devUserId != nil {
            teeTimes = TeeTime.mockData
            for u in User.mockUsers { profileCache[u.id] = u }
            return
        }
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
            let hostedIds = teeTimes.filter { $0.hostId == userId }.map { $0.id.uuidString }
            let rows: [JoinRequestRow]
            if hostedIds.isEmpty {
                let response = try await supabase
                    .from("join_requests")
                    .select()
                    .eq("requester_id", value: userId)
                    .execute()
                rows = try decoder.decode([JoinRequestRow].self, from: response.data)
            } else {
                let response = try await supabase
                    .from("join_requests")
                    .select()
                    .or("requester_id.eq.\(userId),tee_time_id.in.(\(hostedIds.joined(separator: ",")))")
                    .execute()
                rows = try decoder.decode([JoinRequestRow].self, from: response.data)
            }
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

    func createProfile(name: String, username: String, handicap: Double, industry: String, pace: PacePref, homeCourse: String, avatarData: Data? = nil) async {
        guard let userId = (try? await supabase.auth.session.user.id) ?? devUserId else { return }

        // Dev bypass: skip Supabase, set user in-memory only
        if devUserId != nil {
            currentUser = User(
                id: userId,
                name: name,
                username: username,
                handicapIndex: handicap,
                industry: industry,
                pacePreference: pace,
                homeCourses: homeCourse.isEmpty ? [] : [homeCourse],
                avatarImageData: avatarData
            )
            profileCache[userId] = currentUser
            isOnboarded = true
            return
        }

        do {
            let body = ProfileInsert(
                id: userId,
                name: name,
                username: username,
                handicapIndex: handicap,
                industry: industry,
                pacePreference: pace.rawValue.lowercased(),
                homeCourses: homeCourse.isEmpty ? [] : [homeCourse]
            )
            let response = try await supabase
                .from("profiles")
                .upsert(body)
                .single()
                .execute()
            let row = try decoder.decode(ProfileRow.self, from: response.data)
            currentUser = row.toUser()
            profileCache[userId] = currentUser
            isOnboarded = true
            if let data = avatarData {
                await updateAvatar(data)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateProfile(name: String, username: String, handicap: Double, industry: String, pace: PacePref, homeCourse: String, avatarData: Data? = nil) async {
        guard var user = currentUser else { return }
        user.name = name
        user.username = username
        user.handicapIndex = handicap
        user.industry = industry
        user.pacePreference = pace
        user.homeCourses = homeCourse.isEmpty ? [] : [homeCourse]
        currentUser = user
        profileCache[user.id] = user

        if devUserId != nil {
            if let data = avatarData { await updateAvatar(data) }
            return
        }
        do {
            try await supabase
                .from("profiles")
                .update([
                    "name": name,
                    "username": username,
                    "handicap_index": String(handicap),
                    "industry": industry,
                    "pace_preference": pace.rawValue.lowercased(),
                    "home_courses": "{\(homeCourse)}"
                ])
                .eq("id", value: user.id)
                .execute()
            if let data = avatarData { await updateAvatar(data) }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteTeeTime(id: UUID) async {
        teeTimes.removeAll { $0.id == id }
        guard devUserId == nil else { return }
        _ = try? await supabase
            .from("tee_times")
            .update(["is_active": false])
            .eq("id", value: id)
            .execute()
    }

    func updateTeeTime(_ teeTime: TeeTime) async {
        if let idx = teeTimes.firstIndex(where: { $0.id == teeTime.id }) {
            teeTimes[idx] = teeTime
        }
        guard devUserId == nil else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        _ = try? await supabase
            .from("tee_times")
            .update([
                "open_spots": String(teeTime.openSpots),
                "total_spots": String(teeTime.totalSpots),
                "tee_time": teeTime.teeTimeString,
                "carry_mode": teeTime.carryMode.rawValue,
                "tees": teeTime.tees ?? "",
                "notes": teeTime.notes ?? ""
            ])
            .eq("id", value: teeTime.id)
            .execute()
    }

    func hostTeeTime(_ teeTime: TeeTime) async {
        guard let user = currentUser else { return }

        // Dev mode: add in-memory only
        if devUserId != nil {
            teeTimes.insert(teeTime, at: 0)
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        do {
            let body = TeeTimeInsert(
                hostId: user.id,
                courseName: teeTime.courseName,
                location: teeTime.courseLocation,
                teeDate: dateFormatter.string(from: teeTime.date),
                teeTime: teeTime.teeTimeString,
                openSpots: teeTime.openSpots,
                carryMode: teeTime.carryMode.rawValue.lowercased(),
                tees: teeTime.tees,
                notes: teeTime.notes
            )
            let response = try await supabase
                .from("tee_times")
                .insert(body)
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

        // Dev mode: add in-memory only
        if devUserId != nil {
            let req = JoinRequest(id: UUID(), teeTimeId: teeTime.id, requesterId: user.id, note: note, status: .pending, createdAt: Date())
            joinRequests.append(req)
            return
        }

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

    func submitScore(teeTimeId: UUID, score: Int) async {
        if let idx = teeTimes.firstIndex(where: { $0.id == teeTimeId }) {
            teeTimes[idx].score = score
        }
        guard devUserId == nil else { return }
        _ = try? await supabase
            .from("tee_times")
            .update(["score": score])
            .eq("id", value: teeTimeId)
            .execute()
    }

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

    func updateAvatar(_ data: Data) async {
        guard let user = currentUser else { return }
        currentUser?.avatarImageData = data
        profileCache[user.id]?.avatarImageData = data
        guard devUserId == nil else { return }
        let path = "\(user.id.uuidString)/avatar.jpg"
        do {
            _ = try await supabase.storage
                .from("avatars")
                .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
            let avatarURL = try supabase.storage.from("avatars").getPublicURL(path: path)
            try await supabase
                .from("profiles")
                .update(["avatar_url": avatarURL.absoluteString])
                .eq("id", value: user.id)
                .execute()
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
            var user = row.toUser()
            if let urlStr = row.avatarUrl, let url = URL(string: urlStr),
               let (data, _) = try? await URLSession.shared.data(from: url) {
                user.avatarImageData = data
            }
            profileCache[userId] = user
        } catch { }
    }

    func checkPendingRatingPrompts(userId: UUID) {
        pendingRatingPrompts = teeTimes.filter {
            ($0.players.contains(userId) || $0.hostId == userId) && $0.date < Date()
        }
    }

    // MARK: - Friends

    func fetchFriendships(userId: UUID) async {
        if devUserId != nil {
            // Seed Marcus as a friend for demo
            let f = Friendship(id: UUID(), requesterId: userId, addresseeId: User.marcusR.id, status: .accepted, createdAt: Date())
            friendships = [f]
            return
        }
        do {
            let response = try await supabase
                .from("friendships")
                .select()
                .or("requester_id.eq.\(userId),addressee_id.eq.\(userId)")
                .execute()
            let rows = try decoder.decode([FriendshipRow].self, from: response.data)
            friendships = rows.map { $0.toFriendship() }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func sendFriendRequest(to userId: UUID) async {
        guard let me = currentUser else { return }
        // Dev mode: add in-memory
        if devUserId != nil {
            let f = Friendship(id: UUID(), requesterId: me.id, addresseeId: userId, status: .pending, createdAt: Date())
            friendships.append(f)
            return
        }
        do {
            let response = try await supabase
                .from("friendships")
                .insert(["requester_id": me.id.uuidString, "addressee_id": userId.uuidString])
                .single()
                .execute()
            let row = try decoder.decode(FriendshipRow.self, from: response.data)
            friendships.append(row.toFriendship())
        } catch {
            self.error = error.localizedDescription
        }
    }

    func acceptFriendRequest(from userId: UUID) async {
        guard let friendship = friendships.first(where: {
            $0.requesterId == userId && $0.status == .pending
        }) else { return }
        if devUserId != nil {
            if let idx = friendships.firstIndex(where: { $0.id == friendship.id }) {
                friendships[idx].status = .accepted
            }
            return
        }
        do {
            try await supabase
                .from("friendships")
                .update(["status": "accepted"])
                .eq("id", value: friendship.id)
                .execute()
            if let idx = friendships.firstIndex(where: { $0.id == friendship.id }) {
                friendships[idx].status = .accepted
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeFriend(_ userId: UUID) async {
        guard let me = currentUser else { return }
        guard let friendship = friendships.first(where: { $0.involves(me.id) && $0.involves(userId) }) else { return }
        if devUserId != nil {
            friendships.removeAll { $0.id == friendship.id }
            return
        }
        do {
            try await supabase
                .from("friendships")
                .delete()
                .eq("id", value: friendship.id)
                .execute()
            friendships.removeAll { $0.id == friendship.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Helpers

    func searchUsers(query: String) async -> [User] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        if devUserId != nil {
            let lower = q.lowercased()
            return User.mockUsers.filter {
                $0.name.lowercased().contains(lower) || $0.username.lowercased().contains(lower)
            }
        }
        do {
            let response = try await supabase
                .from("profiles")
                .select()
                .or("name.ilike.%\(q)%,username.ilike.%\(q)%")
                .limit(20)
                .execute()
            let rows = try decoder.decode([ProfileRow].self, from: response.data)
            let users = rows.map { $0.toUser() }
            for u in users { profileCache[u.id] = u }
            return users
        } catch {
            return []
        }
    }

    func fetchRoundsForUser(userId: UUID) async -> [TeeTime] {
        if devUserId != nil {
            return TeeTime.mockData.filter {
                ($0.hostId == userId || $0.players.contains(userId)) && $0.isCompleted
            }
        }
        do {
            let hostedResp = try await supabase
                .from("tee_times")
                .select()
                .eq("host_id", value: userId)
                .order("tee_date", ascending: false)
                .limit(10)
                .execute()
            let hostedRows = (try? decoder.decode([TeeTimeRow].self, from: hostedResp.data)) ?? []

            let reqResp = try await supabase
                .from("join_requests")
                .select()
                .eq("requester_id", value: userId)
                .eq("status", value: "approved")
                .execute()
            let reqRows = (try? decoder.decode([JoinRequestRow].self, from: reqResp.data)) ?? []
            let joinedIds = reqRows.map { $0.teeTimeId.uuidString }

            var joinedTeeTimes: [TeeTime] = []
            if !joinedIds.isEmpty {
                let joinedResp = try await supabase
                    .from("tee_times")
                    .select()
                    .in("id", values: joinedIds)
                    .order("tee_date", ascending: false)
                    .limit(10)
                    .execute()
                let joinedRows = (try? decoder.decode([TeeTimeRow].self, from: joinedResp.data)) ?? []
                joinedTeeTimes = joinedRows.map { $0.toTeeTime() }
            }

            return (hostedRows.map { $0.toTeeTime() } + joinedTeeTimes)
                .filter { $0.isCompleted }
                .sorted { $0.date > $1.date }
                .prefix(10)
                .map { $0 }
        } catch {
            return []
        }
    }

    func user(for id: UUID) -> User? {
        if currentUser?.id == id { return currentUser }
        return profileCache[id]
    }

    func teeTime(for id: UUID) -> TeeTime? {
        teeTimes.first(where: { $0.id == id })
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
