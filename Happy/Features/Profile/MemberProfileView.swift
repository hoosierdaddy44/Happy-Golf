import SwiftUI

struct MemberProfileView: View {
    let userId: UUID
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var selectedVerifierId: UUID?

    private var user: User? { appState.profileCache[userId] }
    private var userAccolades: [Accolade] { appState.accolades[userId] ?? [] }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            if let user = user {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileHeader(user)
                        profileBody(user)
                    }
                }
            } else {
                ProgressView()
                    .tint(.happyGreen)
            }
        }
        .task {
            async let p: () = appState.fetchCachedProfile(userId: userId)
            async let a: () = appState.fetchAccolades(for: userId)
            _ = await (p, a)
        }
        .sheet(item: Binding(
            get: { selectedVerifierId.map { MemberProfileWrapper(id: $0) } },
            set: { selectedVerifierId = $0?.id }
        )) { wrapper in
            MemberProfileView(userId: wrapper.id)
                .environmentObject(appState)
        }
    }

    private func profileHeader(_ user: User) -> some View {
        ZStack(alignment: .bottom) {
            Color.happyGreen
                .frame(height: 180)

            VStack(spacing: 0) {
                HappyAvatar(user: user, size: 80)
                    .padding(.bottom, HappySpacing.sm)

                Text(user.name)
                    .font(HappyFont.displayHeadline(size: 24))
                    .foregroundColor(.happyWhite)
                    .padding(.bottom, 4)

                // Pills row
                HStack(spacing: HappySpacing.xs) {
                    hcpPill(user)
                    if let rating = user.rating {
                        ratingPill(rating, count: user.ratingCount)
                    }
                    pacePill(user)
                }
                .padding(.bottom, HappySpacing.lg)
            }
        }
    }

    private func hcpPill(_ user: User) -> some View {
        Text("HCP \(user.handicapDisplay)")
            .font(HappyFont.bodyMedium(size: 12))
            .tracking(0.4)
            .foregroundColor(.happyGreen)
            .padding(.vertical, 5)
            .padding(.horizontal, 12)
            .background(Color.happyWhite.opacity(0.9))
            .clipShape(Capsule())
    }

    private func ratingPill(_ rating: Double, count: Int) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 9))
                .foregroundColor(.happyAccent)
            Text(String(format: "%.1f", rating))
                .font(HappyFont.bodyMedium(size: 12))
                .foregroundColor(.happyGreen)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 12)
        .background(Color.happyWhite.opacity(0.9))
        .clipShape(Capsule())
    }

    private func pacePill(_ user: User) -> some View {
        Text("\(user.pacePreference.emoji) \(user.pacePreference.rawValue)")
            .font(HappyFont.bodyMedium(size: 12))
            .foregroundColor(.happyGreen)
            .padding(.vertical, 5)
            .padding(.horizontal, 12)
            .background(Color.happyWhite.opacity(0.9))
            .clipShape(Capsule())
    }

    private func profileBody(_ user: User) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Details
            VStack(alignment: .leading, spacing: HappySpacing.sm) {
                if !user.industry.isEmpty {
                    metaRow(icon: "briefcase", text: user.industry)
                }
                if !user.homeCourses.isEmpty {
                    metaRow(icon: "flag", text: user.homeCourses.joined(separator: ", "))
                }
                metaRow(icon: "calendar", text: "Member since \(memberSinceDisplay(user.joinedAt))")
            }
            .padding(HappySpacing.xl)

            if !userAccolades.isEmpty {
                HappyDivider()
                accoladesSection(user)
            }

            Spacer(minLength: 40)
        }
        .background(Color.happyCream)
    }

    private func metaRow(icon: String, text: String) -> some View {
        HStack(spacing: HappySpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.happyGreen)
                .frame(width: 18)
            Text(text)
                .font(HappyFont.bodyLight(size: 14))
                .foregroundColor(.happyBlack)
        }
    }

    private func accoladesSection(_ user: User) -> some View {
        VStack(alignment: .leading, spacing: HappySpacing.md) {
            HappySectionLabel(text: "Accolades")
                .padding(.horizontal, HappySpacing.xl)
                .padding(.top, HappySpacing.lg)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: HappySpacing.sm) {
                ForEach(userAccolades) { accolade in
                    accoladeChip(accolade, viewerUser: appState.currentUser)
                }
            }
            .padding(.horizontal, HappySpacing.xl)
            .padding(.bottom, HappySpacing.lg)
        }
    }

    private func accoladeChip(_ accolade: Accolade, viewerUser: User?) -> some View {
        let alreadyVerified = accolade.verifications.contains { $0.verifierId == viewerUser?.id }
        let canVerify = viewerUser?.id != userId && !alreadyVerified

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(accolade.type.emoji).font(.system(size: 20))
                Text(accolade.type.displayName)
                    .font(HappyFont.bodyMedium(size: 12))
                    .foregroundColor(.happyBlack)
                    .lineLimit(1)
                Spacer()
            }

            if accolade.verifications.isEmpty {
                Text("Unverified")
                    .font(HappyFont.metaTiny)
                    .foregroundColor(.happyMuted)
                    .italic()
            } else {
                // Show verifier names, tappable
                FlowLayout(spacing: 2) {
                    Text("Verified by ")
                        .font(HappyFont.metaTiny)
                        .foregroundColor(.happyMuted)
                    ForEach(Array(accolade.verifications.enumerated()), id: \.element.id) { idx, ver in
                        Button {
                            selectedVerifierId = ver.verifierId
                        } label: {
                            Text(appState.profileCache[ver.verifierId]?.name ?? "Member")
                                .font(HappyFont.bodyMedium(size: 11))
                                .foregroundColor(.happyGreen)
                                .underline()
                        }
                        if idx < accolade.verifications.count - 1 {
                            Text(",").font(HappyFont.metaTiny).foregroundColor(.happyMuted)
                        }
                    }
                }
            }

            if canVerify {
                Button {
                    Task { await appState.verifyAccolade(accolade) }
                } label: {
                    Text("Confirm")
                        .font(HappyFont.bodyMedium(size: 11))
                        .foregroundColor(.happyGreen)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .overlay(Capsule().stroke(Color.happyGreen, lineWidth: 1))
                }
            }
        }
        .padding(HappySpacing.sm)
        .background(Color.happyWhite)
        .cornerRadius(HappyRadius.card)
        .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
    }

    private func memberSinceDisplay(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }
}

// Helper to make UUID sheet-presentable
private struct MemberProfileWrapper: Identifiable {
    let id: UUID
}

// Simple flow layout for verifier names
private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                y += lineHeight + spacing
                x = 0
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            x += size.width + spacing
        }
        height = y + lineHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += lineHeight + spacing
                x = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            lineHeight = max(lineHeight, size.height)
            x += size.width + spacing
        }
    }
}

