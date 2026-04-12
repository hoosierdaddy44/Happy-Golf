import SwiftUI

struct User: Identifiable, Equatable {
    let id: UUID
    var name: String
    var handicapIndex: Double
    var industry: String
    var interests: [String]
    var pacePreference: PacePref
    var homeCourses: [String]
    var avatarColor: Color
    let joinedAt: Date
    var rating: Double?
    var ratingCount: Int

    var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.compactMap { $0.first }.prefix(2)
        return String(letters).uppercased()
    }

    var handicapDisplay: String {
        String(format: "%.1f", handicapIndex)
    }

    var ratingDisplay: String {
        guard let r = rating else { return "—" }
        return String(format: "%.1f", r)
    }

    init(
        id: UUID = UUID(),
        name: String,
        handicapIndex: Double,
        industry: String,
        interests: [String] = [],
        pacePreference: PacePref = .standard,
        homeCourses: [String] = [],
        avatarColor: Color = .happyGreen,
        joinedAt: Date = Date(),
        rating: Double? = nil,
        ratingCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.handicapIndex = handicapIndex
        self.industry = industry
        self.interests = interests
        self.pacePreference = pacePreference
        self.homeCourses = homeCourses
        self.avatarColor = avatarColor
        self.joinedAt = joinedAt
        self.rating = rating
        self.ratingCount = ratingCount
    }
}

enum PacePref: String, CaseIterable {
    case fast     = "Fast"
    case standard = "Standard"
    case chill    = "Chill"

    var emoji: String {
        switch self {
        case .fast:     return "⚡"
        case .standard: return "🕐"
        case .chill:    return "😌"
        }
    }
}

// MARK: - Mock Data

extension User {
    static let jamesK = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "James K.",
        handicapIndex: 4.2,
        industry: "Finance",
        pacePreference: .fast,
        homeCourses: ["Bethpage Black"],
        avatarColor: .happyGreen
    )
    static let marcusR = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Marcus R.",
        handicapIndex: 7.1,
        industry: "Tech",
        pacePreference: .fast,
        homeCourses: ["Winged Foot"],
        avatarColor: .happyGreenLight
    )
    static let saraT = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Sara T.",
        handicapIndex: 12.4,
        industry: "Real Estate",
        pacePreference: .standard,
        homeCourses: ["Baltusrol"],
        avatarColor: .happyAccent
    )
    static let davidM = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "David M.",
        handicapIndex: 9.8,
        industry: "Law",
        pacePreference: .standard,
        homeCourses: ["Shinnecock Hills"],
        avatarColor: .happySand
    )

    static let mockUsers: [User] = [jamesK, marcusR, saraT, davidM]
}
