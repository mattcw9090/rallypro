import Foundation

struct PlayerBeta: Identifiable, Codable {
    let id: String
    var name: String
    var status: PlayerStatus
    var waitlistPosition: Int?
    var isMale: Bool?
    
    init(id: String = UUID().uuidString,
         name: String,
         status: PlayerStatus = .notInSession,
         waitlistPosition: Int? = nil,
         isMale: Bool? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.waitlistPosition = waitlistPosition
        self.isMale = isMale
    }
    
    // Define player statuses.
    enum PlayerStatus: String, Codable, CaseIterable {
        case playing = "Currently Playing"
        case onWaitlist = "On the Waitlist"
        case notInSession = "Not in Session"
    }
}
