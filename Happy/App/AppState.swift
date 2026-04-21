import SwiftUI
import Supabase

@MainActor
class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var isOnboarded: Bool = false
    @Published var teeTimes: [TeeTime] = []
    @Published var joinRequests: [JoinRequest] = []
    @Published var activityEvents: [ActivityEvent] = []
    @Published var isLoading: Bool = true
    @Published var error: String?
    @Published var pendingRatingPrompts: [TeeTime] = []
    @Published var accolades: [UUID: [Accolade]] = [:]
    @Published var friendships: [Friendship] = []
    @Published var isApproved: Bool = false
    @Published var didJustApply: Bool = false
    @Published var groups: [HappyGroup] = []
    @Published var groupMembers: [UUID: [GroupMember]] = [:]

    // Tracks tee time IDs the user has already rated or dismissed
    private var dismissedRatingPromptIds: Set<UUID> {
        get {
            let stored = UserDefaults.standard.array(forKey: "dismissedRatingPromptIds") as? [String] ?? []
            return Set(stored.compactMap { UUID(uuidString: $0) })
        }
        set {
            UserDefaults.standard.set(newValue.map { $0.uuidString }, forKey: "dismissedRatingPromptIds")
        }
    }

    func dismissRatingPrompt(for id: UUID) {
        var ids = dismissedRatingPromptIds
        ids.insert(id)
        dismissedRatingPromptIds = ids
        pendingRatingPrompts.removeAll { $0.id == id }
    }

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

    func reset() {
        currentUser = nil
        isOnboarded = false
        isApproved = false
        isLoading = false
        didJustApply = false
        teeTimes = []
        joinRequests = []
        activityEvents = []
        pendingRatingPrompts = []
        accolades = [:]
        friendships = []
        groups = []
        groupMembers = [:]
        profileCache = [:]
        devUserId = nil
        error = nil
    }

    func load(userId: UUID) async {
        isLoading = true
        async let profileTask: () = fetchProfile(userId: userId)
        async let teeTimesTask: () = fetchTeeTimes()
        async let activityTask: () = fetchActivity()
        _ = await (profileTask, teeTimesTask, activityTask)
        if currentUser != nil {
            await fetchJoinRequests(userId: userId)
            await fetchFriendships(userId: userId)
            await fetchGroups(userId: userId)
            await fetchMyScores(userId: userId)
            checkPendingRatingPrompts(userId: userId)
            await fetchAccolades(for: userId)
            await checkApproval()
        }
        isLoading = false
    }

    func checkApproval() async {
        if devUserId != nil { isApproved = true; return }
        guard let userId = try? await supabase.auth.session.user.id else { return }
        do {
            let response = try await supabase
                .from("membership_requests")
                .select("status")
                .eq("user_id", value: userId)
                .single()
                .execute()
            struct StatusRow: Decodable { let status: String }
            let row = try JSONDecoder().decode(StatusRow.self, from: response.data)
            isApproved = row.status == "approved"
        } catch {
            let msg = error.localizedDescription
            // Only mark not-approved for definitive "no row" responses, not network errors
            if msg.contains("PGRST116") || msg.contains("JSON") || msg.contains("decode") {
                isApproved = false
            }
        }
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
            user.email = (try? await supabase.auth.session.user.email) ?? ""
            currentUser = user
            profileCache[userId] = user
            isOnboarded = true
        } catch {
            let msg = error.localizedDescription
            // PGRST116 = no rows returned — profile genuinely doesn't exist yet
            if msg.contains("PGRST116") || msg.contains("JSON") || msg.contains("decode") {
                isOnboarded = false
            }
            // Any other error (network, timeout, etc.) — don't reset onboarding state
            // so existing users aren't bounced back to profile setup on a bad connection
        }
    }

    func fetchTeeTimes() async {
        if let userId = devUserId {
            let now = Date()
            let cal = Calendar.current
            // Seed two upcoming hosted rounds for the dev user so edit/profile features work
            let devRounds: [TeeTime] = [
                TeeTime(
                    hostId: userId,
                    courseName: "Bethpage Black",
                    courseLocation: "Farmingdale, NY",
                    date: cal.date(byAdding: .day, value: 5, to: now)!,
                    teeTimeString: "8:00 AM",
                    openSpots: 2,
                    totalSpots: 3,
                    carryMode: .walking,
                    tees: "Blue"
                ),
                TeeTime(
                    hostId: userId,
                    courseName: "Winged Foot Golf Club",
                    courseLocation: "Mamaroneck, NY",
                    date: cal.date(byAdding: .day, value: 12, to: now)!,
                    teeTimeString: "7:30 AM",
                    openSpots: 1,
                    totalSpots: 4,
                    carryMode: .riding,
                    tees: "Championship"
                )
            ]
            teeTimes = devRounds + TeeTime.mockData
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
            isApproved = true
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
            didJustApply = true

            // Write profile info to membership_requests so admin can identify applicants
            struct MembershipUpdate: Encodable {
                let userId: UUID
                let name: String
                let username: String
                enum CodingKeys: String, CodingKey {
                    case userId = "user_id"
                    case name
                    case username
                }
            }
            _ = try? await supabase
                .from("membership_requests")
                .upsert(MembershipUpdate(userId: userId, name: name, username: username), onConflict: "user_id")
                .execute()

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

    func leaveRound(teeTimeId: UUID) async {
        guard let userId = currentUser?.id else { return }
        if let idx = teeTimes.firstIndex(where: { $0.id == teeTimeId }) {
            teeTimes[idx].players.removeAll { $0 == userId }
        }
        guard devUserId == nil else { return }
        _ = try? await supabase
            .from("join_requests")
            .update(["status": "withdrawn"])
            .eq("tee_time_id", value: teeTimeId.uuidString)
            .eq("requester_id", value: userId.uuidString)
            .execute()
    }

    func deleteAccount() async {
        guard let userId = currentUser?.id else { return }
        guard devUserId == nil else { return }
        _ = try? await supabase.from("profiles").delete().eq("id", value: userId.uuidString).execute()
        _ = try? await supabase.from("tee_times").update(["is_active": false]).eq("host_id", value: userId.uuidString).execute()
        _ = try? await supabase.auth.admin.deleteUser(id: userId.uuidString)
        try? await supabase.auth.signOut()
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
                "tee_date": dateFormatter.string(from: teeTime.date),
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
                groupId: teeTime.groupId,
                courseName: teeTime.courseName,
                location: teeTime.courseLocation,
                teeDate: dateFormatter.string(from: teeTime.date),
                teeTime: teeTime.teeTimeString,
                openSpots: teeTime.openSpots,
                carryMode: teeTime.carryMode.rawValue.lowercased(),
                format: teeTime.format.rawValue,
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
        guard let userId = currentUser?.id ?? devUserId else { return }
        if let idx = teeTimes.firstIndex(where: { $0.id == teeTimeId }) {
            teeTimes[idx].score = score
        }
        guard devUserId == nil else { return }
        let body = RoundScoreInsert(teeTimeId: teeTimeId, userId: userId, grossScore: score)
        _ = try? await supabase
            .from("round_scores")
            .upsert(body, onConflict: "tee_time_id,user_id")
            .execute()
    }

    func fetchMyScores(userId: UUID) async {
        guard devUserId == nil else { return }
        do {
            let resp = try await supabase
                .from("round_scores")
                .select()
                .eq("user_id", value: userId)
                .execute()
            let rows = try decoder.decode([RoundScoreRow].self, from: resp.data)
            for row in rows {
                if let idx = teeTimes.firstIndex(where: { $0.id == row.teeTimeId }) {
                    teeTimes[idx].score = row.grossScore
                }
            }
        } catch { }
    }

    func fetchRoundScores(teeTimeId: UUID) async -> [RoundScoreRow] {
        if devUserId != nil {
            // Return mock scores for each player on the round
            guard let tt = teeTimes.first(where: { $0.id == teeTimeId }) else { return [] }
            return tt.confirmedPlayerIds.enumerated().map { i, uid in
                RoundScoreRow(id: UUID(), teeTimeId: teeTimeId, userId: uid,
                             grossScore: 78 + i * 4, createdAt: Date())
            }
        }
        do {
            let resp = try await supabase
                .from("round_scores")
                .select()
                .eq("tee_time_id", value: teeTimeId)
                .execute()
            return (try? decoder.decode([RoundScoreRow].self, from: resp.data)) ?? []
        } catch { return [] }
    }

    func fetchScoreVerifications(teeTimeId: UUID) async -> [ScoreVerificationRow] {
        if devUserId != nil { return [] }
        do {
            let resp = try await supabase
                .from("score_verifications")
                .select()
                .eq("tee_time_id", value: teeTimeId)
                .execute()
            return (try? decoder.decode([ScoreVerificationRow].self, from: resp.data)) ?? []
        } catch { return [] }
    }

    func verifyScore(teeTimeId: UUID, playerId: UUID) async {
        guard let userId = currentUser?.id, devUserId == nil else { return }
        let body = ScoreVerificationInsert(teeTimeId: teeTimeId, playerId: playerId, verifierId: userId)
        _ = try? await supabase.from("score_verifications").insert(body).execute()
    }

    func transferOwnership(teeTimeId: UUID, newHostId: UUID) async {
        if devUserId != nil {
            if let idx = teeTimes.firstIndex(where: { $0.id == teeTimeId }) {
                teeTimes[idx].hostId = newHostId
            }
            return
        }
        do {
            try await supabase
                .from("tee_times")
                .update(["host_id": newHostId.uuidString])
                .eq("id", value: teeTimeId.uuidString)
                .execute()
            if let idx = teeTimes.firstIndex(where: { $0.id == teeTimeId }) {
                teeTimes[idx].hostId = newHostId
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func submitRating(teeTimeId: UUID, rateeId: UUID, score: Int) async {
        guard let user = currentUser else { return }
        dismissRatingPrompt(for: teeTimeId)
        if devUserId != nil { return }
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
        let dismissed = dismissedRatingPromptIds
        pendingRatingPrompts = teeTimes.filter {
            ($0.players.contains(userId) || $0.hostId == userId) &&
            $0.date < Date() &&
            !dismissed.contains($0.id)
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

    // MARK: - Groups

    func fetchGroups(userId: UUID) async {
        if devUserId != nil {
            groups = HappyGroup.mockGroups
            return
        }
        do {
            let memberResp = try await supabase
                .from("group_members")
                .select("group_id, role")
                .eq("user_id", value: userId)
                .execute()
            struct MembershipRow: Decodable {
                let groupId: UUID; let role: String
                enum CodingKeys: String, CodingKey { case groupId = "group_id"; case role }
            }
            let memberships = (try? JSONDecoder().decode([MembershipRow].self, from: memberResp.data)) ?? []

            let groupResp = try await supabase.from("groups").select().execute()
            let rows = try decoder.decode([GroupRow].self, from: groupResp.data)

            let countResp = try? await supabase.from("group_members").select("group_id").execute()
            struct CountRow: Decodable {
                let groupId: UUID
                enum CodingKeys: String, CodingKey { case groupId = "group_id" }
            }
            let countRows = (try? JSONDecoder().decode([CountRow].self, from: countResp?.data ?? Data())) ?? []
            var memberCounts: [UUID: Int] = [:]
            for r in countRows { memberCounts[r.groupId, default: 0] += 1 }

            let myRoleMap = Dictionary(uniqueKeysWithValues: memberships.map {
                ($0.groupId, GroupRole(rawValue: $0.role) ?? .member)
            })
            groups = rows.map { row in
                row.toGroup(memberCount: memberCounts[row.id] ?? 0, myRole: myRoleMap[row.id])
            }.sorted { $0.isMember && !$1.isMember }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createGroup(name: String, description: String, emoji: String, isPrivate: Bool) async {
        guard let userId = currentUser?.id ?? devUserId else { return }
        if devUserId != nil {
            let g = HappyGroup(id: UUID(), name: name, description: description, emoji: emoji,
                               createdBy: userId, isPrivate: isPrivate, createdAt: Date(),
                               memberCount: 1, myRole: .admin)
            groups.insert(g, at: 0)
            return
        }
        do {
            let body = GroupInsert(name: name, description: description, emoji: emoji,
                                   createdBy: userId, isPrivate: isPrivate)
            let resp = try await supabase.from("groups").insert(body).single().execute()
            let row = try decoder.decode(GroupRow.self, from: resp.data)
            let g = row.toGroup(memberCount: 1, myRole: .admin)
            groups.insert(g, at: 0)
            let memberBody = GroupMemberInsert(groupId: g.id, userId: userId, role: "admin")
            try? await supabase.from("group_members").insert(memberBody).execute()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func joinGroup(_ group: HappyGroup) async {
        guard let userId = currentUser?.id ?? devUserId else { return }
        if devUserId != nil {
            if let idx = groups.firstIndex(where: { $0.id == group.id }) {
                groups[idx].myRole = .member
                groups[idx].memberCount += 1
            }
            return
        }
        do {
            let body = GroupMemberInsert(groupId: group.id, userId: userId, role: "member")
            try await supabase.from("group_members").insert(body).execute()
            if let idx = groups.firstIndex(where: { $0.id == group.id }) {
                groups[idx].myRole = .member
                groups[idx].memberCount += 1
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func leaveGroup(_ group: HappyGroup) async {
        guard let userId = currentUser?.id ?? devUserId else { return }
        if devUserId != nil {
            if let idx = groups.firstIndex(where: { $0.id == group.id }) {
                groups[idx].myRole = nil
                groups[idx].memberCount = max(0, groups[idx].memberCount - 1)
            }
            return
        }
        do {
            try await supabase.from("group_members").delete()
                .eq("group_id", value: group.id).eq("user_id", value: userId).execute()
            if let idx = groups.firstIndex(where: { $0.id == group.id }) {
                groups[idx].myRole = nil
                groups[idx].memberCount = max(0, groups[idx].memberCount - 1)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func inviteMemberToGroup(userId: UUID, groupId: UUID) async {
        if devUserId != nil { return }
        do {
            let body = GroupMemberInsert(groupId: groupId, userId: userId, role: "member")
            try await supabase.from("group_members").insert(body).execute()
            if let idx = groups.firstIndex(where: { $0.id == groupId }) {
                groups[idx].memberCount += 1
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func fetchGroupMembers(groupId: UUID) async -> [GroupMember] {
        if let cached = groupMembers[groupId] { return cached }
        if devUserId != nil {
            let members = [
                GroupMember(id: UUID(), groupId: groupId, userId: User.jamesK.id, role: .admin, joinedAt: Date()),
                GroupMember(id: UUID(), groupId: groupId, userId: User.marcusR.id, role: .member, joinedAt: Date())
            ]
            groupMembers[groupId] = members
            return members
        }
        do {
            let resp = try await supabase.from("group_members").select()
                .eq("group_id", value: groupId).execute()
            let rows = try decoder.decode([GroupMemberRow].self, from: resp.data)
            let members = rows.map { $0.toGroupMember() }
            groupMembers[groupId] = members
            let ids = Set(members.map { $0.userId })
            await withTaskGroup(of: Void.self) { group in
                for id in ids { group.addTask { await self.fetchCachedProfile(userId: id) } }
            }
            return members
        } catch {
            self.error = error.localizedDescription
            return []
        }
    }

    func groupTeeTimes(groupId: UUID) -> [TeeTime] {
        teeTimes.filter { $0.groupId == groupId }
    }

    func searchGroups(query: String) async -> [HappyGroup] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        if devUserId != nil {
            let lower = q.lowercased()
            return HappyGroup.mockGroups.filter {
                $0.name.lowercased().contains(lower) ||
                $0.description.lowercased().contains(lower)
            }
        }
        do {
            guard let userId = currentUser?.id else { return [] }
            let resp = try await supabase
                .from("groups")
                .select()
                .ilike("name", value: "%\(q)%")
                .execute()
            let rows = try decoder.decode([GroupRow].self, from: resp.data)

            let memberResp = try? await supabase
                .from("group_members")
                .select("group_id, role")
                .eq("user_id", value: userId)
                .execute()
            struct MembershipRow: Decodable {
                let groupId: UUID; let role: String
                enum CodingKeys: String, CodingKey { case groupId = "group_id"; case role }
            }
            let memberships = (try? JSONDecoder().decode([MembershipRow].self, from: memberResp?.data ?? Data())) ?? []
            let myRoleMap = Dictionary(uniqueKeysWithValues: memberships.map {
                ($0.groupId, GroupRole(rawValue: $0.role) ?? .member)
            })
            return rows.map { row in
                row.toGroup(memberCount: 0, myRole: myRoleMap[row.id])
            }
        } catch {
            return []
        }
    }

    // MARK: - Refresh & Realtime

    func refresh() async {
        guard let userId = currentUser?.id ?? devUserId else { return }
        await load(userId: userId)
    }

    func subscribeToRealtime(userId: UUID) {
        guard devUserId == nil else { return }
        Task {
            let channel = supabase.channel("join-requests-\(userId.uuidString)")
            let changes = channel.postgresChange(AnyAction.self, schema: "public", table: "join_requests")
            await channel.subscribe()
            for await _ in changes {
                await fetchJoinRequests(userId: userId)
            }
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
            var users = rows.map { $0.toUser() }
            await withTaskGroup(of: (Int, Data?).self) { group in
                for (i, row) in rows.enumerated() {
                    if let urlStr = row.avatarUrl, let url = URL(string: urlStr) {
                        group.addTask {
                            let data = try? await URLSession.shared.data(from: url).0
                            return (i, data)
                        }
                    }
                }
                for await (i, data) in group {
                    users[i].avatarImageData = data
                }
            }
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
