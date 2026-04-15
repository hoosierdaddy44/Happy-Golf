import SwiftUI

struct RoundSummaryView: View {
    let teeTime: TeeTime
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var scores: [RoundScoreRow] = []
    @State private var verifications: [ScoreVerificationRow] = []
    @State private var isLoading = true

    private struct PlayerEntry: Identifiable {
        let id: UUID
        let user: User?
        let grossScore: Int?
        let netScore: Int?
        let diffToPar: Int?
        let verifierIds: [UUID]
        let accolades: [Accolade]
    }

    private var entries: [PlayerEntry] {
        teeTime.confirmedPlayerIds.map { uid in
            let user = appState.user(for: uid)
            let scoreRow = scores.first(where: { $0.userId == uid })
            let gross = scoreRow?.grossScore
            let hcp = Int(user?.handicapIndex ?? 0)
            let net = gross.map { $0 - hcp }
            let diff = net.map { $0 - teeTime.par }
            let vers = verifications.filter { $0.playerId == uid }.map { $0.verifierId }
            let acc = (appState.accolades[uid] ?? []).filter { $0.teeTimeId == teeTime.id }
            return PlayerEntry(id: uid, user: user, grossScore: gross, netScore: net,
                               diffToPar: diff, verifierIds: vers, accolades: acc)
        }
        .sorted {
            guard let a = $0.netScore, let b = $1.netScore else {
                return $0.netScore != nil
            }
            return a < b
        }
    }

    private var winner: PlayerEntry? {
        entries.first(where: { $0.netScore != nil })
    }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.happySand)
                    .frame(width: 36, height: 4)
                    .padding(.top, HappySpacing.md)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: HappySpacing.xs) {
                            HappySectionLabel(text: "Round Summary")
                            Text(teeTime.courseName)
                                .font(HappyFont.displayHeadline(size: 30))
                                .foregroundColor(.happyGreen)
                            HStack(spacing: HappySpacing.xs) {
                                Text(teeTime.dateDisplay)
                                    .font(HappyFont.metaSmall)
                                    .foregroundColor(.happyMuted)
                                Text("·")
                                    .foregroundColor(.happyMuted)
                                HappyBadge(text: teeTime.format.displayName, showDot: false)
                            }
                        }
                        .padding(.horizontal, HappySpacing.xl)
                        .padding(.top, HappySpacing.lg)
                        .padding(.bottom, HappySpacing.xl)

                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                        } else {
                            // Winner banner
                            if let w = winner, let user = w.user, let net = w.netScore {
                                let diff = w.diffToPar ?? 0
                                let diffStr = diff >= 0 ? "+\(diff)" : "\(diff)"
                                VStack(spacing: HappySpacing.xs) {
                                    Text("🏆")
                                        .font(.system(size: 36))
                                    Text("\(user.name) wins")
                                        .font(HappyFont.displayMedium(size: 20))
                                        .foregroundColor(.happyGreen)
                                    Text("Net \(net) · \(diffStr) to par")
                                        .font(HappyFont.metaSmall)
                                        .foregroundColor(.happyMuted)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(HappySpacing.lg)
                                .background(Color.happyAccent.opacity(0.12))
                                .cornerRadius(HappyRadius.card)
                                .padding(.horizontal, HappySpacing.xl)
                                .padding(.bottom, HappySpacing.xl)
                            }

                            // Leaderboard
                            VStack(alignment: .leading, spacing: HappySpacing.sm) {
                                HappySectionLabel(text: "Leaderboard")
                                    .padding(.horizontal, HappySpacing.xl)
                                    .padding(.bottom, HappySpacing.xs)

                                ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                                    leaderboardRow(entry: entry, position: idx + 1)
                                }
                            }
                            .padding(.bottom, HappySpacing.xl)

                            // Accolades
                            let allAccolades = entries.flatMap { $0.accolades }
                            if !allAccolades.isEmpty {
                                VStack(alignment: .leading, spacing: HappySpacing.sm) {
                                    HappySectionLabel(text: "Accolades")
                                        .padding(.horizontal, HappySpacing.xl)
                                    ForEach(allAccolades) { acc in
                                        if let user = appState.user(for: acc.userId) {
                                            HStack(spacing: HappySpacing.sm) {
                                                Text(acc.type.emoji)
                                                    .font(.system(size: 24))
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(acc.type.displayName)
                                                        .font(HappyFont.bodyMedium(size: 14))
                                                        .foregroundColor(.happyGreen)
                                                    Text(user.name)
                                                        .font(HappyFont.metaTiny)
                                                        .foregroundColor(.happyMuted)
                                                }
                                                Spacer()
                                                Text("\(acc.verifications.count) verified")
                                                    .font(HappyFont.metaTiny)
                                                    .foregroundColor(.happyMuted)
                                            }
                                            .padding(HappySpacing.md)
                                            .background(Color.happyWhite)
                                            .cornerRadius(HappyRadius.card)
                                            .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
                                            .padding(.horizontal, HappySpacing.xl)
                                        }
                                    }
                                }
                                .padding(.bottom, HappySpacing.xl)
                            }
                        }
                    }
                }
            }
        }
        .task {
            async let s = appState.fetchRoundScores(teeTimeId: teeTime.id)
            async let v = appState.fetchScoreVerifications(teeTimeId: teeTime.id)
            // Pre-load all player profiles
            await withTaskGroup(of: Void.self) { group in
                for uid in teeTime.confirmedPlayerIds {
                    group.addTask { await appState.fetchCachedProfile(userId: uid) }
                }
            }
            scores = await s
            verifications = await v
            isLoading = false
        }
    }

    private func leaderboardRow(entry: PlayerEntry, position: Int) -> some View {
        let me = appState.currentUser
        let hasVerified = verifications.contains {
            $0.playerId == entry.id && $0.verifierId == (me?.id ?? UUID())
        }
        let canVerify = entry.grossScore != nil && me?.id != entry.id && !hasVerified

        return VStack(alignment: .leading, spacing: HappySpacing.xs) {
            HStack(spacing: HappySpacing.md) {
                // Position
                Text("\(position)")
                    .font(HappyFont.displayMedium(size: 18))
                    .foregroundColor(position == 1 ? .happyAccent : .happyMuted)
                    .frame(width: 24)

                // Player
                if let user = entry.user {
                    HappyAvatar(user: user, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name)
                            .font(HappyFont.bodyMedium(size: 14))
                            .foregroundColor(.happyGreen)
                        if let gross = entry.grossScore, let net = entry.netScore, let diff = entry.diffToPar {
                            let diffStr = diff >= 0 ? "+\(diff)" : "\(diff)"
                            Text("Gross \(gross) · Net \(net) · \(diffStr)")
                                .font(HappyFont.metaTiny)
                                .foregroundColor(.happyMuted)
                        } else {
                            Text("No score logged")
                                .font(HappyFont.metaTiny)
                                .foregroundColor(.happyMuted)
                                .italic()
                        }
                    }
                }
                Spacer()

                // Verify button
                if canVerify {
                    Button {
                        Task { await appState.verifyScore(teeTimeId: teeTime.id, playerId: entry.id) }
                        // Optimistic update
                        if let me = me {
                            verifications.append(ScoreVerificationRow(
                                id: UUID(), teeTimeId: teeTime.id,
                                playerId: entry.id, verifierId: me.id, createdAt: Date()
                            ))
                        }
                    } label: {
                        Text("Verify")
                            .font(HappyFont.bodyMedium(size: 11))
                            .foregroundColor(.happyGreen)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .overlay(Capsule().stroke(Color.happyGreen, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                } else if entry.grossScore != nil {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.happyGreenLight)
                        Text("\(entry.verifierIds.count)")
                            .font(HappyFont.metaTiny)
                            .foregroundColor(.happyMuted)
                    }
                }
            }
        }
        .padding(HappySpacing.md)
        .background(Color.happyWhite)
        .cornerRadius(HappyRadius.card)
        .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(
            position == 1 && entry.grossScore != nil ? Color.happyAccent.opacity(0.4) : Color.happySandLight,
            lineWidth: position == 1 && entry.grossScore != nil ? 1.5 : 1
        ))
        .padding(.horizontal, HappySpacing.xl)
    }
}
