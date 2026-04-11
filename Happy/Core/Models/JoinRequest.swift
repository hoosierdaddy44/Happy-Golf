import Foundation

struct JoinRequest: Identifiable {
    let id: UUID
    let teeTimeId: UUID
    let requesterId: UUID
    var note: String?
    var status: RequestStatus
    let createdAt: Date

    init(
        id: UUID = UUID(),
        teeTimeId: UUID,
        requesterId: UUID,
        note: String? = nil,
        status: RequestStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.teeTimeId = teeTimeId
        self.requesterId = requesterId
        self.note = note
        self.status = status
        self.createdAt = createdAt
    }
}

enum RequestStatus: String {
    case pending  = "pending"
    case approved = "approved"
    case declined = "declined"
}
