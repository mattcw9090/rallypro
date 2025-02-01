import SwiftUI
import SwiftData

/// Manages the logic for calculating session results.
class ResultsManager: ObservableObject {
    private var context: ModelContext

    /// All doubles matches in the store.
    @Published var allDoublesMatches: [DoublesMatch] = []
    /// All session participants in the store.
    @Published var allSessionParticipants: [SessionParticipant] = []

    init(modelContext: ModelContext) {
        self.context = modelContext
        fetchAllDoublesMatches()
        fetchAllSessionParticipants()
    }

    /// Refreshes all data from the persistent store.
    func refreshData() {
        fetchAllDoublesMatches()
        fetchAllSessionParticipants()
    }

    private func fetchAllDoublesMatches() {
        let descriptor = FetchDescriptor<DoublesMatch>()
        do {
            allDoublesMatches = try context.fetch(descriptor)
        } catch {
            print("Error fetching doubles matches: \(error)")
        }
    }

    private func fetchAllSessionParticipants() {
        let descriptor = FetchDescriptor<SessionParticipant>()
        do {
            allSessionParticipants = try context.fetch(descriptor)
        } catch {
            print("Error fetching session participants: \(error)")
        }
    }

    // MARK: - Filtering by Session

    /// Returns all doubles matches for the given session.
    func doublesMatches(for session: Session) -> [DoublesMatch] {
        allDoublesMatches.filter { $0.session.uniqueIdentifier == session.uniqueIdentifier }
    }

    /// Returns all session participants for the given session.
    func sessionParticipants(for session: Session) -> [SessionParticipant] {
        allSessionParticipants.filter { $0.session.uniqueIdentifier == session.uniqueIdentifier }
    }

    // MARK: - Computed Results

    /// All matches in the session that are complete.
    func completedMatches(for session: Session) -> [DoublesMatch] {
        doublesMatches(for: session).filter { $0.isComplete }
    }

    /// Total red team score (from both sets) from completed matches.
    func totalRedScore(for session: Session) -> Int {
        completedMatches(for: session).reduce(0) {
            $0 + $1.redTeamScoreFirstSet + $1.redTeamScoreSecondSet
        }
    }

    /// Total black team score (from both sets) from completed matches.
    func totalBlackScore(for session: Session) -> Int {
        completedMatches(for: session).reduce(0) {
            $0 + $1.blackTeamScoreFirstSet + $1.blackTeamScoreSecondSet
        }
    }

    /// Calculates each participant’s net score (difference) based on completed matches.
    func participantScores(for session: Session) -> [(String, Int)] {
        let participants = sessionParticipants(for: session)
        let matches = completedMatches(for: session)
        return participants.map { participant in
            // For each participant, compute their net score based on matches in which they played.
            let netScore = matches.filter {
                // Check if this participant's player is involved in the match.
                [$0.redPlayer1.id, $0.redPlayer2.id, $0.blackPlayer1.id, $0.blackPlayer2.id]
                    .contains(participant.player.id)
            }.reduce(0) { sum, match in
                // Calculate score difference:
                // If participant is on Black team, add the difference (Black - Red);
                // Otherwise (Red team), subtract the difference.
                let scoreDiff = (match.blackTeamScoreFirstSet + match.blackTeamScoreSecondSet) -
                                (match.redTeamScoreFirstSet + match.redTeamScoreSecondSet)
                return sum + (participant.team == .Black ? scoreDiff : -scoreDiff)
            }
            return (participant.player.name, netScore)
        }
        .sorted { $0.1 > $1.1 }
    }
}
