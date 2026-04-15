import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @EnvironmentObject var appState: AppState

    @State private var step = 1
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var handicap = ""
    @State private var industry = ""
    @State private var pace: PacePref = .standard
    @State private var homeCourse = ""

    // Photo
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarData: Data?
    @State private var avatarImage: Image?

    private var fullName: String {
        "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))"
            .trimmingCharacters(in: .whitespaces)
    }

    private var cleanUsername: String {
        username.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private var isStep1Valid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !cleanUsername.isEmpty &&
        Double(handicap) != nil
    }

    private var isStep2Valid: Bool {
        !industry.trimmingCharacters(in: .whitespaces).isEmpty &&
        !homeCourse.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack(alignment: .center) {
                    if step == 2 {
                        Button {
                            withAnimation(.easeOut(duration: 0.3)) { step = 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.happyGreen)
                        }
                    } else {
                        Spacer().frame(width: 20)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        progressPill(active: step >= 1)
                        progressPill(active: step >= 2)
                    }

                    Spacer()
                    Spacer().frame(width: 36)
                }
                .padding(.horizontal, HappySpacing.xl)
                .padding(.top, HappySpacing.xl)
                .padding(.bottom, HappySpacing.lg)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        if step == 1 {
                            stepOne
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        } else {
                            stepTwo
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }
                    }
                    .padding(.horizontal, HappySpacing.xl)
                    .padding(.bottom, 100)
                }

                // Bottom CTA
                VStack(spacing: 0) {
                    HappyDivider()
                    VStack(spacing: HappySpacing.sm) {
                        HappyPrimaryButton(
                            title: step == 1 ? "Continue →" : "Join Happy →",
                            fullWidth: true
                        ) {
                            if step == 1 {
                                withAnimation(.easeOut(duration: 0.3)) { step = 2 }
                            } else {
                                Task { await appState.createProfile(
                                    name: fullName,
                                    username: cleanUsername,
                                    handicap: Double(handicap) ?? 0,
                                    industry: industry,
                                    pace: pace,
                                    homeCourse: homeCourse,
                                    avatarData: avatarData
                                )}
                            }
                        }
                        .opacity((step == 1 && !isStep1Valid) || (step == 2 && !isStep2Valid) ? 0.4 : 1)
                        .disabled((step == 1 && !isStep1Valid) || (step == 2 && !isStep2Valid))
                    }
                    .padding(.horizontal, HappySpacing.xl)
                    .padding(.vertical, HappySpacing.lg)
                    .background(Color.happyCream)
                }
            }
        }
        .onChange(of: selectedPhoto) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    avatarData = data
                    if let uiImage = UIImage(data: data) {
                        avatarImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }

    // MARK: - Step 1

    private var stepOne: some View {
        VStack(alignment: .leading, spacing: 0) {
            HappySectionLabel(text: "Step 1 of 2")
                .padding(.bottom, HappySpacing.md)

            Text("Tell us about\nyour game.")
                .font(HappyFont.displayHeadline(size: 42))
                .foregroundColor(.happyGreen)
                .lineSpacing(4)
                .padding(.bottom, HappySpacing.xs)

            Text("We review every application personally.")
                .font(HappyFont.bodyLight(size: 14))
                .foregroundColor(.happyMuted)
                .padding(.bottom, HappySpacing.xxl)

            // Photo picker
            HStack {
                Spacer()
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(Color.happySandLight)
                            .frame(width: 88, height: 88)

                        if let avatarImage {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 88, height: 88)
                                .clipShape(Circle())
                        } else {
                            VStack(spacing: 4) {
                                Image(systemName: "camera")
                                    .font(.system(size: 22))
                                    .foregroundColor(.happyGreen)
                                Text("Add Photo")
                                    .font(HappyFont.bodyMedium(size: 11))
                                    .foregroundColor(.happyGreen)
                            }
                        }

                        Circle()
                            .stroke(Color.happySand, lineWidth: 1)
                            .frame(width: 88, height: 88)
                    }
                }
                Spacer()
            }
            .padding(.bottom, HappySpacing.xl)

            VStack(spacing: HappySpacing.md) {
                HStack(spacing: HappySpacing.sm) {
                    HappyTextField(
                        label: "First Name",
                        placeholder: "First",
                        text: $firstName,
                        isRequired: true
                    )
                    HappyTextField(
                        label: "Last Name",
                        placeholder: "Last",
                        text: $lastName,
                        isRequired: true
                    )
                }

                // TODO: Username is collected pre-approval so we have a unique identifier
                // for the admin dashboard. Move this to post-approval onboarding when
                // the membership flow is more mature.
                VStack(alignment: .leading, spacing: 4) {
                    HappyTextField(
                        label: "Username",
                        placeholder: "e.g. alexschein",
                        text: $username,
                        isRequired: true
                    )
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
        }
    }

    // MARK: - Step 2

    private var stepTwo: some View {
        VStack(alignment: .leading, spacing: 0) {
            HappySectionLabel(text: "Step 2 of 2")
                .padding(.bottom, HappySpacing.md)

            Text("A little more\nabout you.")
                .font(HappyFont.displayHeadline(size: 42))
                .foregroundColor(.happyGreen)
                .lineSpacing(4)
                .padding(.bottom, HappySpacing.xs)

            Text("This helps hosts find you — and you find them.")
                .font(HappyFont.bodyLight(size: 14))
                .foregroundColor(.happyMuted)
                .padding(.bottom, HappySpacing.xxl)

            VStack(spacing: HappySpacing.md) {
                HappyTextField(
                    label: "Industry",
                    placeholder: "e.g. Finance, Tech, Law",
                    text: $industry,
                    isRequired: true
                )
                CourseSearchField(label: "Home Course *", courseName: $homeCourse)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Pace of Play".uppercased())
                        .font(HappyFont.formLabel)
                        .tracking(1.4)
                        .foregroundColor(.happyGreen)
                    HappyPaceSelector(selection: $pace)
                }
            }
        }
    }

    private func progressPill(active: Bool) -> some View {
        Capsule()
            .fill(active ? Color.happyGreen : Color.happySandLight)
            .frame(width: active ? 28 : 10, height: 10)
            .animation(.easeOut(duration: 0.25), value: active)
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(AppState())
}
