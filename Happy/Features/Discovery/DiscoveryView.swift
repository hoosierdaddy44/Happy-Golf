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

    private var visibleRounds: [TeeTime] {
        let cal = Calendar.current
        let now = Date()
        return appState.teeTimes.filter { tt in
            guard !tt.isFull else { return false }
            if let user = appState.currentUser, tt.hostId == user.id { return false }
            switch filter {
            case .all:   return true
            case .today: return cal.isDateInToday(tt.date)
            case .week:  return tt.date <= cal.date(byAdding: .day, value: 7, to: now)!
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.happyCream.ignoresSafeArea()

                VStack(spacing: 0) {
                    navHeader

                    if visibleRounds.isEmpty {
                        emptyState
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: HappySpacing.md) {
                                ForEach(visibleRounds) { tt in
                                    TeeTimeCard(teeTime: tt)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedTeeTime = tt }
                                }
                            }
                            .padding(.horizontal, HappySpacing.xl)
                            .padding(.top, HappySpacing.md)
                            .padding(.bottom, HappySpacing.section)
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedTeeTime) { tt in
                TeeTimeDetailView(teeTime: tt)
            }
        }
    }

    // MARK: - Nav Header

    private var navHeader: some View {
        VStack(alignment: .leading, spacing: HappySpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HappySectionLabel(text: "Happy Golf")
                    Text("Open Rounds")
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

            // Filters
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

    private var emptyState: some View {
        VStack(spacing: HappySpacing.md) {
            Spacer()
            Text("⛳")
                .font(.system(size: 52))
            Text("No open rounds")
                .font(HappyFont.displayMedium(size: 24))
                .foregroundColor(.happyGreen)
            Text("Be the first to host one.")
                .font(HappyFont.bodyLight())
                .foregroundColor(.happyMuted)
            Spacer()
        }
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

                // Gold tag
                HappyBadge(text: "⛳ Happy Round", style: .gold)
                    .padding(.bottom, HappySpacing.md)

                // Course + spots
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

                // Meta
                HStack(spacing: HappySpacing.md) {
                    HappyMetaItem(emoji: "📅", label: teeTime.dateDisplay)
                    HappyMetaItem(emoji: "⏰", label: teeTime.teeTimeString)
                    HappyMetaItem(emoji: teeTime.carryMode.emoji, label: teeTime.carryMode.rawValue)
                    Spacer()
                }
                .padding(.bottom, HappySpacing.md)

                // Host row
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

            // Signature top gradient bar
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
            s.createProfile(name: "Alex S.", handicap: 12.0, industry: "Tech", pace: .fast, homeCourse: "Bethpage")
            return s
        }())
}
