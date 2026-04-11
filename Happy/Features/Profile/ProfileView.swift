import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authManager: AuthManager

    private var user: User? { appState.currentUser }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            if let user = user {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileHeader(user: user)
                        profileBody(user: user)
                    }
                }
                .ignoresSafeArea(edges: .top)
            } else {
                Text("No profile yet.")
                    .font(HappyFont.bodyLight())
                    .foregroundColor(.happyMuted)
            }
        }
    }

    // MARK: - Header (green band)

    private func profileHeader(user: User) -> some View {
        ZStack(alignment: .bottomLeading) {
            Color.happyGreen.frame(height: 220)

            // Ghost "H"
            Text("H")
                .font(.custom("PlayfairDisplay-Bold", size: 300))
                .foregroundColor(Color.white.opacity(0.03))
                .offset(x: 60, y: 80)

            VStack(alignment: .leading, spacing: 0) {
                // Edit button
                HStack {
                    Spacer()
                    Menu {
                        Button("Edit Profile", action: {})
                        Button("Sign Out", role: .destructive) {
                            Task { await authManager.signOut() }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.6))
                            .padding(10)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, HappySpacing.xl)

                Spacer()

                // Avatar — sits half-over the card edge
                Text(user.initials)
                    .font(.custom("PlayfairDisplay-Medium", size: 30))
                    .foregroundColor(.happyWhite)
                    .frame(width: 76, height: 76)
                    .background(user.avatarColor)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 2))
                    .padding(.leading, HappySpacing.xl)
                    .offset(y: 38)
            }
        }
        .frame(height: 220)
    }

    // MARK: - Body card

    private func profileBody(user: User) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: HappySpacing.xl) {
                // Avatar spacer
                Spacer().frame(height: HappySpacing.xl)

                // Name + pills
                VStack(alignment: .leading, spacing: HappySpacing.sm) {
                    Text(user.name)
                        .font(HappyFont.displayMedium(size: 28))
                        .foregroundColor(.happyBlack)

                    HStack(spacing: HappySpacing.xs) {
                        handicapPill(user.handicapDisplay)
                        pacePill(user.pacePreference)
                    }
                }

                HappyDivider()

                // Detail rows
                VStack(spacing: HappySpacing.md) {
                    if !user.industry.isEmpty {
                        detailRow(label: "Industry", value: user.industry)
                    }
                    if !user.homeCourses.isEmpty {
                        detailRow(label: "Home Course", value: user.homeCourses.joined(separator: ", "))
                    }
                    detailRow(label: "Member Since", value: user.joinedAt.formatted(.dateTime.month(.wide).year()))
                }

                HappyDivider()

                // Stats row
                HStack {
                    statBlock(value: "\(appState.currentUserTeeTimes.count)", label: "Rounds")
                    Spacer()
                    statBlock(value: "—", label: "Tour Card")
                    Spacer()
                    statBlock(value: "—", label: "Avg Rating")
                }

                HappyDivider()

                // Hosted rounds preview
                VStack(alignment: .leading, spacing: HappySpacing.sm) {
                    HappySectionLabel(text: "Recent Rounds")
                    if appState.currentUserTeeTimes.isEmpty {
                        Text("No rounds yet. Host your first one.")
                            .font(HappyFont.bodyLight(size: 14))
                            .foregroundColor(.happyMuted)
                            .italic()
                    } else {
                        ForEach(appState.currentUserTeeTimes.prefix(3)) { tt in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(tt.courseName)
                                        .font(HappyFont.bodyMedium(size: 14))
                                        .foregroundColor(.happyBlack)
                                    Text(tt.dateDisplay)
                                        .font(HappyFont.metaTiny)
                                        .foregroundColor(.happyMuted)
                                }
                                Spacer()
                                if tt.hostId == user.id {
                                    Text("Host")
                                        .font(HappyFont.bodyMedium(size: 10))
                                        .tracking(0.6)
                                        .foregroundColor(.happyGreenLight)
                                        .padding(.vertical, 3)
                                        .padding(.horizontal, 8)
                                        .background(Color.happyGreenLight.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, HappySpacing.xs)
                        }
                    }
                }
            }
            .padding(.horizontal, HappySpacing.xl)
            .padding(.bottom, HappySpacing.section)
            .background(Color.happyWhite)
            .cornerRadius(HappyRadius.sectionLg, corners: [.topLeft, .topRight])
            .shadow(color: Color.happyGreen.opacity(0.06), radius: 20, y: -4)
        }
    }

    // MARK: - Sub-components

    private func handicapPill(_ value: String) -> some View {
        Text("HCP \(value)")
            .font(HappyFont.bodyMedium(size: 12))
            .tracking(0.6)
            .foregroundColor(.happyGreenLight)
            .padding(.vertical, 5)
            .padding(.horizontal, 12)
            .background(Color.happyGreenLight.opacity(0.08))
            .clipShape(Capsule())
    }

    private func pacePill(_ pace: PacePref) -> some View {
        Text("\(pace.emoji) \(pace.rawValue)")
            .font(HappyFont.bodyMedium(size: 12))
            .foregroundColor(.happyMuted)
            .padding(.vertical, 5)
            .padding(.horizontal, 12)
            .background(Color.happySandLight.opacity(0.6))
            .clipShape(Capsule())
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label.uppercased())
                .font(HappyFont.formLabel)
                .tracking(1.4)
                .foregroundColor(.happyGreenLight)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(HappyFont.bodyRegular(size: 14))
                .foregroundColor(.happyBlack)
            Spacer()
        }
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(HappyFont.displayMedium(size: 30))
                .foregroundColor(.happyGreen)
            Text(label)
                .font(HappyFont.metaTiny)
                .tracking(0.6)
                .foregroundColor(.happyMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProfileView()
        .environmentObject({
            let s = AppState()
            s.currentUser = User.jamesK
            s.isOnboarded = true
            return s
        }())
        .environmentObject(AuthManager())
}
