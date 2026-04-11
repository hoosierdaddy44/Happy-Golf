# Happy — Product Requirements Document

**Version:** 1.1
**Status:** MVP In Progress
**Platform:** iOS (SwiftUI)
**Markets:** NYC & South Florida Beta

---

## 1. Product Vision

Happy is a private, curated golf social network for professionals who take both their game and their network seriously. It exists because golf is one of the highest-signal professional and social environments in the world — but the current booking experience (random pairings, public courses, strangers) destroys the value of the round before it starts.

**Happy's promise:** No randoms. No awkward pairings. Ever.

Members build a verified golf profile — handicap, pace of play, industry, interests — and use it to host or join curated tee times with people worth knowing. Every round is intentional. Every group is approved by the host. Over time, members build a reputation that opens better doors: better rounds, better courses, better rooms.

The app targets professionals in their **20s–40s**, primarily in NYC and South Florida, who golf regularly and want to turn rounds into meaningful relationships — without the friction of random pairings or the stiffness of traditional golf club networking.

**Tagline:** Golf on your terms.

---

## 2. Full Feature Universe

### 2.1 Core Profile
- Name, photo, handicap index, home course(s), pace preference (Fast / Standard / Chill)
- Industry, company, and professional interests
- Member since date, total Happy rounds played
- Happy Tour Card — verified score record showing verified low rounds (earned)
- Reputation score built from host ratings and attendance history

### 2.2 Authentication
- **Sign in with Apple** (primary — App Store requires this if any other OAuth is offered)
- **Email magic link** via Supabase (fallback / invite flow)
- Invite-only gate: members must be on the approved list before onboarding completes
- Backend: Supabase (`supabase-swift` SDK)

### 2.3 Tee Time Hosting
- Create a tee time: date, course name, tee time, open spots, walking/riding, notes
- Set group criteria (handicap range, pace, verified-only)
- Review and approve or decline join requests
- Cancel or reschedule a tee time
- Post-round: rate attendees, add a score entry

### 2.4 Tee Time Discovery & Joining
- Feed of open tee times in card format
- Filter by date, course, handicap range, pace, spots available
- Handicap-tiered recommendations — only surface rounds within your skill band
- View host profile and existing players before requesting
- Request to join with a personal note
- Push notification on approval/decline

### 2.5 Social Feed / Activity Layer
- Recent activity: new tee times, join confirmations, new member welcomes
- Round completion cards
- Happy Tour Card moments

### 2.6 Matchmaking & Discovery
- Handicap-based matching: ±5 strokes default
- Networking mode: filter by industry
- Suggested connections based on round history

### 2.7 Course Partnership Portal (Future)
- Verified courses list available slots directly on Happy
- Course-level reviews and ratings

### 2.8 In-App Messaging (Future)
- Direct message between matched golfers
- Group thread for a confirmed tee time
- Pre-round intro note from host

### 2.9 Ratings & Reviews (Future)
- Post-round ratings: pace, attitude, skill match, overall
- Flagging system for no-shows and bad actors

### 2.10 Leaderboards & Round History (Future)
- All-time rounds played, best net scores
- Season leaderboards within your Happy network

### 2.11 Premium Tier (Future)
- Priority access to high-demand tee times
- Partner course slots before general members
- Enhanced profile: verified employment, LinkedIn connect
- Advanced networking filters

---

## 3. MVP Scope

The MVP proves the core value loop: **auth → profile → find a round → host or join → see activity**.

### Included in MVP

#### 3.1 Authentication (Supabase)
- Sign in with Apple (primary, cleanest UX on iOS)
- Email magic link (fallback)
- New user → profile setup flow
- Returning user → lands on Discovery

#### 3.2 Profile Creation
- 2-step setup: (1) name + handicap, (2) industry + pace + home course
- Profile view: all fields, round stats

#### 3.3 Discovery — Browse Open Tee Times
- Card feed of open rounds
- Filter: today / this week / all
- Tap → full tee time detail

#### 3.4 Host a Tee Time
- Form: course, date, time, open spots (1–3), walking/riding, notes
- Hosted round appears in discovery feed
- Host approves/declines join requests

#### 3.5 Request to Join
- "Request to Join" CTA on detail screen
- Optional personal note
- States: Pending / Approved / Declined

#### 3.6 Activity Feed
- Chronological: new tee times, requests, approvals, declines

---

## 4. Out of Scope for MVP

- Course partnership portal
- In-app messaging
- Post-round ratings and reviews
- Leaderboards and round history
- Handicap-tiered filtering (all open rounds shown)
- Networking mode / industry filter
- Premium tier
- Push notifications
- Live Supabase data sync (MVP uses mock data; auth is real)

---

## 5. Data Model

### User
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | from Supabase auth |
| name | String | |
| handicapIndex | Double | 0.0–54.0 |
| industry | String | e.g. "Finance" |
| interests | [String] | |
| pacePreference | PacePref | .fast / .standard / .chill |
| homeCourses | [String] | |
| avatarColor | String | hex |
| joinedAt | Date | |

### TeeTime
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| hostId | UUID | → User |
| courseName | String | |
| courseLocation | String | |
| date | Date | |
| teeTimeString | String | e.g. "7:24 AM" |
| openSpots | Int | |
| totalSpots | Int | |
| carryMode | CarryMode | .walking / .riding |
| notes | String? | |
| players | [UUID] | confirmed |
| createdAt | Date | |

### JoinRequest
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| teeTimeId | UUID | |
| requesterId | UUID | |
| note | String? | |
| status | RequestStatus | .pending / .approved / .declined |
| createdAt | Date | |

### ActivityEvent
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| type | ActivityType | .newTeeTime / .requestSent / .approved / .declined |
| actorId | UUID | |
| teeTimeId | UUID? | |
| createdAt | Date | |

---

## 6. Tech Stack

| Layer | Choice | Notes |
|-------|--------|-------|
| UI | SwiftUI | iOS 17+ |
| Auth | Supabase (`supabase-swift`) | Sign in with Apple primary, email magic link fallback |
| Database | Supabase (Postgres) | MVP uses local mock; Supabase schema ready |
| State | `ObservableObject` / `@EnvironmentObject` | Single AppState |
| Fonts | Playfair Display + Instrument Sans | Bundled from Google Fonts |

---

## 7. Screen List

| # | Screen | Description |
|---|--------|-------------|
| 1 | **Welcome / Splash** | Happy branding, Sign in with Apple + email magic link CTA |
| 2 | **Email Auth** | Magic link entry + confirmation screen |
| 3 | **Profile Setup — Step 1** | Name, handicap index |
| 4 | **Profile Setup — Step 2** | Industry, pace preference, home course |
| 5 | **Profile** | Your profile: stats, handicap, rounds |
| 6 | **Discovery Feed** | Browse open tee times as round cards |
| 7 | **Tee Time Detail** | Full round detail + join request CTA |
| 8 | **Host a Round** | Form to post a new tee time |
| 9 | **My Rounds** | Hosted + joined rounds, approve/decline requests |
| 10 | **Activity Feed** | Chronological activity stream |
| 11 | **Main Tab Bar** | Discovery / Host / My Rounds / Activity / Profile |
