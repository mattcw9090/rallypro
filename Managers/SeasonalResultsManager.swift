import SwiftData
import SwiftUI

class SeasonalResultsManager: ObservableObject {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func aggregatedPlayers(forSeasonNumber seasonNumber: Int) -> [(player: Player, sessionCount: Int, matchCount: Int, finalAverageScore: Double)] {
        var playerStats: [UUID: (player: Player, sessionsAttended: Set<Int>, totalNet: Int, matchCount: Int)] = [:]

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

        let completedMatches = matches.filter { $0.isComplete }

        completedMatches.forEach { match in
            let blackMinusRed = (match.blackTeamScoreFirstSet + match.blackTeamScoreSecondSet)
                              - (match.redTeamScoreFirstSet + match.redTeamScoreSecondSet)

            let playersInMatch = [
                match.redPlayer1, match.redPlayer2,
                match.blackPlayer1, match.blackPlayer2
            ]

            playersInMatch.forEach { matchPlayer in
                guard let participant = participants.first(where: {
                    $0.player.id == matchPlayer.id &&
                    $0.session.uniqueIdentifier == match.session.uniqueIdentifier
                }) else { return }

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
