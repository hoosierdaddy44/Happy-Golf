# Happy Golf — Claude Code Reference

## Project Overview
Happy is a private golf social iOS app. Members create profiles, host tee times, browse and request to join open rounds, and track activity. Auth via Supabase (Sign in with Apple + email magic link).

## Project Structure

```
Happy/
├── PRD.md                          ← Product requirements
├── CLAUDE.md                       ← This file
├── project.yml                     ← xcodegen config (includes Supabase SPM dep)
├── Happy.xcodeproj/
└── Happy/
    ├── App/
    │   ├── HappyApp.swift          ← @main entry point
    │   ├── AppState.swift          ← Central ObservableObject (all state + business logic)
    │   ├── AuthManager.swift       ← Supabase auth (Sign in with Apple, email magic link)
    │   ├── SupabaseClient.swift    ← Shared supabase client instance
    │   ├── RootView.swift          ← Routes based on auth + onboarding state
    │   └── MainTabView.swift       ← Tab bar: Discover / Host / My Rounds / Activity / Profile
    ├── Features/
    │   ├── Auth/
    │   │   ├── WelcomeView.swift   ← Splash: Sign in with Apple + email CTA
    │   │   └── EmailAuthView.swift ← Magic link entry + confirmation
    │   ├── Profile/
    │   │   ├── ProfileSetupView.swift  ← 2-step onboarding
    │   │   └── ProfileView.swift       ← User profile display + sign out
    │   ├── Discovery/
    │   │   └── DiscoveryView.swift ← Browse open tee times (card feed + filters)
    │   ├── TeeTimes/
    │   │   ├── TeeTimeDetailView.swift ← Full tee time + join request sheet
    │   │   ├── HostRoundView.swift     ← Create a new tee time
    │   │   └── MyRoundsView.swift      ← Hosted + joined rounds, approve/decline
    │   └── Feed/
    │       └── ActivityFeedView.swift  ← Chronological activity stream
    ├── Core/
    │   └── Models/
    │       ├── User.swift          ← User model + PacePref enum + mock data
    │       ├── TeeTime.swift       ← TeeTime model + CarryMode enum + mock data
    │       ├── JoinRequest.swift   ← JoinRequest model + RequestStatus enum
    │       └── ActivityEvent.swift ← ActivityEvent model + ActivityType enum + mock data
    └── DesignSystem/
        ├── DesignSystem.swift      ← ALL design tokens (colors, fonts, spacing, radius, shadows, gradients, animation)
        └── Components/
            └── HappyComponents.swift ← Reusable UI components
```

## Architecture
- **Auth:** `AuthManager` (ObservableObject) — Supabase session, Sign in with Apple, email magic link
- **State:** `AppState` (ObservableObject) — all app state + business logic, injected via `.environmentObject()`
- **Routing:** `RootView` checks `authManager.isSignedIn` → `appState.isOnboarded` → routes accordingly
- **Navigation:** NavigationStack + TabView
- **Data:** In-memory mock data for MVP; Supabase schema ready for real data layer
- **Design system:** All tokens in `DesignSystem.swift` — never hardcode colors, fonts, or spacing

## Bundle ID
`com.happy.golf`

## Build & Run

### Requirements
- Xcode 15+
- iOS 17+ deployment target
- Swift Package Manager (Supabase fetched automatically on first build)
- Simulator: iPhone 16 Pro

### Setup
1. Open `Happy.xcodeproj` in Xcode
2. Let SPM resolve `supabase-swift` (first build only)
3. Add your Supabase project URL + anon key to `SupabaseClient.swift`
4. Add font files to `Happy/Resources/Fonts/` and register in `Info.plist` (see Fonts below)
5. Build and run on simulator

### Supabase Config
In `SupabaseClient.swift`, replace the placeholder values with your project credentials from:
`https://supabase.com/dashboard/project/<your-project>/settings/api`

Or set environment variables:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

### Build command (CI)
```bash
xcodebuild -project Happy.xcodeproj \
  -scheme Happy \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build
```

### Regenerate .xcodeproj
```bash
xcodegen generate
```

### MCP Simulator Workflow
For every screen built, use this sequence:
1. `xcodebuild` — build for simulator target
2. `launch_app` — launch in simulator
3. `screenshot` — observe current state
4. `get_ui_hierarchy` — verify accessibility elements
5. `ui_tap` / `ui_swipe` — interact (prefer accessibility labels over coordinates)
6. `screenshot` — confirm visual matches design system
7. Fix any issues, then mark screen complete below

## Design System Quick Reference
| Token | Usage |
|-------|-------|
| `Color.happyGreen` (#1C3D2B) | Primary, CTAs, nav |
| `Color.happyCream` (#F5F0E8) | Page background |
| `Color.happyWhite` (#FDFCFA) | Card surfaces |
| `Color.happyAccent` (#E8A838) | Gold highlights |
| `HappyFont.displayHeadline()` | Playfair Display, all headlines |
| `HappyFont.bodyLight()` | Instrument Sans 300, body copy |
| `HappyRadius.pill` | Badges, buttons |
| `HappyRadius.card` / `.cardLarge` | Cards |
| `HappyGradient.cardTopBar` | 3-stop gradient top bar on cards |

## MVP Screen Completion Checklist

| Screen | Status | Notes |
|--------|--------|-------|
| Welcome / Splash | ✅ Verified | Sign in with Apple + email magic link |
| Email Auth | ✅ Verified | Dev login + Skip Auth bypass |
| Profile Setup Step 1 | ✅ Verified | Name + handicap |
| Profile Setup Step 2 | ✅ Verified | Industry + pace + home course |
| Profile View | ✅ Verified | Stats, HCP badge, pace badge, member since |
| Discovery Feed | ✅ Verified | Card feed + date filters |
| Tee Time Detail | ✅ Verified | Players list + open spots + join request |
| Host a Round | ✅ Verified | Full form: course, date, tee time, spots, carry mode |
| My Rounds | ✅ Verified | Hosting tab + joined tab |
| Activity Feed | ✅ Verified | Chronological event list |
| Main Tab Bar | ✅ Verified | All 5 tabs navigate correctly |

## Fonts
The app uses `Playfair Display` and `Instrument Sans`. To add:
1. Download from Google Fonts
2. Add `.ttf` files to `Happy/Resources/Fonts/` group in Xcode
3. Already registered in `Info.plist` under `UIAppFonts`

Font fallback: `HappyFont` uses `.custom()` — if the font file is missing, iOS falls back to system serif/sans-serif automatically.

## Target Audience
Professionals in their **20s–40s**, NYC & South Florida. No randoms. No awkward pairings. Ever.
