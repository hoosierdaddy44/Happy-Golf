import SwiftUI

// MARK: - Happy Design System
// Single source of truth for all UI tokens.
// Based on Happy Golf Design Language v1.0

// MARK: - Colors

extension Color {
    // Primary palette
    static let happyGreen       = Color(hex: "#1C3D2B") // Primary, nav, CTA
    static let happyGreenMid    = Color(hex: "#2E6045") // Hover states
    static let happyGreenLight  = Color(hex: "#4E8C65") // Labels, accents
    static let happyCream       = Color(hex: "#F5F0E8") // Page background
    static let happySand        = Color(hex: "#C9B99A") // Borders, dividers
    static let happySandLight   = Color(hex: "#E8DDD0") // Card borders
    static let happyWhite       = Color(hex: "#FDFCFA") // Card surfaces
    static let happyBlack       = Color(hex: "#0D0D0D") // Headings, names
    static let happyMuted       = Color(hex: "#7A7870") // Body text, meta
    static let happyAccent      = Color(hex: "#E8A838") // Tour Card, required
    static let happyAccentDark  = Color(hex: "#B8832A") // Gold badge text

    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Typography

enum HappyFont {
    // Playfair Display — display/headline font
    static func displayHeadline(size: CGFloat = 52) -> Font {
        .custom("PlayfairDisplay-Regular", size: size)
    }
    static func displayHeadlineItalic(size: CGFloat = 28) -> Font {
        .custom("PlayfairDisplay-Italic", size: size)
    }
    static func displayMedium(size: CGFloat = 22) -> Font {
        .custom("PlayfairDisplay-Medium", size: size)
    }
    static func displayMediumItalic(size: CGFloat = 22) -> Font {
        .custom("PlayfairDisplay-MediumItalic", size: size)
    }

    // Instrument Sans — body/UI font
    // Note: no static 300 weight exists; use Regular + .fontWeight(.light) for light appearance
    static func bodyLight(size: CGFloat = 15) -> Font {
        .custom("InstrumentSans-Regular", size: size)
    }
    static func bodyRegular(size: CGFloat = 14) -> Font {
        .custom("InstrumentSans-Regular", size: size)
    }
    static func bodyMedium(size: CGFloat = 13) -> Font {
        .custom("InstrumentSans-Medium", size: size)
    }

    // Semantic aliases
    static let heroTitle         = displayHeadline(size: 52)
    static let heroTitleLarge    = displayHeadline(size: 72)
    static let heroSubline       = displayHeadlineItalic(size: 28)
    static let sectionTitle      = displayHeadline(size: 40)
    static let cardTitle         = displayMedium(size: 22)
    static let sectionLabel      = bodyMedium(size: 10)
    static let bodyCopy          = bodyLight(size: 15)
    static let bodySmall         = bodyRegular(size: 13)
    static let metaSmall         = bodyRegular(size: 12)
    static let metaTiny          = bodyRegular(size: 11)
    static let formLabel         = bodyMedium(size: 10)
    static let buttonLabel       = bodyMedium(size: 13)
    static let navLogoText       = displayMedium(size: 20)
}

// MARK: - Spacing

enum HappySpacing {
    static let xs:  CGFloat = 8
    static let sm:  CGFloat = 12
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 20
    static let xl:  CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
    static let section: CGFloat = 64
    static let sectionLg: CGFloat = 80
    static let sectionXl: CGFloat = 100
}

// MARK: - Corner Radius

enum HappyRadius {
    static let icon:       CGFloat = 8   // Nav icon, step icon
    static let input:      CGFloat = 10  // Inputs, small CTA
    static let whyCard:    CGFloat = 12  // Why cards, motion items
    static let card:       CGFloat = 16  // Round cards, form wrap
    static let cardLarge:  CGFloat = 20  // Large cards
    static let section:    CGFloat = 24  // How / Why sections
    static let sectionLg:  CGFloat = 32  // Larger section containers
    static let pill:       CGFloat = 100 // Badges, nav CTA, buttons
}

// MARK: - Shadows

enum HappyShadow {
    struct ShadowConfig {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    static let card = ShadowConfig(
        color: Color.happyGreen.opacity(0.08),
        radius: 16, x: 0, y: 8
    )
    static let roundCard = ShadowConfig(
        color: Color.happyGreen.opacity(0.10),
        radius: 40, x: 0, y: 24
    )
    static let heroCTA = ShadowConfig(
        color: Color.happyGreen.opacity(0.22),
        radius: 16, x: 0, y: 8
    )
    static let heroCTAHover = ShadowConfig(
        color: Color.happyGreen.opacity(0.32),
        radius: 22, x: 0, y: 14
    )
    static let formWrap = ShadowConfig(
        color: Color.black.opacity(0.06),
        radius: 40, x: 0, y: 20
    )
    static let badge = ShadowConfig(
        color: Color.black.opacity(0.05),
        radius: 8, x: 0, y: 2
    )
}

// MARK: - Gradients

enum HappyGradient {
    /// The signature 3-stop top bar used on cards
    static let cardTopBar = LinearGradient(
        colors: [.happyGreen, .happyGreenLight, .happyAccent],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Hero background radial glow
    static let heroBg = RadialGradient(
        colors: [Color.happyGreenMid.opacity(0.07), Color.clear],
        center: .top,
        startRadius: 0,
        endRadius: 400
    )
}

// MARK: - Animation

enum HappyAnimation {
    static let pageLoad     = Animation.easeOut(duration: 0.7)
    static let scrollReveal = Animation.easeOut(duration: 0.55)
    static let buttonHover  = Animation.easeOut(duration: 0.25)
    static let heroCTA      = Animation.easeOut(duration: 0.30)
    static let pulse        = Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)
    static let float        = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)

    /// Staggered delay for page load items
    static func staggerDelay(index: Int) -> Double {
        return 0.08 + Double(index) * 0.09
    }
}

// MARK: - Component Token Structs

struct HappyBadgeStyle {
    let background: Color
    let border: Color
    let foreground: Color
    let fontSize: CGFloat
    let letterSpacing: CGFloat

    static let `default` = HappyBadgeStyle(
        background: .happyWhite,
        border: .happySand,
        foreground: .happyGreen,
        fontSize: 11,
        letterSpacing: 0.12
    )
    static let gold = HappyBadgeStyle(
        background: Color.happyAccent.opacity(0.1),
        border: Color.happyAccent.opacity(0.25),
        foreground: .happyAccentDark,
        fontSize: 10,
        letterSpacing: 0.10
    )
    static let spots = HappyBadgeStyle(
        background: Color.happyGreenLight.opacity(0.10),
        border: Color.happyGreenLight.opacity(0.20),
        foreground: .happyGreenLight,
        fontSize: 11,
        letterSpacing: 0.06
    )
}

// MARK: - Voice & Tone Constants

enum HappyCopy {
    static let heroHeadline       = "Golf on your terms."
    static let heroSubline        = "Where your round becomes your network."
    static let heroTagline        = "No randoms. No awkward pairings. Ever."
    static let heroDescription    = "Happy is a private network for curated golf rounds. Play with people who match your skill, pace, and vibe — and build a reputation that opens better doors."
    static let heroCTA            = "Request Access →"
    static let heroSubNote        = "Limited NYC beta · Members approved individually"
    static let whyLabel           = "Flex on 'Em"
    static let whyTitle           = "Golf is the best networking you're not using."
    static let howTitle           = "Simple enough for a Sunday morning."
    static let formTitle          = "Join Happy."
    static let formSubtitle       = "Tell us about your game. We review every application personally — no bots, no auto-approvals."
    static let formNote           = "Limited NYC & South Florida beta. We're accepting a small number of members to start."
    static let confirmation       = "✓ You're on the list — We'll be in touch soon. Welcome to Happy."
    static let badgeDefault       = "NYC Beta · Invite Only"
    static let roundTag           = "⛳ Happy Round"
    static let openSpotText       = "Open — waiting for the right fit"
}
