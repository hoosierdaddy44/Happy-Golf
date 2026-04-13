import SwiftUI

struct TeeTimeDetailView: View {
    let teeTime: TeeTime
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    enum Sheet: Identifiable {
        case memberProfile(UUID)
        case joinRequest
        case editRound
        var id: String {
            switch self {
            case .memberProfile(let uid): return "member_\(uid)"
            case .joinRequest: return "joinRequest"
            case .editRound: return "editRound"
            }
        }
    }
    @State private var activeSheet: Sheet?

    private var host: User? { appState.user(for: teeTime.hostId) }
    private var confirmedPlayers: [User] { teeTime.confirmedPlayerIds.compactMap { appState.user(for: $0) } }
    private var isCurrentUserHost: Bool { appState.currentUser?.id == teeTime.hostId }
    private var existingRequest: JoinRequest? {
        guard let user = appState.currentUser else { return nil }
        return appState.joinRequests.first { $0.teeTimeId == teeTime.id && $0.requesterId == user.id }
    }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    roundCard
                    ctaSection
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .memberProfile(let uid):
                MemberProfileView(userId: uid).environmentObject(appState)
            case .joinRequest:
                JoinRequestSheet(teeTime: teeTime).environmentObject(appState)
            case .editRound:
                EditRoundSheet(teeTime: teeTime).environmentObject(appState)
            }
        }
    }

    // MARK: - Round Card

    private var roundCard: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                HappyBadge(text: "⛳ Happy Round", style: .gold)
                    .padding(.bottom, HappySpacing.md)

                // Course + spots
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(teeTime.courseName)
                            .font(HappyFont.displayHeadline(size: 28))
                            .foregroundColor(.happyGreen)
                        Text(teeTime.courseLocation)
                            .font(HappyFont.metaSmall)
                            .foregroundColor(.happyMuted)
                    }
                    Spacer()
                    HappySpotsBadge(count: teeTime.openSpots)
                }
                .padding(.bottom, HappySpacing.md)

                HappyDivider()
                    .padding(.bottom, HappySpacing.lg)

                // Meta
                HStack(spacing: HappySpacing.md) {
                    HappyMetaItem(emoji: "📅", label: teeTime.dateDisplay)
                    HappyMetaItem(emoji: "⏰", label: teeTime.teeTimeString)
                    HappyMetaItem(emoji: teeTime.carryMode.emoji, label: teeTime.carryMode.rawValue)
                }
                .padding(.bottom, HappySpacing.xl)

                // Players label
                Text("Players".uppercased())
                    .font(HappyFont.formLabel)
                    .tracking(1.2)
                    .foregroundColor(.happyMuted)
                    .padding(.bottom, HappySpacing.sm)

                // Confirmed players
                VStack(spacing: HappySpacing.sm) {
                    ForEach(confirmedPlayers) { player in
                        playerRow(player)
                    }
                    // Open spots
                    ForEach(0..<teeTime.openSpots, id: \.self) { _ in
                        openSpotRow
                    }
                }

                // Notes
                if let notes = teeTime.notes, !notes.isEmpty {
                    HappyDivider()
                        .padding(.vertical, HappySpacing.md)
                    Text(notes)
                        .font(HappyFont.bodyLight(size: 13))
                        .foregroundColor(.happyMuted)
                        .italic()
                }
            }
            .padding(HappySpacing.xl)
            .background(Color.happyWhite)
            .cornerRadius(HappyRadius.cardLarge)
            .overlay(
                RoundedRectangle(cornerRadius: HappyRadius.cardLarge)
                    .stroke(Color.happySandLight, lineWidth: 1)
            )
            .shadow(color: Color.happyGreen.opacity(0.08), radius: 24, y: 8)

            HappyGradient.cardTopBar
                .frame(height: 3)
                .cornerRadius(HappyRadius.cardLarge, corners: [.topLeft, .topRight])
        }
        .padding(.horizontal, HappySpacing.xl)
        .padding(.top, HappySpacing.xl)
    }

    private func playerRow(_ player: User) -> some View {
        Button {
            activeSheet = .memberProfile(player.id)
        } label: {
            HStack(spacing: 11) {
                HappyAvatar(user: player, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(player.name)
                            .font(HappyFont.bodyMedium(size: 13))
                            .foregroundColor(.happyBlack)
                        if player.id == teeTime.hostId {
                            Text("· Host")
                                .font(HappyFont.bodyLight(size: 11))
                                .foregroundColor(.happyMuted)
                        }
                    }
                    Text("Handicap \(player.handicapDisplay)")
                        .font(HappyFont.metaTiny)
                        .foregroundColor(.happyMuted)
                }
                Spacer()
                Text(player.pacePreference.rawValue)
                    .font(HappyFont.bodyMedium(size: 10))
                    .tracking(0.7)
                    .foregroundColor(.happyGreenLight)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(Color.happyGreenLight.opacity(0.08))
                    .overlay(Capsule().stroke(Color.happyGreenLight.opacity(0.15), lineWidth: 1))
                    .clipShape(Capsule())
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var openSpotRow: some View {
        HStack(spacing: 11) {
            OpenSpotAvatar(size: 38)
            Text("Open — waiting for the right fit")
                .font(HappyFont.bodyLight(size: 13))
                .foregroundColor(.happyMuted)
                .italic()
            Spacer()
        }
    }

    // MARK: - CTA

    @ViewBuilder
    private var ctaSection: some View {
        if isCurrentUserHost && !teeTime.isCompleted {
            VStack(spacing: HappySpacing.sm) {
                HappyPrimaryButton(title: "Edit Round →", fullWidth: true) {
                    activeSheet = .editRound
                }
            }
            .padding(.horizontal, HappySpacing.xl)
            .padding(.top, HappySpacing.xl)
            .padding(.bottom, HappySpacing.section)
        } else if !isCurrentUserHost {
            VStack(spacing: HappySpacing.sm) {
                if teeTime.isFull {
                    Text("Round is full")
                        .font(HappyFont.buttonLabel)
                        .foregroundColor(.happyMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.happySandLight)
                        .clipShape(Capsule())
                } else if let req = existingRequest {
                    switch req.status {
                    case .pending:
                        statusPill(icon: "clock", label: "Request Sent", color: .happyMuted)
                    case .approved:
                        statusPill(icon: "checkmark", label: "You're In", color: .happyGreenLight)
                    case .declined:
                        statusPill(icon: "xmark", label: "Not This Time", color: .happySand)
                    }
                } else {
                    HappyPrimaryButton(title: "Request to Join →", fullWidth: true) {
                        activeSheet = .joinRequest
                    }
                }
            }
            .padding(.horizontal, HappySpacing.xl)
            .padding(.top, HappySpacing.xl)
            .padding(.bottom, HappySpacing.section)
        }
    }

    private func statusPill(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(label)
        }
        .font(HappyFont.buttonLabel)
        .foregroundColor(color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}

// MARK: - Join Request Sheet

struct JoinRequestSheet: View {
    let teeTime: TeeTime
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var note = ""

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Handle
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.happySand)
                        .frame(width: 36, height: 4)
                    Spacer()
                }
                .padding(.top, HappySpacing.md)
                .padding(.bottom, HappySpacing.xl)

                VStack(alignment: .leading, spacing: HappySpacing.sm) {
                    HappySectionLabel(text: "Join Request")
                    Text("Request to join\n\(teeTime.courseName)")
                        .font(HappyFont.displayHeadline(size: 30))
                        .foregroundColor(.happyGreen)
                        .lineSpacing(4)
                    Text("\(teeTime.dateDisplay) · \(teeTime.teeTimeString)")
                        .font(HappyFont.bodyLight(size: 14))
                        .foregroundColor(.happyMuted)
                }
                .padding(.horizontal, HappySpacing.xl)
                .padding(.bottom, HappySpacing.xl)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Note (Optional)".uppercased())
                        .font(HappyFont.formLabel)
                        .tracking(1.4)
                        .foregroundColor(.happyGreen)
                        .padding(.horizontal, HappySpacing.xl)

                    TextEditor(text: $note)
                        .font(HappyFont.bodyRegular(size: 14))
                        .foregroundColor(.happyBlack)
                        .frame(height: 100)
                        .padding(HappySpacing.md)
                        .background(Color.happyCream)
                        .cornerRadius(HappyRadius.input)
                        .overlay(
                            RoundedRectangle(cornerRadius: HappyRadius.input)
                                .stroke(Color.happySandLight, lineWidth: 1)
                        )
                        .padding(.horizontal, HappySpacing.xl)
                }

                Spacer()

                VStack(spacing: HappySpacing.xs) {
                    HappyPrimaryButton(title: "Send Request →", fullWidth: true) {
                        Task { await appState.requestToJoin(teeTime: teeTime, note: note.isEmpty ? nil : note) }
                        dismiss()
                    }
                    HappyOutlineButton(title: "Cancel", fullWidth: true) {
                        dismiss()
                    }
                }
                .padding(.horizontal, HappySpacing.xl)
                .padding(.bottom, HappySpacing.xxxl)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Edit Round Sheet

struct EditRoundSheet: View {
    let teeTime: TeeTime
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var teeTimeHour: Int
    @State private var teeTimeMinute: Int
    @State private var teeTimeAMPM: Int
    @State private var openSpots: Int
    @State private var carryMode: CarryMode
    @State private var tees: String
    @State private var notes: String

    private let teesOptions = ["Championship", "Blue", "White", "Gold", "Red"]

    init(teeTime: TeeTime) {
        self.teeTime = teeTime
        // Parse teeTimeString e.g. "7:30 AM"
        let parts = teeTime.teeTimeString.split(separator: " ")
        let timeParts = (parts.first ?? "7:00").split(separator: ":")
        let hour = Int(timeParts.first ?? "7") ?? 7
        let minute = Int(timeParts.last ?? "0") ?? 0
        let isAM = (parts.last ?? "AM") == "AM"
        _teeTimeHour = State(initialValue: hour)
        _teeTimeMinute = State(initialValue: minute)
        _teeTimeAMPM = State(initialValue: isAM ? 0 : 1)
        _openSpots = State(initialValue: teeTime.openSpots)
        _carryMode = State(initialValue: teeTime.carryMode)
        _tees = State(initialValue: teeTime.tees ?? "Blue")
        _notes = State(initialValue: teeTime.notes ?? "")
    }

    private var teeTimeString: String {
        let ampm = teeTimeAMPM == 0 ? "AM" : "PM"
        return String(format: "%d:%02d %@", teeTimeHour, teeTimeMinute, ampm)
    }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.happySandLight)
                    .frame(width: 36, height: 4)
                    .padding(.top, HappySpacing.md)
                    .padding(.bottom, HappySpacing.xl)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        HappySectionLabel(text: "Edit Round")
                            .padding(.bottom, HappySpacing.xs)
                        Text(teeTime.courseName)
                            .font(HappyFont.displayHeadline(size: 28))
                            .foregroundColor(.happyGreen)
                            .padding(.bottom, HappySpacing.xxl)

                        // Tee Time
                        fieldLabel("Tee Time")
                        HStack(spacing: 4) {
                            wheelPicker("Hour", selection: $teeTimeHour, options: Array(1...12), label: { "\($0)" })
                            Text(":").font(HappyFont.displayMedium(size: 22)).foregroundColor(.happyGreen)
                            wheelPicker("Min", selection: $teeTimeMinute, options: Array(stride(from: 0, through: 55, by: 5)), label: { String(format: "%02d", $0) })
                            wheelPicker("AM/PM", selection: $teeTimeAMPM, options: [0, 1], label: { $0 == 0 ? "AM" : "PM" })
                            Spacer()
                        }
                        .padding(.bottom, HappySpacing.xl)

                        // Open Spots
                        fieldLabel("Open Spots")
                        HStack(spacing: HappySpacing.xs) {
                            ForEach(1...3, id: \.self) { n in
                                Button { openSpots = n } label: {
                                    Text("\(n)")
                                        .font(HappyFont.bodyMedium(size: 14))
                                        .foregroundColor(openSpots == n ? .happyCream : .happyGreen)
                                        .frame(width: 44, height: 44)
                                        .background(openSpots == n ? Color.happyGreen : Color.happyWhite)
                                        .cornerRadius(HappyRadius.card)
                                        .overlay(RoundedRectangle(cornerRadius: HappyRadius.card)
                                            .stroke(Color.happySandLight, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, HappySpacing.xl)

                        // Carry Mode
                        fieldLabel("Carry Mode")
                        HStack(spacing: HappySpacing.xs) {
                            ForEach(CarryMode.allCases, id: \.self) { mode in
                                Button { carryMode = mode } label: {
                                    HStack(spacing: 4) {
                                        Text(mode.emoji)
                                        Text(mode.rawValue)
                                            .font(HappyFont.bodyMedium(size: 12))
                                            .foregroundColor(carryMode == mode ? .happyCream : .happyGreen)
                                    }
                                    .padding(.horizontal, HappySpacing.sm)
                                    .padding(.vertical, 8)
                                    .background(carryMode == mode ? Color.happyGreen : Color.happyWhite)
                                    .cornerRadius(HappyRadius.card)
                                    .overlay(RoundedRectangle(cornerRadius: HappyRadius.card)
                                        .stroke(Color.happySandLight, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, HappySpacing.xl)

                        // Tees
                        fieldLabel("Tees")
                        HStack(spacing: HappySpacing.xs) {
                            ForEach(teesOptions, id: \.self) { t in
                                Button { tees = t } label: {
                                    Text(t)
                                        .font(HappyFont.bodyMedium(size: 12))
                                        .foregroundColor(tees == t ? .happyCream : .happyGreen)
                                        .padding(.horizontal, HappySpacing.sm)
                                        .padding(.vertical, 8)
                                        .background(tees == t ? Color.happyGreen : Color.happyWhite)
                                        .cornerRadius(HappyRadius.card)
                                        .overlay(RoundedRectangle(cornerRadius: HappyRadius.card)
                                            .stroke(Color.happySandLight, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, HappySpacing.xl)

                        // Notes
                        fieldLabel("Notes (Optional)")
                        TextEditor(text: $notes)
                            .font(HappyFont.bodyRegular(size: 14))
                            .foregroundColor(.happyBlack)
                            .frame(height: 80)
                            .padding(HappySpacing.sm)
                            .background(Color.happyWhite)
                            .cornerRadius(HappyRadius.input)
                            .overlay(RoundedRectangle(cornerRadius: HappyRadius.input)
                                .stroke(Color.happySandLight, lineWidth: 1))
                            .padding(.bottom, 100)
                    }
                    .padding(.horizontal, HappySpacing.xl)
                }

                VStack(spacing: 0) {
                    HappyDivider()
                    HappyPrimaryButton(title: "Save Changes →", fullWidth: true) {
                        var updated = teeTime
                        updated.openSpots = openSpots
                        updated.teeTimeString = teeTimeString
                        updated.carryMode = carryMode
                        updated.tees = tees
                        updated.notes = notes.isEmpty ? nil : notes
                        Task { await appState.updateTeeTime(updated) }
                        dismiss()
                    }
                    .padding(.horizontal, HappySpacing.xl)
                    .padding(.vertical, HappySpacing.lg)
                    .background(Color.happyCream)
                }
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(HappyFont.formLabel)
            .tracking(1.4)
            .foregroundColor(.happyGreen)
            .padding(.bottom, HappySpacing.sm)
    }

    private func wheelPicker<T: Hashable>(_ title: String, selection: Binding<T>, options: [T], label: @escaping (T) -> String) -> some View {
        Picker(title, selection: selection) {
            ForEach(options, id: \.self) { opt in
                Text(label(opt)).foregroundColor(.happyGreen).tag(opt)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 72, height: 80)
        .clipped()
    }
}

#Preview {
    NavigationStack {
        TeeTimeDetailView(teeTime: TeeTime.mockData[0])
            .environmentObject({
                let s = AppState()
                s.currentUser = User.jamesK
                s.isOnboarded = true
                return s
            }())
    }
}
