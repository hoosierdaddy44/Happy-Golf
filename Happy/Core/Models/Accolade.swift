import Foundation

enum AccoladeType: String, CaseIterable, Codable {
    case eagle         = "eagle"
    case birdieMachine = "birdie_machine"
    case broke80       = "broke_80"
    case broke70       = "broke_70"
    case holeInOne     = "hole_in_one"
    case personalBest  = "personal_best"

    var displayName: String {
        switch self {
        case .eagle:         return "Eagle"
        case .birdieMachine: return "Birdie Machine"
        case .broke80:       return "Broke 80"
        case .broke70:       return "Broke 70"
        case .holeInOne:     return "Hole in One"
        case .personalBest:  return "Personal Best"
        }
    }

    var emoji: String {
        switch self {
        case .eagle:         return "🦅"
        case .birdieMachine: return "🐦"
        case .broke80:       return "🔥"
        case .broke70:       return "💥"
        case .holeInOne:     return "⛳"
        case .personalBest:  return "🏆"
        }
    }

    var description: String {
        switch self {
        case .eagle:         return "Made an eagle on any hole"
        case .birdieMachine: return "Multiple birdies in a single round"
        case .broke80:       return "Shot under 80 gross"
        case .broke70:       return "Shot under 70 gross"
        case .holeInOne:     return "Aced a hole"
        case .personalBest:  return "Best round of your career"
        }
    }
}

struct AccoladeVerification: Identifiable {
    let id: UUID
    let accoladeId: UUID
    let verifierId: UUID
    let createdAt: Date
}

struct Accolade: Identifiable {
    let id: UUID
    let userId: UUID
    let type: AccoladeType
    let teeTimeId: UUID?
    let createdAt: Date
    var verifications: [AccoladeVerification]

    var isVerified: Bool { !verifications.isEmpty }
}

struct RoundRating: Identifiable {
    let id: UUID
    let teeTimeId: UUID
    let raterId: UUID
    let rateeId: UUID
    let score: Int
    let createdAt: Date
}
