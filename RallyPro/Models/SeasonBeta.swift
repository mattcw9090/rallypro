import Foundation

struct SeasonBeta: Identifiable, Codable {
    var id: String = UUID().uuidString
    var seasonNumber: Int
    var sessions: [SessionBeta]? = nil
    var isComplete: Bool = false
}
