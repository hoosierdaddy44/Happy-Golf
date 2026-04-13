import SwiftUI

struct PlayerSearchView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var query = ""
    @State private var results: [User] = []
    @State private var isSearching = false
    @State private var selectedUserId: UUID?

    private var currentUserId: UUID? { appState.currentUser?.id }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.happySand)
                    .frame(width: 36, height: 4)
                    .padding(.top, HappySpacing.md)
                    .padding(.bottom, HappySpacing.lg)

                // Header
                VStack(alignment: .leading, spacing: HappySpacing.xs) {
                    HappySectionLabel(text: "Happy Golf")
                    Text("Find Players")
                        .font(HappyFont.displayHeadline(size: 34))
                        .foregroundColor(.happyGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, HappySpacing.xl)
                .padding(.bottom, HappySpacing.lg)

                // Search field
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

                // Results
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
                                if member.id != currentUserId {
                                    memberRow(member)
                                }
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
        .sheet(item: Binding(
            get: { selectedUserId.map { MemberIDWrapper(id: $0) } },
            set: { selectedUserId = $0?.id }
        )) { wrapper in
            MemberProfileView(userId: wrapper.id).environmentObject(appState)
        }
    }

    private func memberRow(_ member: User) -> some View {
        Button { selectedUserId = member.id } label: {
            HStack(spacing: HappySpacing.sm) {
                HappyAvatar(user: member, size: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text(member.name)
                        .font(HappyFont.displayMedium(size: 15))
                        .foregroundColor(.happyGreen)
                    HStack(spacing: 6) {
                        if !member.username.isEmpty {
                            Text("@\(member.username)")
                                .font(HappyFont.bodyLight(size: 12))
                                .foregroundColor(.happyMuted)
                            Text("·")
                                .font(HappyFont.bodyLight(size: 12))
                                .foregroundColor(.happyMuted)
                        }
                        Text("HCP \(member.handicapDisplay)")
                            .font(HappyFont.bodyLight(size: 12))
                            .foregroundColor(.happyMuted)
                        if !member.industry.isEmpty {
                            Text("· \(member.industry)")
                                .font(HappyFont.bodyLight(size: 12))
                                .foregroundColor(.happyMuted)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.happyMuted)
            }
            .padding(HappySpacing.md)
            .background(Color.happyWhite)
            .cornerRadius(HappyRadius.card)
            .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var searchTask: Task<Void, Never>?

    private func debounceSearch() {
        searchTask?.cancel()
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
