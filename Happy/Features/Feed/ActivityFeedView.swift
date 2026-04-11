import SwiftUI

struct ActivityFeedView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HappySectionLabel(text: "Happy Golf")
                    Text("Activity")
                        .font(HappyFont.displayHeadline(size: 34))
                        .foregroundColor(.happyGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, HappySpacing.xl)
                .padding(.top, HappySpacing.xl)
                .padding(.bottom, HappySpacing.md)
                .background(Color.happyCream)

                if appState.activityEvents.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(appState.activityEvents) { event in
                                ActivityEventRow(event: event)
                                if event.id != appState.activityEvents.last?.id {
                                    HappyDivider()
                                        .padding(.leading, 68)
                                }
                            }
                        }
                        .background(Color.happyWhite)
                        .cornerRadius(HappyRadius.cardLarge)
                        .overlay(
                            RoundedRectangle(cornerRadius: HappyRadius.cardLarge)
                                .stroke(Color.happySandLight, lineWidth: 1)
                        )
                        .shadow(color: Color.happyGreen.opacity(0.06), radius: 16, y: 4)
                        .padding(.horizontal, HappySpacing.xl)
                        .padding(.top, HappySpacing.md)
                        .padding(.bottom, HappySpacing.section)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: HappySpacing.md) {
            Spacer()
            Text("⛳")
                .font(.system(size: 52))
            Text("No activity yet.")
                .font(HappyFont.displayMedium(size: 24))
                .foregroundColor(.happyGreen)
            Text("Host or join a round to get started.")
                .font(HappyFont.bodyLight())
                .foregroundColor(.happyMuted)
            Spacer()
        }
    }
}

// MARK: - Activity Event Row

struct ActivityEventRow: View {
    let event: ActivityEvent
    @EnvironmentObject var appState: AppState

    private var actor: User? { appState.user(for: event.actorId) }
    private var teeTime: TeeTime? { event.teeTimeId.flatMap { appState.teeTime(for: $0) } }

    var body: some View {
        HStack(alignment: .top, spacing: HappySpacing.md) {
            // Icon bubble
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 42, height: 42)
                Text(event.icon)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(headline)
                    .font(HappyFont.bodyMedium(size: 14))
                    .foregroundColor(.happyBlack)
                    .lineLimit(2)

                if let tt = teeTime {
                    Text(tt.courseName)
                        .font(HappyFont.metaSmall)
                        .foregroundColor(.happyGreen)
                }

                Text(event.createdAt.relativeString)
                    .font(HappyFont.metaTiny)
                    .foregroundColor(.happyMuted)
            }

            Spacer()
        }
        .padding(.horizontal, HappySpacing.md)
        .padding(.vertical, HappySpacing.md)
    }

    private var headline: String {
        let name = actor?.name ?? "Someone"
        switch event.type {
        case .newTeeTime:   return "\(name) posted a new tee time"
        case .requestSent:  return "\(name) requested to join"
        case .approved:     return "\(name) was approved"
        case .declined:     return "\(name)'s request was declined"
        }
    }

    private var iconColor: Color {
        switch event.type {
        case .newTeeTime:   return .happyGreen
        case .requestSent:  return .happyAccent
        case .approved:     return .happyGreenLight
        case .declined:     return .happySand
        }
    }
}

// MARK: - Date helper

private extension Date {
    var relativeString: String {
        let diff = Date().timeIntervalSince(self)
        if diff < 60      { return "Just now" }
        if diff < 3600    { return "\(Int(diff / 60))m ago" }
        if diff < 86400   { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }
}

#Preview {
    ActivityFeedView()
        .environmentObject(AppState())
}
