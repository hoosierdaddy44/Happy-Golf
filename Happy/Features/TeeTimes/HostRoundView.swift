import SwiftUI

struct HostRoundView: View {
    @EnvironmentObject var appState: AppState

    @State private var courseName = ""
    @State private var courseLocation = ""
    @State private var date = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    @State private var teeTimeHour = 7
    @State private var teeTimeMinute = 0
    @State private var teeTimeAMPM = 0
    @State private var openSpots = 2
    @State private var carryMode: CarryMode = .walking
    @State private var roundFormat: RoundFormat = .strokePlay
    @State private var tees = "Blue"
    @State private var notes = ""
    @State private var submitted = false
    @State private var selectedGroupId: UUID? = nil
    @State private var invitedFriends: [User] = []
    @State private var showInvitePicker = false

    private let teesOptions = ["Championship", "Blue", "White", "Gold", "Red"]

    private var isValid: Bool { !courseName.trimmingCharacters(in: .whitespaces).isEmpty }

    private var teeTimeString: String {
        let ampm = teeTimeAMPM == 0 ? "AM" : "PM"
        return String(format: "%d:%02d %@", teeTimeHour, teeTimeMinute, ampm)
    }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()
                .onTapGesture { dismissKeyboard() }

            if submitted {
                successView
            } else {
                formView
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Form

    private var formView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: HappySpacing.sm) {
                    HappySectionLabel(text: "Host a Round")
                    Text("Your round,\nyour standards.")
                        .font(HappyFont.displayHeadline(size: 38))
                        .foregroundColor(.happyGreen)
                        .lineSpacing(4)
                }
                .padding(.horizontal, HappySpacing.xl)
                .padding(.top, HappySpacing.xl)
                .padding(.bottom, HappySpacing.xxl)

                VStack(spacing: HappySpacing.lg) {

                    // Course
                    VStack(spacing: HappySpacing.md) {
                        CourseSearchField(label: "Course Name *", courseName: $courseName, location: $courseLocation)
                        if !courseLocation.isEmpty {
                            HappyTextField(label: "Location", placeholder: "e.g. Farmingdale, NY", text: $courseLocation)
                        }
                    }

                    HappyDivider()

                    // Date
                    fieldGroup(label: "Date") {
                        DatePicker("", selection: $date, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(.happyGreen)
                            .padding(.vertical, 11)
                            .padding(.horizontal, HappySpacing.md)
                            .background(Color.happyWhite)
                            .cornerRadius(HappyRadius.input)
                            .overlay(RoundedRectangle(cornerRadius: HappyRadius.input).stroke(Color.happySandLight, lineWidth: 1))
                    }

                    // Tee time
                    fieldGroup(label: "Tee Time") {
                        HStack(spacing: 0) {
                            wheelPicker("Hour", selection: $teeTimeHour, options: Array(1...12), label: { "\($0)" })
                            Text(":").font(HappyFont.displayMedium(size: 20)).foregroundColor(.happyGreen).padding(.horizontal, 4)
                            wheelPicker("Min", selection: $teeTimeMinute, options: Array(stride(from: 0, through: 55, by: 5)), label: { String(format: "%02d", $0) })
                            wheelPicker("AM/PM", selection: $teeTimeAMPM, options: [0, 1], label: { $0 == 0 ? "AM" : "PM" })
                        }
                        .padding(.horizontal, HappySpacing.md)
                        .padding(.vertical, 4)
                        .background(Color.happyWhite)
                        .cornerRadius(HappyRadius.input)
                        .overlay(RoundedRectangle(cornerRadius: HappyRadius.input).stroke(Color.happySandLight, lineWidth: 1))
                    }

                    HappyDivider()

                    // Open spots
                    fieldGroup(label: "Open Spots") {
                        HStack(spacing: HappySpacing.xs) {
                            ForEach(1...3, id: \.self) { n in
                                segmentButton(
                                    label: "\(n)",
                                    selected: openSpots == n,
                                    action: { openSpots = n }
                                )
                            }
                        }
                    }

                    // Tees
                    fieldGroup(label: "Tees") {
                        HStack(spacing: HappySpacing.xs) {
                            ForEach(teesOptions, id: \.self) { t in
                                segmentButton(label: t, selected: tees == t, action: { tees = t })
                            }
                        }
                    }

                    // Carry mode
                    fieldGroup(label: "Carry Mode") {
                        HStack(spacing: HappySpacing.xs) {
                            ForEach(CarryMode.allCases, id: \.self) { mode in
                                segmentButton(
                                    label: "\(mode.emoji) \(mode.rawValue)",
                                    selected: carryMode == mode,
                                    action: { carryMode = mode }
                                )
                            }
                        }
                    }

                    // Round Format
                    fieldGroup(label: "Format") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: HappySpacing.xs) {
                            ForEach(RoundFormat.allCases, id: \.self) { fmt in
                                segmentButton(
                                    label: "\(fmt.emoji) \(fmt.displayName)",
                                    selected: roundFormat == fmt,
                                    action: { roundFormat = fmt }
                                )
                            }
                        }
                    }

                    HappyDivider()

                    // Post to Group
                    let myGroups = appState.groups.filter { $0.isMember }
                    if !myGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Post to Group (Optional)".uppercased())
                                .font(HappyFont.formLabel)
                                .tracking(1.4)
                                .foregroundColor(.happyGreen)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: HappySpacing.xs) {
                                    Button {
                                        selectedGroupId = nil
                                    } label: {
                                        Text("None")
                                            .font(HappyFont.bodyMedium(size: 13))
                                            .foregroundColor(selectedGroupId == nil ? .happyCream : .happyGreen)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, HappySpacing.md)
                                            .background(selectedGroupId == nil ? Color.happyGreen : Color.happyCream)
                                            .cornerRadius(HappyRadius.input)
                                            .overlay(RoundedRectangle(cornerRadius: HappyRadius.input).stroke(selectedGroupId == nil ? Color.clear : Color.happySandLight, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                    ForEach(myGroups) { group in
                                        Button {
                                            selectedGroupId = group.id
                                        } label: {
                                            HStack(spacing: 5) {
                                                Text(group.emoji)
                                                    .font(.system(size: 13))
                                                Text(group.name)
                                                    .font(HappyFont.bodyMedium(size: 13))
                                                    .foregroundColor(selectedGroupId == group.id ? .happyCream : .happyGreen)
                                            }
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, HappySpacing.md)
                                            .background(selectedGroupId == group.id ? Color.happyGreen : Color.happyCream)
                                            .cornerRadius(HappyRadius.input)
                                            .overlay(RoundedRectangle(cornerRadius: HappyRadius.input).stroke(selectedGroupId == group.id ? Color.clear : Color.happySandLight, lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        HappyDivider()
                    }

                    // Invite Friends
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite Friends (Optional)".uppercased())
                            .font(HappyFont.formLabel)
                            .tracking(1.4)
                            .foregroundColor(.happyGreen)

                        if !invitedFriends.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: HappySpacing.sm) {
                                    ForEach(invitedFriends) { friend in
                                        HStack(spacing: 6) {
                                            HappyAvatar(user: friend, size: 28)
                                            Text(friend.name.components(separatedBy: " ").first ?? friend.name)
                                                .font(HappyFont.bodyMedium(size: 12))
                                                .foregroundColor(.happyGreen)
                                            Button {
                                                invitedFriends.removeAll { $0.id == friend.id }
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(.happyMuted)
                                            }
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(Color.happyWhite)
                                        .cornerRadius(HappyRadius.pill)
                                        .overlay(Capsule().stroke(Color.happySandLight, lineWidth: 1))
                                    }
                                }
                            }
                        }

                        Button {
                            showInvitePicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 13))
                                Text(invitedFriends.isEmpty ? "Add Friends" : "Add More")
                                    .font(HappyFont.bodyMedium(size: 13))
                            }
                            .foregroundColor(.happyGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.happyCream)
                            .cornerRadius(HappyRadius.input)
                            .overlay(RoundedRectangle(cornerRadius: HappyRadius.input).stroke(Color.happySandLight, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }

                    HappyDivider()

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (Optional)".uppercased())
                            .font(HappyFont.formLabel)
                            .tracking(1.4)
                            .foregroundColor(.happyGreen)
                        TextEditor(text: $notes)
                            .font(HappyFont.bodyRegular(size: 14))
                            .foregroundColor(.happyBlack)
                            .scrollContentBackground(.hidden)
                            .frame(height: 88)
                            .padding(HappySpacing.md)
                            .background(Color.happyCream)
                            .cornerRadius(HappyRadius.input)
                            .overlay(RoundedRectangle(cornerRadius: HappyRadius.input).stroke(Color.happySandLight, lineWidth: 1))
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") { dismissKeyboard() }
                                        .font(HappyFont.bodyMedium(size: 14))
                                        .foregroundColor(.happyGreen)
                                }
                            }
                    }
                }
                .padding(.horizontal, HappySpacing.xl)

                // CTA
                HappyPrimaryButton(title: "Post Round →", fullWidth: true) {
                    submitRound()
                }
                .opacity(isValid ? 1 : 0.4)
                .disabled(!isValid)
                .padding(.horizontal, HappySpacing.xl)
                .padding(.top, HappySpacing.xl)
                .padding(.bottom, HappySpacing.section)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showInvitePicker) {
            InviteFriendsPickerView(
                alreadySelected: invitedFriends.map { $0.id },
                onAdd: { user in
                    if !invitedFriends.contains(where: { $0.id == user.id }) {
                        invitedFriends.append(user)
                    }
                }
            )
            .environmentObject(appState)
        }
    }

    // MARK: - Sub-components

    private func fieldGroup<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(HappyFont.formLabel)
                .tracking(1.4)
                .foregroundColor(.happyGreen)
            content()
        }
    }

    private func segmentButton(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(HappyFont.bodyMedium(size: 13))
                .foregroundColor(selected ? .happyCream : .happyGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? Color.happyGreen : Color.happyCream)
                .cornerRadius(HappyRadius.input)
                .overlay(RoundedRectangle(cornerRadius: HappyRadius.input).stroke(selected ? Color.clear : Color.happySandLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func wheelPicker<T: Hashable>(_ title: String, selection: Binding<T>, options: [T], label: @escaping (T) -> String) -> some View {
        Picker(title, selection: selection) {
            ForEach(options, id: \.self) { opt in
                Text(label(opt))
                    .foregroundColor(.happyGreen)
                    .tag(opt)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 64, height: 80)
        .clipped()
    }

    // MARK: - Submit

    private func submitRound() {
        guard let user = appState.currentUser else { return }
        let tt = TeeTime(
            hostId: user.id,
            groupId: selectedGroupId,
            courseName: courseName,
            courseLocation: courseLocation,
            date: date,
            teeTimeString: teeTimeString,
            openSpots: openSpots,
            totalSpots: openSpots + 1,
            carryMode: carryMode,
            format: roundFormat,
            tees: tees,
            notes: notes.isEmpty ? nil : notes
        )
        let friendIds = invitedFriends.map { $0.id }
        Task {
            await appState.hostTeeTime(tt)
            if !friendIds.isEmpty, let newTeeTime = appState.teeTimes.first(where: { $0.hostId == tt.hostId && $0.courseName == tt.courseName }) {
                await appState.inviteToRound(teeTimeId: newTeeTime.id, userIds: friendIds)
            }
        }
        withAnimation(.easeOut(duration: 0.4)) { submitted = true }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: HappySpacing.xl) {
            Spacer()
            Text("⛳")
                .font(.system(size: 68))
            VStack(spacing: HappySpacing.sm) {
                Text("Round Posted.")
                    .font(HappyFont.displayHeadline(size: 40))
                    .foregroundColor(.happyGreen)
                Text("Your round is live. Approve requests as they come in.")
                    .font(HappyFont.bodyLight(size: 15))
                    .foregroundColor(.happyMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HappySpacing.xxl)
            }
            HappyOutlineButton(title: "Post Another Round") {
                courseName = ""; courseLocation = ""; notes = ""
                openSpots = 2; carryMode = .walking; roundFormat = .strokePlay; selectedGroupId = nil; invitedFriends = []
                withAnimation { submitted = false }
            }
            Spacer()
        }
    }
}

// MARK: - Invite Friends Picker Sheet

struct InviteFriendsPickerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    let alreadySelected: [UUID]
    let onAdd: (User) -> Void

    @State private var query = ""
    @State private var results: [User] = []
    @State private var isSearching = false
    @State private var addedIds: Set<UUID> = []

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.happySand)
                    .frame(width: 36, height: 4)
                    .padding(.top, HappySpacing.md)
                    .padding(.bottom, HappySpacing.lg)

                HStack {
                    VStack(alignment: .leading, spacing: HappySpacing.xs) {
                        HappySectionLabel(text: "Host a Round")
                        Text("Invite Friends")
                            .font(HappyFont.displayHeadline(size: 34))
                            .foregroundColor(.happyGreen)
                    }
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(HappyFont.bodyMedium(size: 15))
                        .foregroundColor(.happyGreen)
                }
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
                } else if results.isEmpty {
                    Spacer()
                    VStack(spacing: HappySpacing.sm) {
                        Image(systemName: "person.2")
                            .font(.system(size: 36))
                            .foregroundColor(.happySand)
                        Text("Search for members to invite.")
                            .font(HappyFont.bodyLight(size: 14))
                            .foregroundColor(.happyMuted)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: HappySpacing.xs) {
                            ForEach(results) { member in
                                let isAdded = addedIds.contains(member.id) || alreadySelected.contains(member.id)
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
                                        if !isAdded {
                                            addedIds.insert(member.id)
                                            onAdd(member)
                                        }
                                    } label: {
                                        Text(isAdded ? "Added ✓" : "Invite")
                                            .font(HappyFont.bodyMedium(size: 13))
                                            .foregroundColor(isAdded ? .happyMuted : .happyCream)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, HappySpacing.md)
                                            .background(isAdded ? Color.happySandLight : Color.happyGreen)
                                            .cornerRadius(HappyRadius.pill)
                                    }
                                    .disabled(isAdded)
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
            if new.isEmpty { results = [] } else { debounceSearch() }
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
    HostRoundView()
        .environmentObject({
            let s = AppState()
            s.currentUser = User.jamesK
            s.isOnboarded = true
            return s
        }())
}
