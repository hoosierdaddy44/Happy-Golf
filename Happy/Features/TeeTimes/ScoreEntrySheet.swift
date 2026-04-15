import SwiftUI

struct ScoreEntrySheet: View {
    let teeTime: TeeTime
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var grossScore = ""
    @State private var showAccolades = false
    @State private var claimedTypes: Set<AccoladeType> = []

    private var net: Int? {
        guard let gross = Int(grossScore), let me = appState.currentUser else { return nil }
        return gross - Int(me.handicapIndex)
    }

    private var diffToPar: String? {
        guard let n = net else { return nil }
        let diff = n - teeTime.par
        return diff > 0 ? "+\(diff)" : "\(diff)"
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
                    .padding(.bottom, HappySpacing.xxl)

                if showAccolades {
                    accoladeView
                } else {
                    scoreView
                }
            }
        }
    }

    // MARK: - Score View

    private var scoreView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HappySectionLabel(text: "Log Your Score")
                .padding(.bottom, HappySpacing.md)

            Text("How'd it go?")
                .font(HappyFont.displayHeadline(size: 36))
                .foregroundColor(.happyGreen)
                .padding(.bottom, HappySpacing.xs)

            Text("\(teeTime.courseName)\(teeTime.tees.map { " · \($0) Tees" } ?? "")")
                .font(HappyFont.bodyLight(size: 14))
                .foregroundColor(.happyMuted)
                .padding(.bottom, HappySpacing.xxl)

            HappyTextField(
                label: "Gross Score",
                placeholder: "e.g. 82",
                text: $grossScore,
                keyboardType: .numberPad,
                isRequired: true
            )
            .padding(.bottom, HappySpacing.lg)

            // Preview
            if let n = net, let diff = diffToPar, let me = appState.currentUser {
                VStack(spacing: HappySpacing.sm) {
                    HStack {
                        scoreStatBlock(label: "Gross", value: grossScore)
                        Spacer()
                        scoreStatBlock(label: "HCP", value: "\(Int(me.handicapIndex))")
                        Spacer()
                        scoreStatBlock(label: "Net", value: "\(n)")
                        Spacer()
                        scoreStatBlock(label: "To Par", value: diff)
                    }
                }
                .padding(HappySpacing.xl)
                .background(Color.happyWhite)
                .cornerRadius(HappyRadius.card)
                .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
                .padding(.bottom, HappySpacing.xl)
            }

            HappyPrimaryButton(title: "Save Score →", fullWidth: true) {
                guard let gross = Int(grossScore) else { return }
                Task {
                    await appState.submitScore(teeTimeId: teeTime.id, score: gross)
                    withAnimation { showAccolades = true }
                }
            }
            .opacity(Int(grossScore) != nil ? 1 : 0.4)
            .disabled(Int(grossScore) == nil)

            Spacer()
        }
        .padding(.horizontal, HappySpacing.xl)
    }

    // MARK: - Accolade View

    private var accoladeView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HappySectionLabel(text: "Any highlights?")
                    .padding(.bottom, HappySpacing.md)
                Text("Claim your\naccolades.")
                    .font(HappyFont.displayHeadline(size: 36))
                    .foregroundColor(.happyGreen)
                    .lineSpacing(4)
                    .padding(.bottom, HappySpacing.xs)
                Text("These will be visible on your profile and can be verified by co-players.")
                    .font(HappyFont.bodyLight(size: 14))
                    .foregroundColor(.happyMuted)
                    .padding(.bottom, HappySpacing.xxl)

                VStack(spacing: HappySpacing.sm) {
                    ForEach(AccoladeType.allCases, id: \.self) { type in
                        let claimed = claimedTypes.contains(type)
                        Button {
                            if !claimed {
                                claimedTypes.insert(type)
                                Task { await appState.claimAccolade(type: type, teeTimeId: teeTime.id) }
                            }
                        } label: {
                            HStack(spacing: HappySpacing.md) {
                                Text(type.emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 44, height: 44)
                                    .background(claimed ? Color.happyGreen.opacity(0.12) : Color.happySandLight)
                                    .cornerRadius(HappyRadius.icon)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.displayName)
                                        .font(HappyFont.bodyMedium(size: 14))
                                        .foregroundColor(.happyGreen)
                                    Text(type.description)
                                        .font(HappyFont.metaTiny)
                                        .foregroundColor(.happyMuted)
                                }
                                Spacer()
                                if claimed {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.happyGreen)
                                }
                            }
                            .padding(HappySpacing.md)
                            .background(claimed ? Color.happyGreen.opacity(0.06) : Color.happyWhite)
                            .cornerRadius(HappyRadius.card)
                            .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(claimed ? Color.happyGreen.opacity(0.3) : Color.happySandLight, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(claimed)
                    }
                }

                HappyPrimaryButton(title: "Done →", fullWidth: true) {
                    dismiss()
                }
                .padding(.top, HappySpacing.xl)
            }
            .padding(.horizontal, HappySpacing.xl)
        }
    }

    // MARK: - Helpers

    private func scoreStatBlock(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(HappyFont.displayMedium(size: 24))
                .foregroundColor(.happyGreen)
            Text(label.uppercased())
                .font(HappyFont.formLabel)
                .tracking(1.2)
                .foregroundColor(.happyMuted)
        }
    }
}
