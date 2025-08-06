import Foundation
import SwiftData

enum Team: String, Codable {
    case Red
    case Black
}

@Model
class SessionParticipant {
    @Attribute(.unique)
    var compositeKey: String

    @Relationship
    var session: Session

    @Relationship
    var player: Player

    var teamRawValue: String?
    var team: Team? {
        get {
            if let rawValue = teamRawValue {
                return Team(rawValue: rawValue)
            }
            return nil
        }
        set {
            teamRawValue = newValue?.rawValue
        }
    }
    
    /// The position of the participant within their team (e.g., 0-based index)
    var teamPosition: Int = -1

    var hasPaid: Bool = false

    init(session: Session, player: Player, team: Team? = nil, teamPosition: Int = -1) {
        self.session = session
        self.player = player
        self.teamRawValue = team?.rawValue
        self.teamPosition = teamPosition
        self.compositeKey = "\(session.uniqueIdentifier)-\(player.id)"
    }
}
