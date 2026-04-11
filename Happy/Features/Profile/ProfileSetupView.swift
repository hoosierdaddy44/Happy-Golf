import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var appState: AppState

    @State private var step = 1
    @State private var name = ""
    @State private var handicap = ""
    @State private var industry = ""
    @State private var pace: PacePref = .standard
    @State private var homeCourse = ""

    private var isStep1Valid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && Double(handicap) != nil }

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

                    // Step progress pills
                    HStack(spacing: 6) {
                        progressPill(active: step >= 1)
                        progressPill(active: step >= 2)
                    }

                    Spacer()

                    // Skip only on step 2
                    if step == 2 {
                        Button("Skip") {
                            appState.createProfile(
                                name: name,
                                handicap: Double(handicap) ?? 0,
                                industry: "",
                                pace: pace,
                                homeCourse: ""
                            )
                        }
                        .font(HappyFont.bodyMedium(size: 13))
                        .foregroundColor(.happyMuted)
                    } else {
                        Spacer().frame(width: 36)
                    }
                }
                .padding(.horizontal, HappySpacing.xl)
                .padding(.top, HappySpacing.xl)
                .padding(.bottom, HappySpacing.lg)

                // Content
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

                // Bottom CTA — pinned
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
                                appState.createProfile(
                                    name: name,
                                    handicap: Double(handicap) ?? 0,
                                    industry: industry,
                                    pace: pace,
                                    homeCourse: homeCourse
                                )
                            }
                        }
                        .opacity((step == 1 && !isStep1Valid) ? 0.4 : 1)
                        .disabled(step == 1 && !isStep1Valid)
                    }
                    .padding(.horizontal, HappySpacing.xl)
                    .padding(.vertical, HappySpacing.lg)
                    .background(Color.happyCream)
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

            VStack(spacing: HappySpacing.md) {
                HappyTextField(
                    label: "Full Name",
                    placeholder: "Your name",
                    text: $name,
                    isRequired: true
                )
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
                    text: $industry
                )
                HappyTextField(
                    label: "Home Course(s)",
                    placeholder: "e.g. Bethpage, Winged Foot",
                    text: $homeCourse
                )

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
