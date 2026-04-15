import SwiftUI

struct GroupDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    let group: HappyGroup

    @State private var members: [GroupMember] = []
    @State private var isLoadingMembers = true
    @State private var showInviteSheet = false

    private var currentGroup: HappyGroup {
        appState.groups.first(where: { $0.id == group.id }) ?? group
    }

    private var rounds: [TeeTime] {
        appState.groupTeeTimes(groupId: group.id)
    }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header Card
                    VStack(alignment: .leading, spacing: HappySpacing.md) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: HappySpacing.sm) {
                                Text(currentGroup.emoji)
                                    .font(.system(size: 52))
                                Text(currentGroup.name)
                                    .font(HappyFont.displayHeadline(size: 28))
                                    .foregroundColor(.happyGreen)
                                    .lineLimit(2)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: HappySpacing.xs) {
                                HappyBadge(text: "\(currentGroup.memberCount) members", showDot: false)
                                if currentGroup.isPrivate {
                                    HappyBadge(text: "Private", showDot: false)
                                }
                            }
                        }

                        if !currentGroup.description.isEmpty {
                            Text(currentGroup.description)
                                .font(HappyFont.bodyLight(size: 14))
                                .foregroundColor(.happyMuted)
                                .lineSpacing(3)
                        }

                        if let role = currentGroup.myRole {
                            HappyBadge(text: role == .admin ? "You're an Admin" : "You're a Member", showDot: role == .admin)
                        }

                        if !currentGroup.isAdmin && !currentGroup.isMember {
                            HappyPrimaryButton(title: "Join Group →", fullWidth: true) {
                                Task { await appState.joinGroup(currentGroup) }
                            }
                        } else if currentGroup.isMember && !currentGroup.isAdmin {
                            HappyOutlineButton(title: "Leave Group", fullWidth: false) {
                                Task {
                                    await appState.leaveGroup(currentGroup)
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding(HappySpacing.xl)
                    .background(Color.happyWhite)
                    .cornerRadius(HappyRadius.cardLarge)
                    .overlay(RoundedRectangle(cornerRadius: HappyRadius.cardLarge).stroke(Color.happySandLight, lineWidth: 1))
                    .padding(.horizontal, HappySpacing.xl)
                    .padding(.top, HappySpacing.lg)

                    HappyDivider()
                        .padding(.horizontal, HappySpacing.xl)
                        .padding(.vertical, HappySpacing.lg)

                    // Rounds
                    VStack(alignment: .leading, spacing: HappySpacing.sm) {
                        HStack {
                            Text("ROUNDS")
                                .font(HappyFont.metaSmall)
                                .tracking(1.4)
                                .foregroundColor(.happyMuted)
                            Spacer()
                        }
                        .padding(.horizontal, HappySpacing.xl)

                        if rounds.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: HappySpacing.sm) {
                                    Text("⛳")
                                        .font(.system(size: 32))
                                    Text("No rounds posted yet.")
                                        .font(HappyFont.bodyLight(size: 14))
                                        .foregroundColor(.happyMuted)
                                        .italic()
                                }
                                Spacer()
                            }
                            .padding(.vertical, HappySpacing.xl)
                        } else {
                            VStack(spacing: HappySpacing.sm) {
                                ForEach(rounds) { teeTime in
                                    NavigationLink(destination: TeeTimeDetailView(teeTime: teeTime)) {
                                        GroupRoundRow(teeTime: teeTime)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, HappySpacing.xl)
                        }
                    }
                    .padding(.bottom, HappySpacing.lg)

                    HappyDivider()
                        .padding(.horizontal, HappySpacing.xl)
                        .padding(.vertical, HappySpacing.lg)

                    // Members
                    VStack(alignment: .leading, spacing: HappySpacing.sm) {
                        HStack {
                            Text("MEMBERS")
                                .font(HappyFont.metaSmall)
                                .tracking(1.4)
                                .foregroundColor(.happyMuted)
                            Spacer()
                            if currentGroup.isAdmin {
                                Button {
                                    showInviteSheet = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.badge.plus")
                                            .font(.system(size: 12))
                                        Text("Invite")
                                            .font(HappyFont.bodyMedium(size: 13))
                                    }
                                    .foregroundColor(.happyGreen)
                                }
                            }
                        }
                        .padding(.horizontal, HappySpacing.xl)

                        if isLoadingMembers {
                            HStack {
                                Spacer()
                                ProgressView().tint(.happyGreen)
                                Spacer()
                            }
                            .padding(.vertical, HappySpacing.xl)
                        } else {
                            VStack(spacing: HappySpacing.xs) {
                                ForEach(members) { member in
                                    GroupMemberListRow(member: member)
                                }
                            }
                            .padding(.horizontal, HappySpacing.xl)
                        }
                    }
                    .padding(.bottom, HappySpacing.section)
                }
            }
        }
        .navigationTitle(currentGroup.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            members = await appState.fetchGroupMembers(groupId: group.id)
            isLoadingMembers = false
        }
        .sheet(isPresented: $showInviteSheet) {
            GroupInviteView(groupId: group.id).environmentObject(appState)
        }
    }
}

private struct GroupRoundRow: View {
    let teeTime: TeeTime

    var body: some View {
        HStack(spacing: HappySpacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(teeTime.courseName)
                    .font(HappyFont.displayMedium(size: 15))
                    .foregroundColor(.happyGreen)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(teeTime.dateDisplay)
                        .font(HappyFont.bodyLight(size: 12))
                        .foregroundColor(.happyMuted)
                    Text("·")
                        .font(HappyFont.bodyLight(size: 12))
                        .foregroundColor(.happyMuted)
                    Text(teeTime.teeTimeString)
                        .font(HappyFont.bodyLight(size: 12))
                        .foregroundColor(.happyMuted)
                }
            }
            Spacer()
            HappyBadge(text: "\(teeTime.openSpots) open", showDot: teeTime.openSpots > 0)
        }
        .padding(HappySpacing.md)
        .background(Color.happyWhite)
        .cornerRadius(HappyRadius.card)
        .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
    }
}

private struct GroupMemberListRow: View {
    @EnvironmentObject var appState: AppState
    let member: GroupMember

    private var user: User? { appState.user(for: member.userId) }

    var body: some View {
        HStack(spacing: HappySpacing.sm) {
            if let u = user {
                HappyAvatar(user: u, size: 40)
            } else {
                Circle()
                    .fill(Color.happySandLight)
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(user?.name ?? "Member")
                    .font(HappyFont.displayMedium(size: 14))
                    .foregroundColor(.happyGreen)
                if let u = user, !u.username.isEmpty {
                    Text("@\(u.username)")
                        .font(HappyFont.bodyLight(size: 12))
                        .foregroundColor(.happyMuted)
                }
            }

            Spacer()

            if member.role == .admin {
                HappyBadge(text: "Admin", showDot: true)
            }
        }
        .padding(.vertical, HappySpacing.xs)
    }
}

struct GroupInviteView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    let groupId: UUID

    @State private var query = ""
    @State private var results: [User] = []
    @State private var isSearching = false
    @State private var invitedIds: Set<UUID> = []

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.happySand)
                    .frame(width: 36, height: 4)
                    .padding(.top, HappySpacing.md)
                    .padding(.bottom, HappySpacing.lg)

                VStack(alignment: .leading, spacing: HappySpacing.xs) {
                    HappySectionLabel(text: "Groups")
                    Text("Invite Members")
                        .font(HappyFont.displayHeadline(size: 34))
                        .foregroundColor(.happyGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, HappySpacing.xl)
                .padding(.bottom, HappySpacing.lg)

                HStack(spacing: HappySpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundColor(.happyMuted)
                    TextField("Search by name or username", text: $query)
                        .font(HappyFont.bodyRegular(size: 15))
                        .foregroundColor(.happyBlack)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                        .onSubmit { runSearch() }
                    if !query.isEmpty {
                        Button { query = ""; results = [] } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.happyMuted)
                        }
                    }
                }
                .padding(.horizontal, HappySpacing.md)
                .padding(.vertical, 12)
                .background(Color.happyWhite)
                .cornerRadius(HappyRadius.input)
                .overlay(RoundedRectangle(cornerRadius: HappyRadius.input).stroke(Color.happySandLight, lineWidth: 1))
                .padding(.horizontal, HappySpacing.xl)
                .padding(.bottom, HappySpacing.lg)

                if isSearching {
                    Spacer()
                    ProgressView().tint(.happyGreen)
                    Spacer()
                } else if results.isEmpty && !query.isEmpty {
                    Spacer()
                    Text("No members found.")
                        .font(HappyFont.bodyLight(size: 14))
                        .foregroundColor(.happyMuted)
                        .italic()
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: HappySpacing.xs) {
                            ForEach(results) { member in
                                let alreadyInvited = invitedIds.contains(member.id)
                                HStack(spacing: HappySpacing.sm) {
                                    HappyAvatar(user: member, size: 46)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(member.name)
                                            .font(HappyFont.displayMedium(size: 15))
                                            .foregroundColor(.happyGreen)
                                        if !member.username.isEmpty {
                                            Text("@\(member.username)")
                                                .font(HappyFont.bodyLight(size: 12))
                                                .foregroundColor(.happyMuted)
                                        }
                                    }
                                    Spacer()
                                    Button {
                                        if !alreadyInvited {
                                            invitedIds.insert(member.id)
                                            Task { await appState.inviteMemberToGroup(userId: member.id, groupId: groupId) }
                                        }
                                    } label: {
                                        Text(alreadyInvited ? "Invited ✓" : "Invite")
                                            .font(HappyFont.bodyMedium(size: 13))
                                            .foregroundColor(alreadyInvited ? .happyMuted : .happyCream)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, HappySpacing.md)
                                            .background(alreadyInvited ? Color.happySandLight : Color.happyGreen)
                                            .cornerRadius(HappyRadius.pill)
                                    }
                                    .disabled(alreadyInvited)
                                }
                                .padding(HappySpacing.md)
                                .background(Color.happyWhite)
                                .cornerRadius(HappyRadius.card)
                                .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, HappySpacing.xl)
                        .padding(.bottom, HappySpacing.section)
                    }
                }
            }
        }
        .onChange(of: query) { _, new in
            if new.isEmpty { results = [] }
            else { debounceSearch() }
        }
    }

    private func debounceSearch() {
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await runSearchAsync()
        }
    }

    private func runSearch() {
        Task { await runSearchAsync() }
    }

    @MainActor
    private func runSearchAsync() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        results = await appState.searchUsers(query: query)
        isSearching = false
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(group: HappyGroup.mockGroup)
            .environmentObject({
                let s = AppState()
                s.devUserId = UUID()
                s.groups = HappyGroup.mockGroups
                return s
            }())
    }
}
