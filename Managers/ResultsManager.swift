import SwiftUI
import SwiftData

class ResultsManager: ObservableObject {
    private var context: ModelContext

    @Published var allDoublesMatches: [DoublesMatch] = []
    @Published var allSessionParticipants: [SessionParticipant] = []

    init(modelContext: ModelContext) {
        self.context = modelContext
        fetchAllDoublesMatches()
        fetchAllSessionParticipants()
    }

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

    func doublesMatches(for session: Session) -> [DoublesMatch] {
        allDoublesMatches.filter { $0.session.uniqueIdentifier == session.uniqueIdentifier }
    }

    func sessionParticipants(for session: Session) -> [SessionParticipant] {
        allSessionParticipants.filter { $0.session.uniqueIdentifier == session.uniqueIdentifier }
    }

    func completedMatches(for session: Session) -> [DoublesMatch] {
        doublesMatches(for: session).filter { $0.isComplete }
    }

    func totalRedScore(for session: Session) -> Int {
        completedMatches(for: session).reduce(0) {
            $0 + $1.redTeamScoreFirstSet + $1.redTeamScoreSecondSet
        }
    }

    func totalBlackScore(for session: Session) -> Int {
        completedMatches(for: session).reduce(0) {
            $0 + $1.blackTeamScoreFirstSet + $1.blackTeamScoreSecondSet
        }
    }

    func participantScores(for session: Session) -> [(String, Int)] {
        let participants = sessionParticipants(for: session)
        let matches = completedMatches(for: session)
        return participants.map { participant in
            let netScore = matches.filter {
                [$0.redPlayer1.id, $0.redPlayer2.id, $0.blackPlayer1.id, $0.blackPlayer2.id]
                    .contains(participant.player.id)
            }.reduce(0) { sum, match in
                let scoreDiff = (match.blackTeamScoreFirstSet + match.blackTeamScoreSecondSet) -
                                (match.redTeamScoreFirstSet + match.redTeamScoreSecondSet)
                return sum + (participant.team == .Black ? scoreDiff : -scoreDiff)
            }
            return (participant.player.name, netScore)
        }
        .sorted { $0.1 > $1.1 }
    }
}
