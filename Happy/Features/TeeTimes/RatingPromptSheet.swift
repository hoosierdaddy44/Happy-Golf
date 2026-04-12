import SwiftUI

struct RatingPromptSheet: View {
    let teeTime: TeeTime
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var scores: [UUID: Int] = [:]

    private var rateablePlayers: [UUID] {
        (teeTime.players + [teeTime.hostId])
            .filter { $0 != appState.currentUser?.id }
    }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(Color.happySandLight)
                    .frame(width: 36, height: 4)
                    .padding(.top, HappySpacing.md)
                    .padding(.bottom, HappySpacing.xl)

                // Header
                VStack(spacing: HappySpacing.xs) {
                    Text("Rate Your Round")
                        .font(HappyFont.displayHeadline(size: 28))
                        .foregroundColor(.happyGreen)

                    Text(teeTime.courseName)
                        .font(HappyFont.bodyLight(size: 14))
                        .foregroundColor(.happyMuted)
                }
                .padding(.bottom, HappySpacing.xxl)

                // Players to rate
                ScrollView(showsIndicators: false) {
                    VStack(spacing: HappySpacing.md) {
                        ForEach(rateablePlayers, id: \.self) { playerId in
                            playerRatingRow(playerId: playerId)
                        }
                    }
                    .padding(.horizontal, HappySpacing.xl)
                }

                Spacer()

                // Submit
                VStack(spacing: 0) {
                    HappyDivider()
                    VStack(spacing: HappySpacing.sm) {
                        HappyPrimaryButton(title: "Submit Ratings", fullWidth: true) {
                            Task {
                                for (rateeId, score) in scores where score > 0 {
                                    await appState.submitRating(
                                        teeTimeId: teeTime.id,
                                        rateeId: rateeId,
                                        score: score
                                    )
                                }
                                dismiss()
                            }
                        }

                        Button("Skip") { dismiss() }
                            .font(HappyFont.bodyMedium(size: 13))
                            .foregroundColor(.happyMuted)
                    }
                    .padding(.horizontal, HappySpacing.xl)
                    .padding(.vertical, HappySpacing.lg)
                    .background(Color.happyCream)
                }
            }
        }
    }

    private func playerRatingRow(playerId: UUID) -> some View {
        let user = appState.profileCache[playerId]
        let binding = Binding<Int>(
            get: { scores[playerId] ?? 0 },
            set: { scores[playerId] = $0 }
        )

        return HStack {
            if let user = user {
                HappyAvatar(user: user, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(HappyFont.bodyMedium(size: 14))
                        .foregroundColor(.happyBlack)
                    Text("HCP \(user.handicapDisplay)")
                        .font(HappyFont.metaTiny)
                        .foregroundColor(.happyMuted)
                }
            } else {
                Circle()
                    .fill(Color.happySandLight)
                    .frame(width: 44, height: 44)
                Text("Player")
                    .font(HappyFont.bodyMedium(size: 14))
                    .foregroundColor(.happyMuted)
            }

            Spacer()

            StarRatingView(rating: binding)
        }
        .padding(HappySpacing.md)
        .background(Color.happyWhite)
        .cornerRadius(HappyRadius.card)
    }
}
