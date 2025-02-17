import Foundation
import SwiftData

@Model
class Session {
    var sessionNumber: Int
    var seasonNumber: Int

    @Attribute(.unique)
    var uniqueIdentifier: String

    @Relationship
    var season: Season
    
    @Relationship(inverse: \SessionParticipant.session)
    var participants: [SessionParticipant] = []
    
    var courtCost: Double = 0.0
    var numberOfShuttles: Int = 0
    var costPerShuttle: Double = 0.0

    init(sessionNumber: Int, season: Season) {
        self.sessionNumber = sessionNumber
        self.seasonNumber = season.seasonNumber
        self.uniqueIdentifier = "\(season.seasonNumber)-\(sessionNumber)"
        self.season = season
    }
}
