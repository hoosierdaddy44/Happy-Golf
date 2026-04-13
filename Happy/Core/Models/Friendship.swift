import Foundation

enum FriendshipStatus: String, Codable {
    case pending  = "pending"
    case accepted = "accepted"
    case declined = "declined"
}

struct Friendship: Identifiable {
    let id: UUID
    let requesterId: UUID
    let addresseeId: UUID
    var status: FriendshipStatus
    let createdAt: Date

    func involves(_ userId: UUID) -> Bool {
        requesterId == userId || addresseeId == userId
    }

    func otherUserId(from myId: UUID) -> UUID {
        requesterId == myId ? addresseeId : requesterId
    }
}
