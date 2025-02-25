import Foundation

struct SessionBeta: Identifiable, Codable {
    var id: String = UUID().uuidString
    var sessionNumber: Int
}
