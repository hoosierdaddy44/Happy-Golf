import SwiftUI

// MARK: - Section Label

struct HappySectionLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .frame(width: 20, height: 1)
                .foregroundColor(.happyGreenLight)
            Text(text.uppercased())
                .font(HappyFont.sectionLabel)
                .tracking(2.2)
                .foregroundColor(.happyGreenLight)
        }
    }
}

// MARK: - Pill Badge

struct HappyBadge: View {
    let text: String
    var style: HappyBadgeStyle = .default
    var showDot: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if showDot {
                PulseDot()
            }
            Text(text.uppercased())
                .font(HappyFont.bodyMedium(size: style.fontSize))
                .tracking(style.letterSpacing * style.fontSize / 10)
                .foregroundColor(style.foreground)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, showDot ? 14 : 12)
        .background(style.background)
        .overlay(
            Capsule().stroke(style.border, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

struct HappySpotsBadge: View {
    let count: Int

    var body: some View {
        Text("\(count) \(count == 1 ? "spot" : "spots") open")
            .font(HappyFont.bodyMedium(size: 11))
            .tracking(0.6)
            .foregroundColor(.happyGreenLight)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.happyGreenLight.opacity(0.1))
            .overlay(Capsule().stroke(Color.happyGreenLight.opacity(0.2), lineWidth: 1))
            .clipShape(Capsule())
    }
}

// MARK: - Pulse Dot

struct PulseDot: View {
    @State private var pulsing = false

    var body: some View {
        Circle()
            .frame(width: 6, height: 6)
            .foregroundColor(.happyGreenLight)
            .opacity(pulsing ? 0.4 : 1)
            .scaleEffect(pulsing ? 0.8 : 1)
            .onAppear {
                withAnimation(HappyAnimation.pulse) {
                    pulsing = true
                }
            }
    }
}

// MARK: - Primary Button

struct HappyPrimaryButton: View {
    let title: String
    var fullWidth: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(HappyFont.buttonLabel)
                .tracking(0.8)
                .foregroundColor(.happyCream)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .padding(.vertical, 14)
                .padding(.horizontal, fullWidth ? 0 : 28)
                .background(Color.happyGreen)
                .clipShape(Capsule())
        }
        .buttonStyle(HappyButtonPressStyle())
    }
}

struct HappyOutlineButton: View {
    let title: String
    var fullWidth: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(HappyFont.buttonLabel)
                .tracking(0.8)
                .foregroundColor(.happyGreen)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .padding(.vertical, 13)
                .padding(.horizontal, fullWidth ? 0 : 28)
                .overlay(
                    Capsule().stroke(Color.happySand, lineWidth: 1)
                )
        }
        .buttonStyle(HappyButtonPressStyle())
    }
}

// Button press style
struct HappyButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Text Field

struct HappyTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isRequired: Bool = false
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                Text(label.uppercased())
                    .font(HappyFont.formLabel)
                    .tracking(1.4)
                    .foregroundColor(.happyGreen)
                if isRequired {
                    Text("*")
                        .font(HappyFont.formLabel)
                        .foregroundColor(.happyAccent)
                }
            }
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .font(HappyFont.bodyRegular(size: 14))
            .foregroundColor(.happyBlack)
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .background(Color.happyCream)
            .cornerRadius(HappyRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: HappyRadius.input)
                    .stroke(Color.happySandLight, lineWidth: 1)
            )
        }
    }
}

// MARK: - Avatar

struct HappyAvatar: View {
    let user: User
    var size: CGFloat = 34

    var body: some View {
        Group {
            if let data = user.avatarImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Text(user.initials)
                    .font(.custom("PlayfairDisplay-Medium", size: size * 0.38))
                    .foregroundColor(.happyWhite)
                    .frame(width: size, height: size)
                    .background(user.avatarColor)
                    .clipShape(Circle())
            }
        }
    }
}

struct OpenSpotAvatar: View {
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                .foregroundColor(.happySand)
                .frame(width: size, height: size)
            Text("+")
                .font(HappyFont.bodyRegular(size: size * 0.4))
                .foregroundColor(.happySand)
        }
    }
}

// MARK: - Card

struct HappyCard<Content: View>: View {
    var showTopBar: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(HappySpacing.xl)
            .background(Color.happyWhite)
            .cornerRadius(HappyRadius.cardLarge)
            .overlay(
                RoundedRectangle(cornerRadius: HappyRadius.cardLarge)
                    .stroke(Color.happySandLight, lineWidth: 1)
            )
            .shadow(
                color: HappyShadow.card.color,
                radius: HappyShadow.card.radius,
                x: HappyShadow.card.x,
                y: HappyShadow.card.y
            )

            if showTopBar {
                HappyGradient.cardTopBar
                    .frame(height: 3)
                    .cornerRadius(HappyRadius.cardLarge, corners: [.topLeft, .topRight])
            }
        }
    }
}

// Corner radius helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Pace Selector

struct HappyPaceSelector: View {
    @Binding var selection: PacePref

    var body: some View {
        HStack(spacing: 8) {
            ForEach(PacePref.allCases, id: \.self) { pace in
                let isSelected = selection == pace
                Button {
                    selection = pace
                } label: {
                    VStack(spacing: 4) {
                        Text(pace.emoji)
                            .font(.system(size: 18))
                        Text(pace.rawValue)
                            .font(HappyFont.bodyMedium(size: 11))
                            .foregroundColor(isSelected ? .happyGreen : .happyMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isSelected ? Color.happyGreen.opacity(0.05) : Color.happyCream)
                    .cornerRadius(HappyRadius.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: HappyRadius.input)
                            .stroke(isSelected ? Color.happyGreen : Color.happySandLight, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Divider

struct HappyDivider: View {
    var body: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(.happySandLight)
    }
}

// MARK: - Meta Item (date/time/mode chip)

struct HappyMetaItem: View {
    let emoji: String
    let label: String

    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.happyCream)
                    .frame(width: 26, height: 26)
                Text(emoji)
                    .font(.system(size: 11))
            }
            Text(label)
                .font(HappyFont.metaSmall)
                .foregroundColor(.happyMuted)
        }
    }
}
