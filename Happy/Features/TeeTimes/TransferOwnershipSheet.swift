import SwiftUI

struct TransferOwnershipSheet: View {
    let teeTime: TeeTime
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var confirming: UUID? = nil

    private var otherPlayers: [User] {
        teeTime.players.compactMap { appState.user(for: $0) }
    }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.happySand)
                    .frame(width: 36, height: 4)
                    .padding(.top, HappySpacing.md)
                    .padding(.bottom, HappySpacing.xxl)

                VStack(alignment: .leading, spacing: 0) {
                    HappySectionLabel(text: "Transfer Ownership")
                        .padding(.bottom, HappySpacing.md)
                    Text("Hand off\nyour round.")
                        .font(HappyFont.displayHeadline(size: 36))
                        .foregroundColor(.happyGreen)
                        .lineSpacing(4)
                        .padding(.bottom, HappySpacing.xs)
                    Text("The new host can approve/decline requests and manage the round.")
                        .font(HappyFont.bodyLight(size: 14))
                        .foregroundColor(.happyMuted)
                        .padding(.bottom, HappySpacing.xxl)

                    if otherPlayers.isEmpty {
                        Text("No confirmed players yet. Approve a request first.")
                            .font(HappyFont.bodyLight(size: 14))
                            .foregroundColor(.happyMuted)
                            .italic()
                    } else {
                        VStack(spacing: HappySpacing.sm) {
                            ForEach(otherPlayers) { player in
                                Button {
                                    confirming = player.id
                                } label: {
                                    HStack(spacing: HappySpacing.md) {
                                        HappyAvatar(user: player, size: 44)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(player.name)
                                                .font(HappyFont.bodyMedium(size: 15))
                                                .foregroundColor(.happyGreen)
                                            Text("HCP \(player.handicapDisplay) · \(player.pacePreference.rawValue)")
                                                .font(HappyFont.metaTiny)
                                                .foregroundColor(.happyMuted)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13))
                                            .foregroundColor(.happyMuted)
                                    }
                                    .padding(HappySpacing.md)
                                    .background(Color.happyWhite)
                                    .cornerRadius(HappyRadius.card)
                                    .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, HappySpacing.xl)

                Spacer()
            }
        }
        .confirmationDialog(
            "Transfer ownership?",
            isPresented: Binding(get: { confirming != nil }, set: { if !$0 { confirming = nil } }),
            titleVisibility: .visible
        ) {
            if let newHostId = confirming,
               let player = otherPlayers.first(where: { $0.id == newHostId }) {
                Button("Make \(player.name) the host") {
                    Task {
                        await appState.transferOwnership(teeTimeId: teeTime.id, newHostId: newHostId)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) { confirming = nil }
            }
        }
    }
}
