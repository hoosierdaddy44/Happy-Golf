import Foundation

struct HappyGroup: Identifiable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var emoji: String
    let createdBy: UUID
    var isPrivate: Bool
    let createdAt: Date
    var memberCount: Int
    var myRole: GroupRole?

    var isMember: Bool { myRole != nil }
    var isAdmin: Bool  { myRole == .admin }
}

struct GroupMember: Identifiable, Equatable {
    let id: UUID
    let groupId: UUID
    let userId: UUID
    var role: GroupRole
    let joinedAt: Date
}

enum GroupRole: String, Codable, Equatable {
    case admin  = "admin"
    case member = "member"
}

extension HappyGroup {
    static let mockGroup = HappyGroup(
        id: UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!,
        name: "Tri-State Scratch Club",
        description: "Single-digit handicaps only. Bethpage, Winged Foot, Baltusrol.",
        emoji: "🏌️",
        createdBy: User.jamesK.id,
        isPrivate: false,
        createdAt: Date(),
        memberCount: 12,
        myRole: .admin
    )

    static let mockGroups: [HappyGroup] = [
        mockGroup,
        HappyGroup(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000002")!,
            name: "Finance Fairways",
            description: "Wall Street meets the fairway. Members from Goldman, Blackstone, Citadel.",
            emoji: "💼",
            createdBy: User.marcusR.id,
            isPrivate: true,
            createdAt: Date(),
            memberCount: 8,
            myRole: .member
        ),
        HappyGroup(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000003")!,
            name: "South Florida Squad",
            description: "Playing the best courses from Boca to Miami.",
            emoji: "🌴",
            createdBy: User.saraT.id,
            isPrivate: false,
            createdAt: Date(),
            memberCount: 15,
            myRole: nil
        ),
    ]
}
