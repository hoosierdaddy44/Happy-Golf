import Foundation

struct TeeTime: Identifiable, Hashable {
    let id: UUID
    var hostId: UUID
    var courseName: String
    var courseLocation: String
    var date: Date
    var teeTimeString: String
    var openSpots: Int
    var totalSpots: Int
    var carryMode: CarryMode
    var notes: String?
    var players: [UUID]
    var requests: [UUID]
    let createdAt: Date

    var confirmedPlayerIds: [UUID] {
        [hostId] + players
    }

    var isFull: Bool { openSpots <= 0 }

    var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    init(
        id: UUID = UUID(),
        hostId: UUID,
        courseName: String,
        courseLocation: String,
        date: Date,
        teeTimeString: String,
        openSpots: Int,
        totalSpots: Int,
        carryMode: CarryMode = .walking,
        notes: String? = nil,
        players: [UUID] = [],
        requests: [UUID] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.hostId = hostId
        self.courseName = courseName
        self.courseLocation = courseLocation
        self.date = date
        self.teeTimeString = teeTimeString
        self.openSpots = openSpots
        self.totalSpots = totalSpots
        self.carryMode = carryMode
        self.notes = notes
        self.players = players
        self.requests = requests
        self.createdAt = createdAt
    }
}

enum CarryMode: String, CaseIterable {
    case walking = "Walking"
    case riding  = "Riding"

    var emoji: String {
        switch self {
        case .walking: return "🚶"
        case .riding:  return "🏎️"
        }
    }
}

// MARK: - Mock Data

extension TeeTime {
    static var mockData: [TeeTime] {
        let cal = Calendar.current
        let now = Date()
        return [
            TeeTime(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
                hostId: User.jamesK.id,
                courseName: "Bethpage Black",
                courseLocation: "Farmingdale, NY",
                date: cal.date(byAdding: .day, value: 9, to: now)!,
                teeTimeString: "7:24 AM",
                openSpots: 2,
                totalSpots: 4,
                carryMode: .walking,
                players: [User.marcusR.id]
            ),
            TeeTime(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
                hostId: User.saraT.id,
                courseName: "Baltusrol Golf Club",
                courseLocation: "Springfield, NJ",
                date: cal.date(byAdding: .day, value: 3, to: now)!,
                teeTimeString: "8:00 AM",
                openSpots: 1,
                totalSpots: 3,
                carryMode: .riding,
                players: [User.davidM.id]
            ),
            TeeTime(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
                hostId: User.davidM.id,
                courseName: "Winged Foot Golf Club",
                courseLocation: "Mamaroneck, NY",
                date: cal.date(byAdding: .day, value: 14, to: now)!,
                teeTimeString: "9:30 AM",
                openSpots: 3,
                totalSpots: 4,
                carryMode: .walking,
                notes: "West Course. Serious players only."
            ),
        ]
    }
}
