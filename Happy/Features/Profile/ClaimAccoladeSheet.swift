import SwiftUI

struct ClaimAccoladeSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var selectedType: AccoladeType = .eagle
    @State private var selectedTeeTimeId: UUID? = nil

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

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        HappySectionLabel(text: "New Accolade")
                            .padding(.bottom, HappySpacing.md)

                        Text("Claim your moment.")
                            .font(HappyFont.displayHeadline(size: 32))
                            .foregroundColor(.happyGreen)
                            .padding(.bottom, HappySpacing.xs)

                        Text("A fellow player from the round will verify it.")
                            .font(HappyFont.bodyLight(size: 14))
                            .foregroundColor(.happyMuted)
                            .padding(.bottom, HappySpacing.xxl)

                        // Accolade type picker
                        VStack(alignment: .leading, spacing: HappySpacing.sm) {
                            Text("ACCOLADE".uppercased())
                                .font(HappyFont.formLabel)
                                .tracking(1.4)
                                .foregroundColor(.happyGreen)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: HappySpacing.sm) {
                                ForEach(AccoladeType.allCases, id: \.self) { type in
                                    accoladeTypeChip(type)
                                }
                            }
                        }
                        .padding(.bottom, HappySpacing.xl)

                        // Optional round link
                        if !appState.currentUserTeeTimes.isEmpty {
                            VStack(alignment: .leading, spacing: HappySpacing.sm) {
                                Text("LINK TO ROUND (OPTIONAL)".uppercased())
                                    .font(HappyFont.formLabel)
                                    .tracking(1.4)
                                    .foregroundColor(.happyGreen)

                                ForEach(appState.currentUserTeeTimes.prefix(5)) { teeTime in
                                    roundRow(teeTime)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, HappySpacing.xl)
                    .padding(.bottom, 100)
                }

                // CTA
                VStack(spacing: 0) {
                    HappyDivider()
                    HappyPrimaryButton(title: "Claim Accolade →", fullWidth: true) {
                        Task {
                            await appState.claimAccolade(type: selectedType, teeTimeId: selectedTeeTimeId)
                            dismiss()
                        }
                    }
                    .padding(.horizontal, HappySpacing.xl)
                    .padding(.vertical, HappySpacing.lg)
                    .background(Color.happyCream)
                }
            }
        }
    }

    private func accoladeTypeChip(_ type: AccoladeType) -> some View {
        let isSelected = selectedType == type
        return Button { selectedType = type } label: {
            HStack(spacing: HappySpacing.xs) {
                Text(type.emoji).font(.system(size: 18))
                Text(type.displayName)
                    .font(HappyFont.bodyMedium(size: 13))
                    .foregroundColor(isSelected ? .happyWhite : .happyBlack)
                Spacer()
            }
            .padding(HappySpacing.sm)
            .background(isSelected ? Color.happyGreen : Color.happyWhite)
            .cornerRadius(HappyRadius.card)
            .overlay(RoundedRectangle(cornerRadius: HappyRadius.card)
                .stroke(isSelected ? Color.happyGreen : Color.happySandLight, lineWidth: 1))
        }
    }

    private func roundRow(_ teeTime: TeeTime) -> some View {
        let isSelected = selectedTeeTimeId == teeTime.id
        return Button {
            selectedTeeTimeId = isSelected ? nil : teeTime.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(teeTime.courseName)
                        .font(HappyFont.bodyMedium(size: 13))
                        .foregroundColor(isSelected ? .happyWhite : .happyBlack)
                    Text(teeTime.teeTimeString)
                        .font(HappyFont.metaTiny)
                        .foregroundColor(isSelected ? .happyWhite.opacity(0.7) : .happyMuted)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.happyWhite)
                }
            }
            .padding(HappySpacing.sm)
            .background(isSelected ? Color.happyGreen : Color.happyWhite)
            .cornerRadius(HappyRadius.card)
            .overlay(RoundedRectangle(cornerRadius: HappyRadius.card)
                .stroke(isSelected ? Color.happyGreen : Color.happySandLight, lineWidth: 1))
        }
    }
}
