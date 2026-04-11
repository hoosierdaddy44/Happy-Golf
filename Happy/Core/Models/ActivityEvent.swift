import Foundation

struct ActivityEvent: Identifiable {
    let id: UUID
    let type: ActivityType
    let actorId: UUID
    let teeTimeId: UUID?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        type: ActivityType,
        actorId: UUID,
        teeTimeId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.actorId = actorId
        self.teeTimeId = teeTimeId
        self.createdAt = createdAt
    }

    var icon: String {
        switch type {
        case .newTeeTime:   return "⛳"
        case .requestSent:  return "🤝"
        case .approved:     return "✓"
        case .declined:     return "✗"
        }
    }

    var title: String {
        switch type {
        case .newTeeTime:   return "New tee time posted"
        case .requestSent:  return "Request sent"
        case .approved:     return "Request approved"
        case .declined:     return "Request declined"
        }
    }
}

enum ActivityType: String {
    case newTeeTime  = "new_tee_time"
    case requestSent = "request_sent"
    case approved    = "request_approved"
    case declined    = "request_declined"
}

// MARK: - Mock Data

extension ActivityEvent {
    static var mockData: [ActivityEvent] {
        let now = Date()
        let cal = Calendar.current
        return [
            ActivityEvent(
                type: .newTeeTime,
                actorId: User.jamesK.id,
                teeTimeId: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
                createdAt: cal.date(byAdding: .hour, value: -2, to: now)!
            ),
            ActivityEvent(
                type: .newTeeTime,
                actorId: User.saraT.id,
                teeTimeId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
                createdAt: cal.date(byAdding: .hour, value: -5, to: now)!
            ),
            ActivityEvent(
                type: .approved,
                actorId: User.marcusR.id,
                teeTimeId: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
                createdAt: cal.date(byAdding: .hour, value: -8, to: now)!
            ),
        ]
    }
}
