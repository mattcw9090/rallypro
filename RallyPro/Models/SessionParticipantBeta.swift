import Foundation

enum TeamType: String, Codable, CaseIterable {
    case red = "Red Team"
    case black = "Black Team"
}

struct SessionParticipantBeta: Identifiable, Codable {
    var id: String = UUID().uuidString
    var sessionId: String
    var player: PlayerBeta
    var team: TeamType? // nil means unassigned
}
