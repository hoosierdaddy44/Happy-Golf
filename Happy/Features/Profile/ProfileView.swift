import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authManager: AuthManager

    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedMemberId: UUID?
    @State private var showPlayerSearch = false
    @State private var showEditProfile = false
    @State private var showDeleteConfirm = false

    private var user: User? { appState.currentUser }
    private var myAccolades: [Accolade] { appState.accolades[user?.id ?? UUID()] ?? [] }

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
                .sheet(item: Binding(
                    get: { selectedMemberId.map { MemberIDWrapper(id: $0) } },
                    set: { selectedMemberId = $0?.id }
                )) { wrapper in
                    MemberProfileView(userId: wrapper.id).environmentObject(appState)
                }
                .sheet(isPresented: $showPlayerSearch) {
                    PlayerSearchView().environmentObject(appState)
                }
                .sheet(isPresented: $showEditProfile) {
                    if let user = appState.currentUser {
                        EditProfileSheet(user: user).environmentObject(appState)
                    }
                }
                .alert("Delete Account", isPresented: $showDeleteConfirm) {
                    Button("Delete", role: .destructive) {
                        Task {
                            await appState.deleteAccount()
                            await authManager.signOut()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will permanently delete your account and all your data. This cannot be undone.")
                }

                // Floating header buttons — always visible regardless of scroll position
                VStack {
                    HStack {
                        Spacer()
                        Button { showPlayerSearch = true } label: {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.75))
                                .padding(10)
                        }
                        Menu {
                            Button("Edit Profile") { showEditProfile = true }
                            Button("Sign Out", role: .destructive) {
                                Task { await authManager.signOut() }
                            }
                            Button("Delete Account", role: .destructive) {
                                showDeleteConfirm = true
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.75))
                                .padding(10)
                        }
                    }
                    .padding(.horizontal, HappySpacing.md)
                    .padding(.top, 60)
                    Spacer()
                }
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
                // Spacer to push avatar down (buttons are now in floating overlay)
                HStack { Spacer() }
                .padding(.top, 60)
                .padding(.horizontal, HappySpacing.xl)

                Spacer()

                // Avatar — sits half-over the card edge
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        if let data = user.avatarImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 76, height: 76)
                                .clipShape(Circle())
                        } else {
                            Text(user.initials)
                                .font(.custom("PlayfairDisplay-Medium", size: 30))
                                .foregroundColor(.happyWhite)
                                .frame(width: 76, height: 76)
                                .background(user.avatarColor)
                                .clipShape(Circle())
                        }
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.happyWhite)
                            .padding(5)
                            .background(Color.happyGreen)
                            .clipShape(Circle())
                            .offset(x: 2, y: 2)
                    }
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 2))
                }
                .onChange(of: pickerItem) { _, item in
                    Task {
                        guard let item else { return }
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data),
                           let jpegData = uiImage.jpegData(compressionQuality: 0.85) {
                            await appState.updateAvatar(jpegData)
                        }
                    }
                }
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
                        if let rating = user.rating {
                            ratingPill(rating)
                        }
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
                    statBlock(value: "\(myAccolades.count)", label: "Tour Card")
                    Spacer()
                    statBlock(
                        value: user.rating != nil ? "⭐ \(user.ratingDisplay)" : "—",
                        label: "Avg Rating"
                    )
                }

                HappyDivider()

                // Accolades section
                VStack(alignment: .leading, spacing: HappySpacing.sm) {
                    HappySectionLabel(text: "Tour Card")
                    if myAccolades.isEmpty {
                        Text("Claim your first accolade.")
                            .font(HappyFont.bodyLight(size: 14))
                            .foregroundColor(.happyMuted)
                            .italic()
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: HappySpacing.sm) {
                            ForEach(myAccolades) { accolade in
                                accoladeChip(accolade)
                            }
                        }
                    }
                }

                HappyDivider()

                // Recent rounds: upcoming first, then completed
                let completedRounds = appState.currentUserTeeTimes.sorted { a, b in
                    if a.isCompleted != b.isCompleted { return !a.isCompleted }
                    return a.date < b.date
                }
                VStack(alignment: .leading, spacing: HappySpacing.sm) {
                    HappySectionLabel(text: "Recent Rounds")
                    if completedRounds.isEmpty {
                        Text("No rounds yet.")
                            .font(HappyFont.bodyLight(size: 14))
                            .foregroundColor(.happyMuted)
                            .italic()
                    } else {
                        ForEach(completedRounds.prefix(3)) { tt in
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
                                if let score = tt.score {
                                    Text("\(score)")
                                        .font(HappyFont.displayMedium(size: 20))
                                        .foregroundColor(.happyGreen)
                                }
                            }
                            .padding(.vertical, HappySpacing.xs)
                        }
                    }
                }

                HappyDivider()

                // Sign Out
                Button {
                    Task { await authManager.signOut() }
                } label: {
                    Text("Sign Out")
                        .font(HappyFont.bodyMedium(size: 14))
                        .foregroundColor(.red.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(Capsule().stroke(Color.red.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
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

    private func ratingPill(_ rating: Double) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 9))
                .foregroundColor(.happyAccent)
            Text(String(format: "%.1f", rating))
                .font(HappyFont.bodyMedium(size: 12))
                .foregroundColor(.happyGreenLight)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 12)
        .background(Color.happyAccent.opacity(0.1))
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

    private func accoladeChip(_ accolade: Accolade) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(accolade.type.emoji).font(.system(size: 18))
                Text(accolade.type.displayName)
                    .font(HappyFont.bodyMedium(size: 12))
                    .foregroundColor(.happyBlack)
                    .lineLimit(1)
                Spacer()
            }
            if accolade.verifications.isEmpty {
                Text("Awaiting verification")
                    .font(HappyFont.metaTiny)
                    .foregroundColor(.happyMuted)
                    .italic()
            } else {
                HStack(spacing: 2) {
                    Text("✓ ")
                        .font(HappyFont.metaTiny)
                        .foregroundColor(.happyGreenLight)
                    ForEach(Array(accolade.verifications.prefix(2).enumerated()), id: \.element.id) { idx, ver in
                        Button {
                            selectedMemberId = ver.verifierId
                        } label: {
                            Text(appState.profileCache[ver.verifierId]?.name ?? "Member")
                                .font(HappyFont.bodyMedium(size: 11))
                                .foregroundColor(.happyGreen)
                                .underline()
                        }
                        if idx < min(accolade.verifications.count, 2) - 1 {
                            Text(",").font(HappyFont.metaTiny).foregroundColor(.happyMuted)
                        }
                    }
                }
            }
        }
        .padding(HappySpacing.sm)
        .background(Color.happyWhite.opacity(0.6))
        .cornerRadius(HappyRadius.card)
        .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
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

// Wrapper to make UUID sheet-presentable (shared via this file)
struct MemberIDWrapper: Identifiable {
    let id: UUID
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
