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
        Task { await appState.hostTeeTime(tt) }
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
                openSpots = 2; carryMode = .walking; roundFormat = .strokePlay; selectedGroupId = nil
                withAnimation { submitted = false }
            }
            Spacer()
        }
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
