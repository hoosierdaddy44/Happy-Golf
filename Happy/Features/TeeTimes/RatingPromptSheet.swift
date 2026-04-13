import SwiftUI

struct RatingPromptSheet: View {
    let teeTime: TeeTime
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var scores: [UUID: Int] = [:]
    @State private var step: Step = .rating
    @State private var selectedAccoladeTypes: Set<AccoladeType> = []

    enum Step { case rating, accolade }

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

                if step == .rating {
                    ratingStep
                } else {
                    accoladeStep
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Step 1: Rate

    private var ratingStep: some View {
        VStack(spacing: 0) {
            VStack(spacing: HappySpacing.xs) {
                Text("Rate Your Round")
                    .font(HappyFont.displayHeadline(size: 28))
                    .foregroundColor(.happyGreen)
                Text(teeTime.courseName)
                    .font(HappyFont.bodyLight(size: 14))
                    .foregroundColor(.happyMuted)
            }
            .padding(.bottom, HappySpacing.xxl)

            ScrollView(showsIndicators: false) {
                VStack(spacing: HappySpacing.md) {
                    ForEach(rateablePlayers, id: \.self) { playerId in
                        playerRatingRow(playerId: playerId)
                    }
                }
                .padding(.horizontal, HappySpacing.xl)
            }

            Spacer()

            VStack(spacing: 0) {
                HappyDivider()
                VStack(spacing: HappySpacing.sm) {
                    HappyPrimaryButton(title: "Submit & Continue →", fullWidth: true) {
                        Task {
                            for (rateeId, score) in scores where score > 0 {
                                await appState.submitRating(
                                    teeTimeId: teeTime.id,
                                    rateeId: rateeId,
                                    score: score
                                )
                            }
                            withAnimation { step = .accolade }
                        }
                    }
                    Button("Skip") { appState.dismissRatingPrompt(for: teeTime.id); dismiss() }
                        .font(HappyFont.bodyMedium(size: 13))
                        .foregroundColor(.happyMuted)
                }
                .padding(.horizontal, HappySpacing.xl)
                .padding(.vertical, HappySpacing.lg)
                .background(Color.happyCream)
            }
        }
    }

    // MARK: - Step 2: Accolade

    private var accoladeStep: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: HappySpacing.xs) {
                HappySectionLabel(text: "Tour Card")
                    .padding(.bottom, HappySpacing.xs)
                Text("Anything to claim?")
                    .font(HappyFont.displayHeadline(size: 30))
                    .foregroundColor(.happyGreen)
                Text("A fellow player from the round will verify it.")
                    .font(HappyFont.bodyLight(size: 14))
                    .foregroundColor(.happyMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, HappySpacing.xl)
            .padding(.bottom, HappySpacing.xl)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: HappySpacing.sm) {
                    ForEach(AccoladeType.allCases, id: \.self) { type in
                        accoladeChip(type)
                    }
                }
                .padding(.horizontal, HappySpacing.xl)
            }

            Spacer()

            VStack(spacing: 0) {
                HappyDivider()
                VStack(spacing: HappySpacing.sm) {
                    HappyPrimaryButton(
                        title: selectedAccoladeTypes.isEmpty ? "Claim →" : "Claim \(selectedAccoladeTypes.count) →",
                        fullWidth: true
                    ) {
                        Task {
                            for type in selectedAccoladeTypes {
                                await appState.claimAccolade(type: type, teeTimeId: teeTime.id)
                            }
                            dismiss()
                        }
                    }
                    .disabled(selectedAccoladeTypes.isEmpty)
                    .opacity(selectedAccoladeTypes.isEmpty ? 0.5 : 1)

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

    // MARK: - Sub-views

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

    private func accoladeChip(_ type: AccoladeType) -> some View {
        let isSelected = selectedAccoladeTypes.contains(type)
        return Button {
            if isSelected { selectedAccoladeTypes.remove(type) } else { selectedAccoladeTypes.insert(type) }
        } label: {
            HStack(spacing: HappySpacing.xs) {
                Text(type.emoji).font(.system(size: 18))
                Text(type.displayName)
                    .font(HappyFont.bodyMedium(size: 13))
                    .foregroundColor(isSelected ? .happyWhite : .happyBlack)
                    .lineLimit(1)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(HappySpacing.sm)
            .background(isSelected ? Color.happyGreen : Color.happyWhite)
            .cornerRadius(HappyRadius.card)
            .overlay(RoundedRectangle(cornerRadius: HappyRadius.card)
                .stroke(isSelected ? Color.happyGreen : Color.happySandLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
