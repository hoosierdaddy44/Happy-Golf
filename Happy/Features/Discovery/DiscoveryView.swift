import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var appState: AppState
    @State private var filter: DateFilter = .all
    @State private var selectedTeeTime: TeeTime?

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

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            // Friends' Rounds — always visible
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

                            // Open Rounds — expand your network
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

                            Spacer().frame(height: HappySpacing.section)
                        }
                        .padding(.top, HappySpacing.md)
                    }
                }
            }
            .navigationDestination(item: $selectedTeeTime) { tt in
                TeeTimeDetailView(teeTime: tt)
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
                ZStack {
                    RoundedRectangle(cornerRadius: HappyRadius.icon)
                        .fill(Color.happyGreen)
                        .frame(width: 38, height: 38)
                    Text("⛳")
                        .font(.system(size: 19))
                }
            }

            HStack(spacing: HappySpacing.xs) {
                ForEach(DateFilter.allCases, id: \.self) { f in
                    filterPill(f)
                }
                Spacer()
            }
        }
        .padding(.horizontal, HappySpacing.xl)
        .padding(.top, HappySpacing.xl)
        .padding(.bottom, HappySpacing.md)
        .background(Color.happyCream)
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

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                HappyBadge(text: "⛳ Happy Round", style: .gold)
                    .padding(.bottom, HappySpacing.md)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(teeTime.courseName)
                            .font(HappyFont.cardTitle)
                            .foregroundColor(.happyGreen)
                        Text(teeTime.courseLocation)
                            .font(HappyFont.metaSmall)
                            .foregroundColor(.happyMuted)
                    }
                    Spacer()
                    HappySpotsBadge(count: teeTime.openSpots)
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

                if let host = host {
                    HStack(spacing: 8) {
                        HappyAvatar(user: host, size: 26)
                        Text(host.name)
                            .font(HappyFont.bodyMedium(size: 12))
                            .foregroundColor(.happyBlack)
                        Text("· HCP \(host.handicapDisplay)")
                            .font(HappyFont.metaTiny)
                            .foregroundColor(.happyMuted)
                        Spacer()
                        Text("View Round →")
                            .font(HappyFont.bodyMedium(size: 12))
                            .foregroundColor(.happyGreen)
                    }
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

#Preview {
    DiscoveryView()
        .environmentObject({
            let s = AppState()
            s.currentUser = User.jamesK
            s.isOnboarded = true
            return s
        }())
}
