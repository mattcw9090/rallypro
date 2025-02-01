import SwiftData
import SwiftUI

class SeasonalResultsManager: ObservableObject {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Returns an aggregated summary of players for the given season.
    /// - Parameter seasonNumber: The season number to compute results for.
    /// - Returns: A sorted array of tuples containing:
    ///   - player: the `Player`
    ///   - sessionCount: the number of sessions attended
    ///   - matchCount: the number of matches the player appeared in
    ///   - finalAverageScore: the computed average (net score adjusted by sessions attended)
    func aggregatedPlayers(forSeasonNumber seasonNumber: Int) -> [(player: Player, sessionCount: Int, matchCount: Int, finalAverageScore: Double)] {
        
        // Dictionary keyed by player ID to accumulate stats.
        var playerStats: [UUID: (player: Player, sessionsAttended: Set<Int>, totalNet: Int, matchCount: Int)] = [:]

        // 1) Fetch all session participants for the season.
        let participantsDescriptor = FetchDescriptor<SessionParticipant>(
            predicate: #Predicate<SessionParticipant> { $0.session.seasonNumber == seasonNumber }
        )
        let participants: [SessionParticipant]
        do {
            participants = try modelContext.fetch(participantsDescriptor)
        } catch {
            print("Error fetching participants for season \(seasonNumber): \(error)")
            return []
        }
        
        // Record sessions attended by each player.
        participants.forEach { participant in
            let pid = participant.player.id
            let sessionNumber = participant.session.sessionNumber
            if var stats = playerStats[pid] {
                stats.sessionsAttended.insert(sessionNumber)
                playerStats[pid] = stats
            } else {
                playerStats[pid] = (participant.player, Set([sessionNumber]), 0, 0)
            }
        }
        
        // 2) Fetch all matches for the season.
        let matchesDescriptor = FetchDescriptor<DoublesMatch>(
            predicate: #Predicate<DoublesMatch> { $0.session.seasonNumber == seasonNumber }
        )
        let matches: [DoublesMatch]
        do {
            matches = try modelContext.fetch(matchesDescriptor)
        } catch {
            print("Error fetching matches for season \(seasonNumber): \(error)")
            return []
        }
        
        // Filter only completed matches.
        let completedMatches = matches.filter { $0.isComplete }
        
        // 3) For each completed match, update each player’s stats.
        completedMatches.forEach { match in
            let blackMinusRed = (match.blackTeamScoreFirstSet + match.blackTeamScoreSecondSet)
                                - (match.redTeamScoreFirstSet + match.redTeamScoreSecondSet)
            
            // All four players in the match.
            let playersInMatch = [
                match.redPlayer1, match.redPlayer2,
                match.blackPlayer1, match.blackPlayer2
            ]
            
            playersInMatch.forEach { matchPlayer in
                // Find the corresponding participant record for this match and player.
                guard let participant = participants.first(where: {
                    $0.player.id == matchPlayer.id &&
                    $0.session.uniqueIdentifier == match.session.uniqueIdentifier
                }) else {
                    return
                }
                
                // Calculate the net score based on team.
                let netScore = (participant.team == .Black) ? blackMinusRed : -blackMinusRed
                
                if var stats = playerStats[matchPlayer.id] {
                    stats.totalNet += netScore
                    stats.matchCount += 1
                    playerStats[matchPlayer.id] = stats
                } else {
                    playerStats[matchPlayer.id] = (matchPlayer, Set<Int>(), netScore, 1)
                }
            }
        }
        
        // 4) Compute final stats and sort the players.
        let aggregated = playerStats.values
            .map { stats -> (Player, Int, Int, Double) in
                let sessionCount = stats.sessionsAttended.count
                let averageScore: Double = sessionCount > 0 ? Double(stats.totalNet) / Double(sessionCount) : 0.0
                let finalAverageScore = averageScore + Double(sessionCount)
                return (stats.player, sessionCount, stats.matchCount, finalAverageScore)
            }
            .sorted { $0.3 > $1.3 }
        
        return aggregated
    }
}
