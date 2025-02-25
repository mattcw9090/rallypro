import Foundation

struct SeasonBeta: Identifiable, Codable {
    var id: String = UUID().uuidString
    var seasonNumber: Int
    var sessions: [SessionBeta]?
    var isComplete: Bool = false
}
