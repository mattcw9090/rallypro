import SwiftUI
import SwiftData

class DrawsManager: ObservableObject {
    private var context: ModelContext

    @Published var allDoublesMatches: [DoublesMatch] = []
    @Published var allParticipants: [SessionParticipant] = []

    init(modelContext: ModelContext) {
        self.context = modelContext
        fetchAllDoublesMatches()
        fetchAllParticipants()
    }

    func refreshData() {
        fetchAllDoublesMatches()
        fetchAllParticipants()
    }

    private func fetchAllDoublesMatches() {
        let descriptor = FetchDescriptor<DoublesMatch>()
        do {
            allDoublesMatches = try context.fetch(descriptor)
        } catch {
            print("Error fetching doubles matches: \(error)")
        }
    }

    private func fetchAllParticipants() {
        let descriptor = FetchDescriptor<SessionParticipant>()
        do {
            allParticipants = try context.fetch(descriptor)
        } catch {
            print("Error fetching participants: \(error)")
        }
    }

    func doublesMatches(for session: Session) -> [DoublesMatch] {
        allDoublesMatches.filter { $0.session.uniqueIdentifier == session.uniqueIdentifier }
    }

    func participants(for session: Session) -> [SessionParticipant] {
        allParticipants.filter { $0.session.uniqueIdentifier == session.uniqueIdentifier }
    }

    func redTeamMembers(for session: Session) -> [Player] {
        participants(for: session)
            .filter { $0.team == .Red }
            .map { $0.player }
    }

    func blackTeamMembers(for session: Session) -> [Player] {
        participants(for: session)
            .filter { $0.team == .Black }
            .map { $0.player }
    }

    func maxWaveNumber(for session: Session) -> Int {
        doublesMatches(for: session)
            .map { $0.waveNumber }
            .max() ?? 0
    }

    func addWave(for session: Session) {
        let newWaveNumber = maxWaveNumber(for: session) + 1
        let redTeam = redTeamMembers(for: session)
        let blackTeam = blackTeamMembers(for: session)
        let newMatch = DoublesMatch(
            session: session,
            waveNumber: newWaveNumber,
            redPlayer1: redTeam.first ?? Player(name: "Red Player A"),
            redPlayer2: redTeam.dropFirst().first ?? Player(name: "Red Player B"),
            blackPlayer1: blackTeam.first ?? Player(name: "Black Player A"),
            blackPlayer2: blackTeam.dropFirst().first ?? Player(name: "Black Player B")
        )
        context.insert(newMatch)
        saveContext()
        refreshData()
    }

    func addMatch(for session: Session, wave: Int) {
        let redTeam = redTeamMembers(for: session)
        let blackTeam = blackTeamMembers(for: session)
        let newMatch = DoublesMatch(
            session: session,
            waveNumber: wave,
            redPlayer1: redTeam.first ?? Player(name: "Red Player A"),
            redPlayer2: redTeam.dropFirst().first ?? Player(name: "Red Player B"),
            blackPlayer1: blackTeam.first ?? Player(name: "Black Player A"),
            blackPlayer2: blackTeam.dropFirst().first ?? Player(name: "Black Player B")
        )
        context.insert(newMatch)
        saveContext()
        refreshData()
    }

    func deleteMatch(_ match: DoublesMatch, for session: Session) {
        let deletedWaveNumber = match.waveNumber
        context.delete(match)
        saveContext()
        refreshData()
        reorderWavesAfterDeletingWaveIfNeeded(deletedWaveNumber, for: session)
    }

    func reorderWavesAfterDeletingWaveIfNeeded(_ wave: Int, for session: Session) {
        let isWaveEmpty = !allDoublesMatches.contains {
            $0.session.uniqueIdentifier == session.uniqueIdentifier && $0.waveNumber == wave
        }
        guard isWaveEmpty else { return }

        let matchesToShift = allDoublesMatches.filter {
            $0.session.uniqueIdentifier == session.uniqueIdentifier && $0.waveNumber > wave
        }
        for match in matchesToShift {
            match.waveNumber -= 1
        }
        saveContext()
        refreshData()
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context in DrawsManager: \(error)")
        }
    }
}
