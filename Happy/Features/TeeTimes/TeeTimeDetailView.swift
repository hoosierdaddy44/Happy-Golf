import SwiftUI

struct TeeTimeDetailView: View {
    let teeTime: TeeTime
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var showJoinSheet = false

    private var host: User? { appState.user(for: teeTime.hostId) }
    private var confirmedPlayers: [User] { teeTime.confirmedPlayerIds.compactMap { appState.user(for: $0) } }
    private var isCurrentUserHost: Bool { appState.currentUser?.id == teeTime.hostId }
    private var existingRequest: JoinRequest? {
        guard let user = appState.currentUser else { return nil }
        return appState.joinRequests.first { $0.teeTimeId == teeTime.id && $0.requesterId == user.id }
    }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    roundCard
                    ctaSection
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showJoinSheet) {
            JoinRequestSheet(teeTime: teeTime)
        }
    }

    // MARK: - Round Card

    private var roundCard: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                HappyBadge(text: "⛳ Happy Round", style: .gold)
                    .padding(.bottom, HappySpacing.md)

                // Course + spots
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(teeTime.courseName)
                            .font(HappyFont.displayHeadline(size: 28))
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
                    .padding(.bottom, HappySpacing.lg)

                // Meta
                HStack(spacing: HappySpacing.md) {
                    HappyMetaItem(emoji: "📅", label: teeTime.dateDisplay)
                    HappyMetaItem(emoji: "⏰", label: teeTime.teeTimeString)
                    HappyMetaItem(emoji: teeTime.carryMode.emoji, label: teeTime.carryMode.rawValue)
                }
                .padding(.bottom, HappySpacing.xl)

                // Players label
                Text("Players".uppercased())
                    .font(HappyFont.formLabel)
                    .tracking(1.2)
                    .foregroundColor(.happyMuted)
                    .padding(.bottom, HappySpacing.sm)

                // Confirmed players
                VStack(spacing: HappySpacing.sm) {
                    ForEach(confirmedPlayers) { player in
                        playerRow(player)
                    }
                    // Open spots
                    ForEach(0..<teeTime.openSpots, id: \.self) { _ in
                        openSpotRow
                    }
                }

                // Notes
                if let notes = teeTime.notes, !notes.isEmpty {
                    HappyDivider()
                        .padding(.vertical, HappySpacing.md)
                    Text(notes)
                        .font(HappyFont.bodyLight(size: 13))
                        .foregroundColor(.happyMuted)
                        .italic()
                }
            }
            .padding(HappySpacing.xl)
            .background(Color.happyWhite)
            .cornerRadius(HappyRadius.cardLarge)
            .overlay(
                RoundedRectangle(cornerRadius: HappyRadius.cardLarge)
                    .stroke(Color.happySandLight, lineWidth: 1)
            )
            .shadow(color: Color.happyGreen.opacity(0.08), radius: 24, y: 8)

            HappyGradient.cardTopBar
                .frame(height: 3)
                .cornerRadius(HappyRadius.cardLarge, corners: [.topLeft, .topRight])
        }
        .padding(.horizontal, HappySpacing.xl)
        .padding(.top, HappySpacing.xl)
    }

    private func playerRow(_ player: User) -> some View {
        HStack(spacing: 11) {
            HappyAvatar(user: player, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(player.name)
                        .font(HappyFont.bodyMedium(size: 13))
                        .foregroundColor(.happyBlack)
                    if player.id == teeTime.hostId {
                        Text("· Host")
                            .font(HappyFont.bodyLight(size: 11))
                            .foregroundColor(.happyMuted)
                    }
                }
                Text("Handicap \(player.handicapDisplay)")
                    .font(HappyFont.metaTiny)
                    .foregroundColor(.happyMuted)
            }
            Spacer()
            Text(player.pacePreference.rawValue)
                .font(HappyFont.bodyMedium(size: 10))
                .tracking(0.7)
                .foregroundColor(.happyGreenLight)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(Color.happyGreenLight.opacity(0.08))
                .overlay(Capsule().stroke(Color.happyGreenLight.opacity(0.15), lineWidth: 1))
                .clipShape(Capsule())
        }
    }

    private var openSpotRow: some View {
        HStack(spacing: 11) {
            OpenSpotAvatar(size: 38)
            Text("Open — waiting for the right fit")
                .font(HappyFont.bodyLight(size: 13))
                .foregroundColor(.happyMuted)
                .italic()
            Spacer()
        }
    }

    // MARK: - CTA

    @ViewBuilder
    private var ctaSection: some View {
        if !isCurrentUserHost {
            VStack(spacing: HappySpacing.sm) {
                if teeTime.isFull {
                    Text("Round is full")
                        .font(HappyFont.buttonLabel)
                        .foregroundColor(.happyMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.happySandLight)
                        .clipShape(Capsule())
                } else if let req = existingRequest {
                    switch req.status {
                    case .pending:
                        statusPill(icon: "clock", label: "Request Sent", color: .happyMuted)
                    case .approved:
                        statusPill(icon: "checkmark", label: "You're In", color: .happyGreenLight)
                    case .declined:
                        statusPill(icon: "xmark", label: "Not This Time", color: .happySand)
                    }
                } else {
                    HappyPrimaryButton(title: "Request to Join →", fullWidth: true) {
                        showJoinSheet = true
                    }
                }
            }
            .padding(.horizontal, HappySpacing.xl)
            .padding(.top, HappySpacing.xl)
            .padding(.bottom, HappySpacing.section)
        }
    }

    private func statusPill(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(label)
        }
        .font(HappyFont.buttonLabel)
        .foregroundColor(color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}

// MARK: - Join Request Sheet

struct JoinRequestSheet: View {
    let teeTime: TeeTime
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var note = ""

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Handle
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.happySand)
                        .frame(width: 36, height: 4)
                    Spacer()
                }
                .padding(.top, HappySpacing.md)
                .padding(.bottom, HappySpacing.xl)

                VStack(alignment: .leading, spacing: HappySpacing.sm) {
                    HappySectionLabel(text: "Join Request")
                    Text("Request to join\n\(teeTime.courseName)")
                        .font(HappyFont.displayHeadline(size: 30))
                        .foregroundColor(.happyGreen)
                        .lineSpacing(4)
                    Text("\(teeTime.dateDisplay) · \(teeTime.teeTimeString)")
                        .font(HappyFont.bodyLight(size: 14))
                        .foregroundColor(.happyMuted)
                }
                .padding(.horizontal, HappySpacing.xl)
                .padding(.bottom, HappySpacing.xl)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Note (Optional)".uppercased())
                        .font(HappyFont.formLabel)
                        .tracking(1.4)
                        .foregroundColor(.happyGreen)
                        .padding(.horizontal, HappySpacing.xl)

                    TextEditor(text: $note)
                        .font(HappyFont.bodyRegular(size: 14))
                        .foregroundColor(.happyBlack)
                        .frame(height: 100)
                        .padding(HappySpacing.md)
                        .background(Color.happyCream)
                        .cornerRadius(HappyRadius.input)
                        .overlay(
                            RoundedRectangle(cornerRadius: HappyRadius.input)
                                .stroke(Color.happySandLight, lineWidth: 1)
                        )
                        .padding(.horizontal, HappySpacing.xl)
                }

                Spacer()

                VStack(spacing: HappySpacing.xs) {
                    HappyPrimaryButton(title: "Send Request →", fullWidth: true) {
                        appState.requestToJoin(teeTime: teeTime, note: note.isEmpty ? nil : note)
                        dismiss()
                    }
                    HappyOutlineButton(title: "Cancel", fullWidth: true) {
                        dismiss()
                    }
                }
                .padding(.horizontal, HappySpacing.xl)
                .padding(.bottom, HappySpacing.xxxl)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    NavigationStack {
        TeeTimeDetailView(teeTime: TeeTime.mockData[0])
            .environmentObject({
                let s = AppState()
                s.createProfile(name: "Alex S.", handicap: 12.0, industry: "Tech", pace: .fast, homeCourse: "")
                return s
            }())
    }
}
