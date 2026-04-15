import SwiftUI

struct CreateGroupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var selectedEmoji = "⛳"
    @State private var groupName = ""
    @State private var description = ""
    @State private var isPrivate = false
    @State private var isSubmitting = false

    private let emojiOptions = ["⛳", "🏌️", "🏆", "🌿", "🍺", "🤝", "💼", "🌴", "🎯", "🔥"]

    private var isValid: Bool { !groupName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
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
                    .padding(.bottom, HappySpacing.lg)

                    // Header
                    VStack(alignment: .leading, spacing: HappySpacing.sm) {
                        HappySectionLabel(text: "Groups")
                        Text("Create a\nNew Group.")
                            .font(HappyFont.displayHeadline(size: 34))
                            .foregroundColor(.happyGreen)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, HappySpacing.xl)
                    .padding(.bottom, HappySpacing.xxl)

                    VStack(spacing: HappySpacing.lg) {
                        // Emoji picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Emoji".uppercased())
                                .font(HappyFont.formLabel)
                                .tracking(1.4)
                                .foregroundColor(.happyGreen)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: HappySpacing.xs), count: 5), spacing: HappySpacing.xs) {
                                ForEach(emojiOptions, id: \.self) { emoji in
                                    Button {
                                        selectedEmoji = emoji
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: 26))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 52)
                                            .background(selectedEmoji == emoji ? Color.happyGreen.opacity(0.12) : Color.happyWhite)
                                            .cornerRadius(HappyRadius.input)
                                            .overlay(RoundedRectangle(cornerRadius: HappyRadius.input).stroke(
                                                selectedEmoji == emoji ? Color.happyGreen : Color.happySandLight,
                                                lineWidth: selectedEmoji == emoji ? 1.5 : 1
                                            ))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        HappyDivider()

                        // Group name
                        HappyTextField(label: "Group Name *", placeholder: "e.g. Tri-State Scratch Club", text: $groupName, isRequired: true)

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (Optional)".uppercased())
                                .font(HappyFont.formLabel)
                                .tracking(1.4)
                                .foregroundColor(.happyGreen)
                            TextEditor(text: $description)
                                .font(HappyFont.bodyRegular(size: 14))
                                .foregroundColor(.happyBlack)
                                .scrollContentBackground(.hidden)
                                .frame(height: 88)
                                .padding(HappySpacing.md)
                                .background(Color.happyCream)
                                .cornerRadius(HappyRadius.input)
                                .overlay(RoundedRectangle(cornerRadius: HappyRadius.input).stroke(Color.happySandLight, lineWidth: 1))
                        }

                        HappyDivider()

                        // Private toggle
                        VStack(alignment: .leading, spacing: HappySpacing.sm) {
                            Toggle(isOn: $isPrivate) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Private Group")
                                        .font(HappyFont.displayMedium(size: 15))
                                        .foregroundColor(.happyGreen)
                                    Text("Only members can see rounds posted to this group")
                                        .font(HappyFont.bodyLight(size: 12))
                                        .foregroundColor(.happyMuted)
                                }
                            }
                            .tint(.happyGreen)
                        }
                        .padding(HappySpacing.md)
                        .background(Color.happyWhite)
                        .cornerRadius(HappyRadius.card)
                        .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
                    }
                    .padding(.horizontal, HappySpacing.xl)

                    // CTA
                    HappyPrimaryButton(title: isSubmitting ? "Creating..." : "Create Group →", fullWidth: true) {
                        guard !isSubmitting, isValid else { return }
                        isSubmitting = true
                        Task {
                            await appState.createGroup(
                                name: groupName.trimmingCharacters(in: .whitespaces),
                                description: description.trimmingCharacters(in: .whitespaces),
                                emoji: selectedEmoji,
                                isPrivate: isPrivate
                            )
                            dismiss()
                        }
                    }
                    .opacity(isValid ? 1 : 0.4)
                    .disabled(!isValid || isSubmitting)
                    .padding(.horizontal, HappySpacing.xl)
                    .padding(.top, HappySpacing.xl)
                    .padding(.bottom, HappySpacing.section)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

#Preview {
    CreateGroupView()
        .environmentObject({
            let s = AppState()
            s.devUserId = UUID()
            return s
        }())
}
