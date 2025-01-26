import Foundation
import SwiftData

@Model
class Player {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var name: String
    var statusRawValue: String
    var waitlistPosition: Int?
    @Attribute var isMale: Bool?
    
    enum PlayerStatus: String, Codable, CaseIterable {
        case playing = "Currently Playing"
        case onWaitlist = "On the Waitlist"
        case notInSession = "Not in Session"
    }
    
    var status: PlayerStatus {
        get { PlayerStatus(rawValue: statusRawValue) ?? .notInSession }
        set { statusRawValue = newValue.rawValue }
    }

    init(id: UUID = UUID(), name: String, status: PlayerStatus = .notInSession, waitlistPosition: Int? = nil, isMale: Bool? = nil) {
        self.id = id
        self.name = name
        self.statusRawValue = status.rawValue
        self.waitlistPosition = waitlistPosition
        self.isMale = isMale
    }
}
