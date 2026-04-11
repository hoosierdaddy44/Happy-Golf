import Foundation

// MARK: - Supabase Row Types
// These Codable structs match the database schema exactly.
// They are converted to the app's model types after fetching.

struct ProfileRow: Codable {
    let id: UUID
    let name: String
    let handicapIndex: Double?
    let industry: String?
    let homeCourses: [String]
    let pacePreference: String
    let memberSince: Date
    let roundsPlayed: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case handicapIndex   = "handicap_index"
        case industry
        case homeCourses     = "home_courses"
        case pacePreference  = "pace_preference"
        case memberSince     = "member_since"
        case roundsPlayed    = "rounds_played"
    }

    func toUser() -> User {
        User(
            id: id,
            name: name,
            handicapIndex: handicapIndex ?? 0,
            industry: industry ?? "",
            pacePreference: PacePref(rawValue: pacePreference.capitalized) ?? .standard,
            homeCourses: homeCourses,
            joinedAt: memberSince
        )
    }
}

struct TeeTimeRow: Codable {
    let id: UUID
    let hostId: UUID
    let courseName: String
    let location: String?
    let teeDate: String      // "2026-04-20"
    let teeTime: String      // "07:24:00"
    let openSpots: Int
    let carryMode: String
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case hostId      = "host_id"
        case courseName  = "course_name"
        case location
        case teeDate     = "tee_date"
        case teeTime     = "tee_time"
        case openSpots   = "open_spots"
        case carryMode   = "carry_mode"
        case notes
        case createdAt   = "created_at"
    }

    func toTeeTime(approvedPlayerIds: [UUID] = []) -> TeeTime {
        let date = Self.parseDate(teeDate) ?? Date()
        let timeDisplay = Self.formatTime(teeTime)
        return TeeTime(
            id: id,
            hostId: hostId,
            courseName: courseName,
            courseLocation: location ?? "",
            date: date,
            teeTimeString: timeDisplay,
            openSpots: openSpots,
            totalSpots: openSpots + 1 + approvedPlayerIds.count,
            carryMode: CarryMode(rawValue: carryMode.capitalized) ?? .walking,
            notes: notes,
            players: approvedPlayerIds,
            createdAt: createdAt
        )
    }

    private static func parseDate(_ str: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "America/New_York")
        return f.date(from: str)
    }

    private static func formatTime(_ str: String) -> String {
        // "07:24:00" → "7:24 AM"
        let parts = str.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return str }
        let hour = parts[0]
        let minute = parts[1]
        let period = hour < 12 ? "AM" : "PM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
}

struct JoinRequestRow: Codable {
    let id: UUID
    let teeTimeId: UUID
    let requesterId: UUID
    let status: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case teeTimeId   = "tee_time_id"
        case requesterId = "requester_id"
        case status
        case createdAt   = "created_at"
    }

    func toJoinRequest() -> JoinRequest {
        JoinRequest(
            id: id,
            teeTimeId: teeTimeId,
            requesterId: requesterId,
            status: RequestStatus(rawValue: status) ?? .pending,
            createdAt: createdAt
        )
    }
}

struct ActivityEventRow: Codable {
    let id: UUID
    let type: String
    let actorId: UUID
    let teeTimeId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case actorId    = "actor_id"
        case teeTimeId  = "tee_time_id"
        case createdAt  = "created_at"
    }

    func toActivityEvent() -> ActivityEvent {
        ActivityEvent(
            id: id,
            type: ActivityType(rawValue: type) ?? .newTeeTime,
            actorId: actorId,
            teeTimeId: teeTimeId,
            createdAt: createdAt
        )
    }
}
