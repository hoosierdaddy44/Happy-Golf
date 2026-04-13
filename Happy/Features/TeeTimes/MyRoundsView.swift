import SwiftUI

struct MyRoundsView: View {
    @EnvironmentObject var appState: AppState
    @State private var tab = 0
    @State private var selectedMemberId: UUID?
    @State private var scoreSheetTeeTime: TeeTime?
    @State private var selectedTeeTime: TeeTime?

    private var hostedRounds: [TeeTime] {
        guard let user = appState.currentUser else { return [] }
        return appState.teeTimes.filter { $0.hostId == user.id }
    }

    private var joinedRounds: [TeeTime] {
        guard let user = appState.currentUser else { return [] }
        return appState.teeTimes.filter { $0.hostId != user.id && $0.players.contains(user.id) }
    }

    private var pendingRequests: [JoinRequest] { appState.pendingRequestsForHost }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: HappySpacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HappySectionLabel(text: "Happy Golf")
                            Text("My Rounds")
                                .font(HappyFont.displayHeadline(size: 34))
                                .foregroundColor(.happyGreen)
                        }
                        Spacer()
                    }

                    // Segmented control
                    HStack(spacing: 2) {
                        tabBtn("Hosting", index: 0, badge: pendingRequests.count)
                        tabBtn("Joined", index: 1, badge: 0)
                    }
                    .padding(3)
                    .background(Color.happySandLight.opacity(0.6))
                    .cornerRadius(HappyRadius.input + 3)
                }
                .padding(.horizontal, HappySpacing.xl)
                .padding(.top, HappySpacing.xl)
                .padding(.bottom, HappySpacing.md)
                .background(Color.happyCream)

                ScrollView(showsIndicators: false) {
                    if tab == 0 {
                        hostingTab
                    } else {
                        joinedTab
                    }
                }
            }
        }
        .sheet(item: Binding(
            get: { selectedMemberId.map { MemberIDWrapper(id: $0) } },
            set: { selectedMemberId = $0?.id }
        )) { wrapper in
            MemberProfileView(userId: wrapper.id).environmentObject(appState)
        }
        .sheet(item: $scoreSheetTeeTime) { tt in
            ScoreEntrySheet(teeTime: tt)
                .environmentObject(appState)
        }
        .sheet(item: $selectedTeeTime) { tt in
            TeeTimeDetailView(teeTime: tt)
                .environmentObject(appState)
        }
    }

    // MARK: - Hosting Tab

    private var hostingTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pending requests
            if !pendingRequests.isEmpty {
                VStack(alignment: .leading, spacing: HappySpacing.sm) {
                    HStack {
                        HappySectionLabel(text: "Pending Requests")
                        Spacer()
                        Text("\(pendingRequests.count)")
                            .font(HappyFont.bodyMedium(size: 11))
                            .foregroundColor(.happyCream)
                            .frame(width: 22, height: 22)
                            .background(Color.happyGreen)
                            .clipShape(Circle())
                    }
                    ForEach(pendingRequests) { req in
                        JoinRequestRowView(request: req) { id in selectedMemberId = id }
                    }
                }
                .padding(.horizontal, HappySpacing.xl)
                .padding(.top, HappySpacing.lg)
                .padding(.bottom, HappySpacing.md)

                HappyDivider()
                    .padding(.horizontal, HappySpacing.xl)
                    .padding(.vertical, HappySpacing.md)
            }

            // Hosted rounds list
            VStack(alignment: .leading, spacing: HappySpacing.sm) {
                HappySectionLabel(text: "Your Rounds")
                    .padding(.bottom, HappySpacing.xs)

                if hostedRounds.isEmpty {
                    emptyMessage("You haven't hosted a round yet.")
                } else {
                    ForEach(hostedRounds) { tt in
                        roundRow(tt, role: "Host")
                            .onTapGesture { selectedTeeTime = tt }
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { await appState.deleteTeeTime(id: tt.id) }
                                } label: {
                                    Label("Delete Round", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, HappySpacing.xl)
            .padding(.top, pendingRequests.isEmpty ? HappySpacing.lg : 0)
            .padding(.bottom, HappySpacing.section)
        }
    }

    // MARK: - Joined Tab

    private var joinedTab: some View {
        VStack(alignment: .leading, spacing: HappySpacing.sm) {
            if joinedRounds.isEmpty {
                emptyMessage("You haven't joined a round yet.")
                    .padding(.top, HappySpacing.section)
            } else {
                ForEach(joinedRounds) { tt in
                    roundRow(tt, role: "Confirmed")
                        .onTapGesture { selectedTeeTime = tt }
                }
            }
        }
        .padding(.horizontal, HappySpacing.xl)
        .padding(.top, HappySpacing.lg)
        .padding(.bottom, HappySpacing.section)
    }

    // MARK: - Sub-components

    private func roundRow(_ tt: TeeTime, role: String) -> some View {
        VStack(alignment: .leading, spacing: HappySpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tt.courseName)
                        .font(HappyFont.displayMedium(size: 18))
                        .foregroundColor(.happyGreen)
                    HStack(spacing: 6) {
                        Text(tt.dateDisplay)
                        Text("·")
                        Text(tt.teeTimeString)
                        if let tees = tt.tees {
                            Text("·")
                            Text(tees)
                        }
                    }
                    .font(HappyFont.metaSmall)
                    .foregroundColor(.happyMuted)
                }
                Spacer()
                if tt.isCompleted {
                    if let score = tt.score {
                        scoreDisplay(score: score)
                    } else {
                        Button { scoreSheetTeeTime = tt } label: {
                            Text("Log Score")
                                .font(HappyFont.bodyMedium(size: 11))
                                .foregroundColor(.happyGreen)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .overlay(Capsule().stroke(Color.happyGreen, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                } else if role == "Host" {
                    HappySpotsBadge(count: tt.openSpots)
                } else {
                    Text("Confirmed")
                        .font(HappyFont.bodyMedium(size: 11))
                        .foregroundColor(.happyGreenLight)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.happyGreenLight.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(HappySpacing.md)
        .background(Color.happyWhite)
        .cornerRadius(HappyRadius.card)
        .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
    }

    private func scoreDisplay(score: Int) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(score)")
                .font(HappyFont.displayMedium(size: 22))
                .foregroundColor(.happyGreen)
            if let me = appState.currentUser {
                let net = score - Int(me.handicapIndex)
                let diff = net - 72
                let diffStr = diff > 0 ? "+\(diff)" : "\(diff)"
                Text("Net \(net) (\(diffStr))")
                    .font(HappyFont.metaTiny)
                    .foregroundColor(.happyMuted)
            }
        }
    }

    private func emptyMessage(_ text: String) -> some View {
        Text(text)
            .font(HappyFont.bodyLight(size: 14))
            .foregroundColor(.happyMuted)
            .italic()
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tabBtn(_ title: String, index: Int, badge: Int) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { tab = index }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(HappyFont.bodyMedium(size: 13))
                    .foregroundColor(tab == index ? .happyCream : .happyMuted)
                if badge > 0 {
                    Text("\(badge)")
                        .font(HappyFont.bodyMedium(size: 10))
                        .foregroundColor(tab == index ? .happyGreen : .happyCream)
                        .frame(width: 18, height: 18)
                        .background(tab == index ? Color.happyCream : Color.happyGreen)
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(tab == index ? Color.happyGreen : Color.clear)
            .cornerRadius(HappyRadius.input)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Join Request Row (host view)

struct JoinRequestRowView: View {
    let request: JoinRequest
    var onTapProfile: ((UUID) -> Void)? = nil
    @EnvironmentObject var appState: AppState

    private var requester: User? { appState.user(for: request.requesterId) }
    private var teeTime: TeeTime? { appState.teeTime(for: request.teeTimeId) }

    var body: some View {
        if let user = requester {
            VStack(alignment: .leading, spacing: HappySpacing.sm) {
                HStack(spacing: HappySpacing.sm) {
                    Button { onTapProfile?(user.id) } label: {
                        HappyAvatar(user: user, size: 42)
                    }
                    .buttonStyle(.plain)
                    Button { onTapProfile?(user.id) } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(user.name)
                                .font(HappyFont.bodyMedium(size: 14))
                                .foregroundColor(.happyBlack)
                            if let tt = teeTime {
                                Text(tt.courseName)
                                    .font(HappyFont.metaTiny)
                                    .foregroundColor(.happyGreen)
                            }
                            Text("HCP \(user.handicapDisplay) · \(user.pacePreference.rawValue)")
                                .font(HappyFont.metaTiny)
                                .foregroundColor(.happyMuted)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }

                if let note = request.note, !note.isEmpty {
                    Text("\"\(note)\"")
                        .font(HappyFont.bodyLight(size: 13))
                        .foregroundColor(.happyMuted)
                        .italic()
                }

                HStack(spacing: HappySpacing.xs) {
                    HappyPrimaryButton(title: "Approve") {
                        Task { await appState.approveRequest(request) }
                    }
                    HappyOutlineButton(title: "Decline") {
                        Task { await appState.declineRequest(request) }
                    }
                }
            }
            .padding(HappySpacing.md)
            .background(Color.happyWhite)
            .cornerRadius(HappyRadius.card)
            .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
        }
    }
}

#Preview {
    MyRoundsView()
        .environmentObject({
            let s = AppState()
            s.currentUser = User.jamesK
            s.isOnboarded = true
            return s
        }())
}
