import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var showCreateSheet = false
    @State private var searchResults: [HappyGroup] = []
    @State private var isSearchLoading = false

    private var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespaces).isEmpty }

    private var myGroups: [HappyGroup] { appState.groups.filter { $0.isMember } }
    private var discoverGroups: [HappyGroup] { appState.groups.filter { !$0.isMember } }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.happyCream.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: HappySpacing.sm) {
                            HappySectionLabel(text: "Happy Golf")
                            Text("Your\nGroups.")
                                .font(HappyFont.displayHeadline(size: 38))
                                .foregroundColor(.happyGreen)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, HappySpacing.xl)
                        .padding(.top, HappySpacing.xl)
                        .padding(.bottom, HappySpacing.xl)

                        // Search
                        HStack(spacing: HappySpacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15))
                                .foregroundColor(.happyMuted)
                            TextField("Search groups", text: $searchText)
                                .font(HappyFont.bodyRegular(size: 15))
                                .foregroundColor(.happyBlack)
                                .autocorrectionDisabled()
                            if isSearchLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else if !searchText.isEmpty {
                                Button { searchText = "" } label: {
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
                        .padding(.bottom, HappySpacing.xl)

                        if isSearching {
                            // Search results
                            if searchResults.isEmpty && !isSearchLoading {
                                VStack(spacing: HappySpacing.md) {
                                    Text("🔍")
                                        .font(.system(size: 40))
                                    Text("No groups found.")
                                        .font(HappyFont.displayMedium(size: 18))
                                        .foregroundColor(.happyGreen)
                                    Text("Try a different name.")
                                        .font(HappyFont.bodyLight(size: 14))
                                        .foregroundColor(.happyMuted)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, HappySpacing.xxl)
                            } else {
                                VStack(alignment: .leading, spacing: HappySpacing.sm) {
                                    Text("RESULTS")
                                        .font(HappyFont.metaSmall)
                                        .tracking(1.4)
                                        .foregroundColor(.happyMuted)
                                        .padding(.horizontal, HappySpacing.xl)
                                    VStack(spacing: HappySpacing.sm) {
                                        ForEach(searchResults) { group in
                                            NavigationLink(destination: GroupDetailView(group: group)) {
                                                GroupCard(group: group)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, HappySpacing.xl)
                                }
                                .padding(.bottom, HappySpacing.xl)
                            }
                        } else {
                            // Normal browse layout
                            if !myGroups.isEmpty {
                                VStack(alignment: .leading, spacing: HappySpacing.sm) {
                                    Text("MY GROUPS")
                                        .font(HappyFont.metaSmall)
                                        .tracking(1.4)
                                        .foregroundColor(.happyMuted)
                                        .padding(.horizontal, HappySpacing.xl)
                                    VStack(spacing: HappySpacing.sm) {
                                        ForEach(myGroups) { group in
                                            NavigationLink(destination: GroupDetailView(group: group)) {
                                                GroupCard(group: group)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, HappySpacing.xl)
                                }
                                .padding(.bottom, HappySpacing.xl)
                            }

                            if !discoverGroups.isEmpty {
                                VStack(alignment: .leading, spacing: HappySpacing.sm) {
                                    Text("DISCOVER")
                                        .font(HappyFont.metaSmall)
                                        .tracking(1.4)
                                        .foregroundColor(.happyMuted)
                                        .padding(.horizontal, HappySpacing.xl)
                                    VStack(spacing: HappySpacing.sm) {
                                        ForEach(discoverGroups) { group in
                                            NavigationLink(destination: GroupDetailView(group: group)) {
                                                GroupCard(group: group)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, HappySpacing.xl)
                                }
                                .padding(.bottom, HappySpacing.xl)
                            }

                            if myGroups.isEmpty && discoverGroups.isEmpty {
                                VStack(spacing: HappySpacing.md) {
                                    Text("⛳")
                                        .font(.system(size: 48))
                                    Text("No groups yet.")
                                        .font(HappyFont.displayMedium(size: 18))
                                        .foregroundColor(.happyGreen)
                                    Text("Create one to start playing with your crew.")
                                        .font(HappyFont.bodyLight(size: 14))
                                        .foregroundColor(.happyMuted)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, HappySpacing.xxl)
                                .padding(.horizontal, HappySpacing.xl)
                            }
                        }

                        Color.clear.frame(height: 100)
                    }
                }
                .onChange(of: searchText) { _, query in
                    let trimmed = query.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty {
                        searchResults = []
                        return
                    }
                    isSearchLoading = true
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
                        guard searchText.trimmingCharacters(in: .whitespaces) == trimmed else { return }
                        searchResults = await appState.searchGroups(query: trimmed)
                        isSearchLoading = false
                    }
                }

                // FAB
                Button {
                    showCreateSheet = true
                } label: {
                    HStack(spacing: HappySpacing.xs) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                        Text("New Group")
                            .font(HappyFont.bodyMedium(size: 14))
                    }
                    .foregroundColor(.happyCream)
                    .padding(.vertical, 14)
                    .padding(.horizontal, HappySpacing.lg)
                    .background(Color.happyGreen)
                    .cornerRadius(HappyRadius.pill)
                    .shadow(color: Color.happyGreen.opacity(0.35), radius: 16, x: 0, y: 8)
                }
                .padding(.trailing, HappySpacing.xl)
                .padding(.bottom, HappySpacing.xl)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateGroupView().environmentObject(appState)
        }
    }
}

private struct GroupCard: View {
    let group: HappyGroup

    var body: some View {
        VStack(alignment: .leading, spacing: HappySpacing.sm) {
            HStack(alignment: .top, spacing: HappySpacing.md) {
                Text(group.emoji)
                    .font(.system(size: 36))
                    .frame(width: 56, height: 56)
                    .background(Color.happyCream)
                    .cornerRadius(HappyRadius.icon)

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(HappyFont.displayMedium(size: 17))
                        .foregroundColor(.happyGreen)
                        .lineLimit(1)
                    Text(group.description)
                        .font(HappyFont.bodyLight(size: 13))
                        .foregroundColor(.happyMuted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: HappySpacing.xs) {
                HappyBadge(text: "\(group.memberCount) members", showDot: false)
                if group.isPrivate {
                    HappyBadge(text: "Private", showDot: false)
                }
                if let role = group.myRole {
                    HappyBadge(text: role == .admin ? "Admin" : "Member", showDot: role == .admin)
                }
                Spacer()
            }
        }
        .padding(HappySpacing.md)
        .background(Color.happyWhite)
        .cornerRadius(HappyRadius.card)
        .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
    }
}

#Preview {
    GroupsView()
        .environmentObject({
            let s = AppState()
            s.devUserId = UUID()
            s.groups = HappyGroup.mockGroups
            return s
        }())
}
