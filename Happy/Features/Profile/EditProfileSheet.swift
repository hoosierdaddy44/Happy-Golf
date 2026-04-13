import SwiftUI
import PhotosUI

struct EditProfileSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    // Pre-populated from current user
    @State private var firstName: String
    @State private var lastName: String
    @State private var username: String
    @State private var handicap: String
    @State private var industry: String
    @State private var homeCourse: String
    @State private var pace: PacePref

    @State private var pickerItem: PhotosPickerItem?
    @State private var avatarData: Data?
    @State private var avatarImage: Image?

    @State private var isSaving = false
    @State private var errorMsg: String?

    private var user: User? { appState.currentUser }

    init(user: User) {
        let parts = user.name.split(separator: " ", maxSplits: 1)
        _firstName = State(initialValue: parts.first.map(String.init) ?? "")
        _lastName  = State(initialValue: parts.dropFirst().first.map(String.init) ?? "")
        _username  = State(initialValue: user.username)
        _handicap  = State(initialValue: user.handicapIndex == 0 ? "" : String(format: "%.1f", user.handicapIndex))
        _industry  = State(initialValue: user.industry)
        _homeCourse = State(initialValue: user.homeCourses.first ?? "")
        _pace      = State(initialValue: user.pacePreference)
        if let data = user.avatarImageData, let ui = UIImage(data: data) {
            _avatarImage = State(initialValue: Image(uiImage: ui))
        }
    }

    private var fullName: String {
        "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))"
            .trimmingCharacters(in: .whitespaces)
    }

    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(handicap) != nil &&
        !industry.trimmingCharacters(in: .whitespaces).isEmpty &&
        !homeCourse.trimmingCharacters(in: .whitespaces).isEmpty
    }

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
                HStack {
                    VStack(alignment: .leading, spacing: HappySpacing.xs) {
                        HappySectionLabel(text: "Your Profile")
                        Text("Edit Profile")
                            .font(HappyFont.displayHeadline(size: 30))
                            .foregroundColor(.happyGreen)
                    }
                    Spacer()
                    Button("Cancel") { dismiss() }
                        .font(HappyFont.bodyMedium(size: 14))
                        .foregroundColor(.happyMuted)
                }
                .padding(.horizontal, HappySpacing.xl)
                .padding(.bottom, HappySpacing.lg)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: HappySpacing.lg) {

                        // Photo
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                if let avatarImage {
                                    avatarImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 88, height: 88)
                                        .clipShape(Circle())
                                } else if let data = user?.avatarImageData, let ui = UIImage(data: data) {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 88, height: 88)
                                        .clipShape(Circle())
                                } else if let user {
                                    Text(user.initials)
                                        .font(.custom("PlayfairDisplay-Medium", size: 30))
                                        .foregroundColor(.happyWhite)
                                        .frame(width: 88, height: 88)
                                        .background(user.avatarColor)
                                        .clipShape(Circle())
                                }
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.happyWhite)
                                    .padding(6)
                                    .background(Color.happyGreen)
                                    .clipShape(Circle())
                                    .offset(x: 2, y: 2)
                            }
                            .overlay(Circle().stroke(Color.happySandLight, lineWidth: 1.5))
                        }
                        .onChange(of: pickerItem) { _, item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self) {
                                    avatarData = data
                                    if let ui = UIImage(data: data) {
                                        avatarImage = Image(uiImage: ui)
                                    }
                                }
                            }
                        }

                        HappyDivider()

                        // Name
                        VStack(spacing: HappySpacing.md) {
                            HStack(spacing: HappySpacing.sm) {
                                HappyTextField(label: "First Name", placeholder: "First", text: $firstName, isRequired: true)
                                HappyTextField(label: "Last Name", placeholder: "Last", text: $lastName, isRequired: true)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                HappyTextField(label: "Username", placeholder: "e.g. alexschein", text: $username, isRequired: true)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                Text("Lowercase letters, numbers, and underscores only.")
                                    .font(HappyFont.metaTiny)
                                    .foregroundColor(.happyMuted)
                                    .padding(.leading, 2)
                            }
                            HappyTextField(
                                label: "Handicap Index",
                                placeholder: "e.g. 8.4",
                                text: $handicap,
                                keyboardType: .decimalPad,
                                isRequired: true
                            )
                        }

                        HappyDivider()

                        // About
                        VStack(spacing: HappySpacing.md) {
                            HappyTextField(
                                label: "Industry",
                                placeholder: "e.g. Finance, Tech, Law",
                                text: $industry,
                                isRequired: true
                            )
                            CourseSearchField(label: "Home Course *", courseName: $homeCourse)
                        }

                        HappyDivider()

                        // Pace
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PACE OF PLAY")
                                .font(HappyFont.formLabel)
                                .tracking(1.4)
                                .foregroundColor(.happyGreen)
                            HStack(spacing: HappySpacing.xs) {
                                ForEach(PacePref.allCases, id: \.self) { p in
                                    paceButton(p)
                                }
                            }
                        }

                        if let errorMsg {
                            Text(errorMsg)
                                .font(HappyFont.metaSmall)
                                .foregroundColor(.red.opacity(0.8))
                        }

                        HappyPrimaryButton(title: isSaving ? "Saving…" : "Save Changes →", fullWidth: true) {
                            save()
                        }
                        .opacity(isValid && !isSaving ? 1 : 0.4)
                        .disabled(!isValid || isSaving)
                        .padding(.bottom, HappySpacing.section)
                    }
                    .padding(.horizontal, HappySpacing.xl)
                }
            }
        }
    }

    private func paceButton(_ p: PacePref) -> some View {
        Button { pace = p } label: {
            VStack(spacing: 4) {
                Text(p.emoji).font(.system(size: 22))
                Text(p.rawValue)
                    .font(HappyFont.bodyMedium(size: 12))
                    .foregroundColor(pace == p ? .happyCream : .happyGreen)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(pace == p ? Color.happyGreen : Color.happyCream)
            .cornerRadius(HappyRadius.input)
            .overlay(RoundedRectangle(cornerRadius: HappyRadius.input).stroke(pace == p ? Color.clear : Color.happySandLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: pace)
    }

    private func save() {
        isSaving = true
        Task {
            await appState.updateProfile(
                name: fullName,
                username: username.trimmingCharacters(in: .whitespaces).lowercased(),
                handicap: Double(handicap) ?? 0,
                industry: industry.trimmingCharacters(in: .whitespaces),
                pace: pace,
                homeCourse: homeCourse.trimmingCharacters(in: .whitespaces),
                avatarData: avatarData
            )
            isSaving = false
            dismiss()
        }
    }
}
