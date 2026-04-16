import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var appState: AppState
    @State private var discoverTab = 0
    @State private var filter: DateFilter = .all
    @State private var selectedTeeTime: TeeTime?
    @State private var showPlayerSearch = false

    enum DateFilter: String, CaseIterable {
        case all   = "All"
        case today = "Today"
        case week  = "This Week"
    }

    private func filtered(_ rounds: [TeeTime]) -> [TeeTime] {
        let cal = Calendar.current
        let now = Date()
        return rounds.filter { tt in
            switch filter {
            case .all:   return true
            case .today: return cal.isDateInToday(tt.date)
            case .week:  return tt.date <= cal.date(byAdding: .day, value: 7, to: now)!
            }
        }
    }

    private var openRounds: [TeeTime] {
        guard let me = appState.currentUser else { return [] }
        return appState.teeTimes.filter { !$0.isFull && $0.hostId != me.id }
    }

    private var friendRounds: [TeeTime] {
        let ids = appState.friendIds
        return filtered(openRounds.filter { ids.contains($0.hostId) || $0.players.contains(where: { ids.contains($0) }) })
    }

    private var forYouRounds: [TeeTime] {
        let ids = appState.friendIds
        let me = appState.currentUser
        return filtered(openRounds.filter { tt in
            guard !ids.contains(tt.hostId) && !tt.players.contains(where: { ids.contains($0) }) else { return false }
            if let me = me, let host = appState.profileCache[tt.hostId] {
                return abs(host.handicapIndex - me.handicapIndex) <= 6
            }
            return true
        })
    }

    private var completedRounds: [TeeTime] {
        appState.teeTimes
            .filter { $0.isCompleted }
            .sorted { $0.date > $1.date }
            .prefix(10)
            .map { $0 }
    }

    private var friendsEmptyState: some View {
        HStack(spacing: HappySpacing.md) {
            Image(systemName: "person.2")
                .font(.system(size: 22))
                .foregroundColor(.happySand)
            VStack(alignment: .leading, spacing: 3) {
                Text("No friends' rounds yet.")
                    .font(HappyFont.bodyMedium(size: 13))
                    .foregroundColor(.happyBlack)
                Text("Join a round below to meet members and grow your network.")
                    .font(HappyFont.bodyLight(size: 12))
                    .foregroundColor(.happyMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(HappySpacing.md)
        .background(Color.happyWhite)
        .cornerRadius(HappyRadius.card)
        .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.happyCream.ignoresSafeArea()

                VStack(spacing: 0) {
                    navHeader

                    if discoverTab == 0 {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                                // Friends' Rounds
                                Section {
                                    if friendRounds.isEmpty {
                                        friendsEmptyState
                                            .padding(.horizontal, HappySpacing.xl)
                                            .padding(.bottom, HappySpacing.md)
                                    } else {
                                        ForEach(friendRounds) { tt in
                                            TeeTimeCard(teeTime: tt)
                                                .padding(.horizontal, HappySpacing.xl)
                                                .padding(.bottom, HappySpacing.md)
                                                .contentShape(Rectangle())
                                                .onTapGesture { selectedTeeTime = tt }
                                        }
                                    }
                                } header: {
                                    sectionHeader("Friends' Rounds", icon: "person.2.fill")
                                }

                                // Open Rounds
                                Section {
                                    if forYouRounds.isEmpty {
                                        Text("No open rounds right now.")
                                            .font(HappyFont.bodyLight(size: 14))
                                            .foregroundColor(.happyMuted)
                                            .italic()
                                            .padding(.horizontal, HappySpacing.xl)
                                            .padding(.bottom, HappySpacing.md)
                                    } else {
                                        ForEach(forYouRounds) { tt in
                                            TeeTimeCard(teeTime: tt)
                                                .padding(.horizontal, HappySpacing.xl)
                                                .padding(.bottom, HappySpacing.md)
                                                .contentShape(Rectangle())
                                                .onTapGesture { selectedTeeTime = tt }
                                        }
                                    }
                                } header: {
                                    sectionHeader("Expand Your Network", icon: "magnifyingglass")
                                }

                                // Recently Played
                                if !completedRounds.isEmpty {
                                    Section {
                                        ForEach(completedRounds) { tt in
                                            CompletedRoundCard(teeTime: tt)
                                                .padding(.horizontal, HappySpacing.xl)
                                                .padding(.bottom, HappySpacing.sm)
                                        }
                                    } header: {
                                        sectionHeader("Recently Played", icon: "flag.checkered")
                                    }
                                }

                                Spacer().frame(height: HappySpacing.section)
                            }
                            .padding(.top, HappySpacing.md)
                        }
                        .refreshable { await appState.refresh() }
                    } else {
                        ActivityFeedView()
                            .environmentObject(appState)
                    }
                }
            }
            .navigationDestination(item: $selectedTeeTime) { tt in
                TeeTimeDetailView(teeTime: tt)
            }
            .sheet(isPresented: $showPlayerSearch) {
                PlayerSearchView().environmentObject(appState)
            }
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: HappySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.happyGreenLight)
            Text(title.uppercased())
                .font(HappyFont.formLabel)
                .tracking(1.4)
                .foregroundColor(.happyGreenLight)
            Spacer()
        }
        .padding(.horizontal, HappySpacing.xl)
        .padding(.vertical, HappySpacing.sm)
        .background(Color.happyCream)
    }

    private var navHeader: some View {
        VStack(alignment: .leading, spacing: HappySpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HappySectionLabel(text: "Happy Golf")
                    Text("Discover")
                        .font(HappyFont.displayHeadline(size: 34))
                        .foregroundColor(.happyGreen)
                }
                Spacer()
                Button { showPlayerSearch = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14, weight: .medium))
                        Text("Find Players")
                            .font(HappyFont.bodyMedium(size: 13))
                    }
                    .foregroundColor(.happyGreen)
                    .padding(.horizontal, HappySpacing.md)
                    .padding(.vertical, 8)
                    .background(Color.happyWhite)
                    .cornerRadius(HappyRadius.pill)
                    .overlay(Capsule().stroke(Color.happySand, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // Segmented control
            HStack(spacing: 2) {
                segmentBtn("Rounds", index: 0)
                segmentBtn("Activity", index: 1)
            }
            .padding(3)
            .background(Color.happySandLight.opacity(0.6))
            .cornerRadius(HappyRadius.input + 3)

            if discoverTab == 0 {
                HStack(spacing: HappySpacing.xs) {
                    ForEach(DateFilter.allCases, id: \.self) { f in
                        filterPill(f)
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, HappySpacing.xl)
        .padding(.top, HappySpacing.xl)
        .padding(.bottom, HappySpacing.md)
        .background(Color.happyCream)
    }

    private func segmentBtn(_ title: String, index: Int) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { discoverTab = index }
        } label: {
            Text(title)
                .font(HappyFont.bodyMedium(size: 13))
                .foregroundColor(discoverTab == index ? .happyCream : .happyMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(discoverTab == index ? Color.happyGreen : Color.clear)
                .cornerRadius(HappyRadius.input)
        }
        .buttonStyle(.plain)
    }

    private func filterPill(_ f: DateFilter) -> some View {
        let selected = filter == f
        return Button {
            withAnimation(.easeOut(duration: 0.2)) { filter = f }
        } label: {
            Text(f.rawValue)
                .font(HappyFont.bodyMedium(size: 11))
                .tracking(0.5)
                .foregroundColor(selected ? .happyCream : .happyGreen)
                .padding(.vertical, 7)
                .padding(.horizontal, 16)
                .background(selected ? Color.happyGreen : Color.happyWhite)
                .overlay(Capsule().stroke(selected ? Color.clear : Color.happySand, lineWidth: 1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

}

// MARK: - Round Card

struct TeeTimeCard: View {
    let teeTime: TeeTime
    @EnvironmentObject var appState: AppState

    private var host: User? { appState.user(for: teeTime.hostId) }
    private var confirmedUsers: [User] {
        teeTime.confirmedPlayerIds.compactMap { appState.user(for: $0) }
    }
    private var hasFriend: Bool {
        let friends = appState.friendIds
        return friends.contains(teeTime.hostId) || teeTime.players.contains(where: { friends.contains($0) })
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                // Top row: badge + friend indicator + spots
                HStack {
                    HappyBadge(text: "⛳ Happy Round", style: .gold)
                    if hasFriend {
                        HappyBadge(text: "🤝 Friend", style: .friend)
                    }
                    Spacer()
                    HappySpotsBadge(count: teeTime.openSpots)
                }
                .padding(.bottom, HappySpacing.md)

                VStack(alignment: .leading, spacing: 3) {
                    Text(teeTime.courseName)
                        .font(HappyFont.cardTitle)
                        .foregroundColor(.happyGreen)
                    Text(teeTime.courseLocation)
                        .font(HappyFont.metaSmall)
                        .foregroundColor(.happyMuted)
                }
                .padding(.bottom, HappySpacing.md)

                HappyDivider()
                    .padding(.bottom, HappySpacing.md)

                HStack(spacing: HappySpacing.md) {
                    HappyMetaItem(emoji: "📅", label: teeTime.dateDisplay)
                    HappyMetaItem(emoji: "⏰", label: teeTime.teeTimeString)
                    HappyMetaItem(emoji: teeTime.carryMode.emoji, label: teeTime.carryMode.rawValue)
                    Spacer()
                }
                .padding(.bottom, HappySpacing.md)

                HappyDivider()
                    .padding(.bottom, HappySpacing.md)

                // Players row
                HStack(spacing: 8) {
                    StackedAvatars(users: confirmedUsers, size: 28)
                    if let host = host {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(host.name)
                                .font(HappyFont.bodyMedium(size: 12))
                                .foregroundColor(.happyBlack)
                            Text("HCP \(host.handicapDisplay) · \(host.pacePreference.rawValue)")
                                .font(HappyFont.metaTiny)
                                .foregroundColor(.happyMuted)
                        }
                    }
                    Spacer()
                    Text("View Round →")
                        .font(HappyFont.bodyMedium(size: 12))
                        .foregroundColor(.happyGreen)
                }
            }
            .padding(HappySpacing.xl)
            .background(Color.happyWhite)
            .cornerRadius(HappyRadius.cardLarge)
            .overlay(
                RoundedRectangle(cornerRadius: HappyRadius.cardLarge)
                    .stroke(Color.happySandLight, lineWidth: 1)
            )
            .shadow(color: Color.happyGreen.opacity(0.07), radius: 20, y: 8)

            HappyGradient.cardTopBar
                .frame(height: 3)
                .cornerRadius(HappyRadius.cardLarge, corners: [.topLeft, .topRight])
        }
    }
}

// MARK: - Stacked Avatars

struct StackedAvatars: View {
    let users: [User]
    let size: CGFloat
    private let maxVisible = 4
    private let overlap: CGFloat = 10

    var body: some View {
        let visible = Array(users.prefix(maxVisible))
        let extra = users.count - maxVisible

        HStack(spacing: 0) {
            ZStack {
                ForEach(Array(visible.enumerated()), id: \.element.id) { idx, user in
                    HappyAvatar(user: user, size: size)
                        .overlay(Circle().stroke(Color.happyWhite, lineWidth: 1.5))
                        .offset(x: CGFloat(idx) * (size - overlap))
                }
                if extra > 0 {
                    Text("+\(extra)")
                        .font(HappyFont.bodyMedium(size: 9))
                        .foregroundColor(.happyWhite)
                        .frame(width: size, height: size)
                        .background(Color.happyGreenLight)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.happyWhite, lineWidth: 1.5))
                        .offset(x: CGFloat(visible.count) * (size - overlap))
                }
            }
            .frame(width: size + CGFloat(min(users.count, maxVisible + 1) - 1) * (size - overlap), height: size)
        }
    }
}

// MARK: - Completed Round Card

struct CompletedRoundCard: View {
    let teeTime: TeeTime
    @EnvironmentObject var appState: AppState

    private var host: User? { appState.user(for: teeTime.hostId) }
    private var confirmedUsers: [User] {
        teeTime.confirmedPlayerIds.compactMap { appState.user(for: $0) }
    }

    var body: some View {
        HStack(spacing: HappySpacing.md) {
            StackedAvatars(users: confirmedUsers, size: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(teeTime.courseName)
                    .font(HappyFont.bodyMedium(size: 14))
                    .foregroundColor(.happyBlack)
                HStack(spacing: 4) {
                    Text(teeTime.dateDisplay)
                        .font(HappyFont.metaTiny)
                        .foregroundColor(.happyMuted)
                    if let host = host {
                        Text("· \(host.name)")
                            .font(HappyFont.metaTiny)
                            .foregroundColor(.happyMuted)
                    }
                }
            }

            Spacer()

            if let score = teeTime.score {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(score)")
                        .font(HappyFont.displayMedium(size: 20))
                        .foregroundColor(.happyGreen)
                    Text("strokes")
                        .font(HappyFont.metaTiny)
                        .foregroundColor(.happyMuted)
                }
            } else {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 16))
                    .foregroundColor(.happySand)
            }
        }
        .padding(HappySpacing.md)
        .background(Color.happyWhite)
        .cornerRadius(HappyRadius.card)
        .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
    }
}

#Preview {
    DiscoveryView()
        .environmentObject({
            let s = AppState()
            s.currentUser = User.jamesK
            s.isOnboarded = true
            return s
        }())
}
