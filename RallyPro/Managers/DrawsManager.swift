import SwiftUI
import SwiftData

/// Manages all draw‐related logic (waves, matches, and wave reordering) for a given session.
class DrawsManager: ObservableObject {
    private var context: ModelContext

    // All doubles matches and participants fetched from the persistent store.
    @Published var allDoublesMatches: [DoublesMatch] = []
    @Published var allParticipants: [SessionParticipant] = []

    init(modelContext: ModelContext) {
        self.context = modelContext
        fetchAllDoublesMatches()
        fetchAllParticipants()
    }

    /// Refreshes all data from the persistent store.
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

    // MARK: - Computed (Filtered) Properties

    /// Returns all doubles matches for the given session.
    func doublesMatches(for session: Session) -> [DoublesMatch] {
        allDoublesMatches.filter { $0.session.uniqueIdentifier == session.uniqueIdentifier }
    }

    /// Returns all participants for the given session.
    func participants(for session: Session) -> [SessionParticipant] {
        allParticipants.filter { $0.session.uniqueIdentifier == session.uniqueIdentifier }
    }

    /// Returns the red team players for the given session.
    func redTeamMembers(for session: Session) -> [Player] {
        participants(for: session)
            .filter { $0.team == .Red }
            .map { $0.player }
    }

    /// Returns the black team players for the given session.
    func blackTeamMembers(for session: Session) -> [Player] {
        participants(for: session)
            .filter { $0.team == .Black }
            .map { $0.player }
    }

    /// Returns the maximum wave number in the session.
    func maxWaveNumber(for session: Session) -> Int {
        doublesMatches(for: session)
            .map { $0.waveNumber }
            .max() ?? 0
    }

    // MARK: - Wave and Match Operations

    /// Adds a new wave (with one match) to the session.
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

    /// Adds a new match to an existing wave.
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

    /// Deletes the given match and then, if that wave is now empty, reorders subsequent waves.
    func deleteMatch(_ match: DoublesMatch, for session: Session) {
        let deletedWaveNumber = match.waveNumber
        context.delete(match)
        saveContext()
        refreshData()
        reorderWavesAfterDeletingWaveIfNeeded(deletedWaveNumber, for: session)
    }

    /// If a wave is empty after deletion, shifts all subsequent wave numbers down by 1.
    func reorderWavesAfterDeletingWaveIfNeeded(_ wave: Int, for session: Session) {
        // Determine if the given wave is now empty.
        let isWaveEmpty = !allDoublesMatches.contains { $0.session.uniqueIdentifier == session.uniqueIdentifier && $0.waveNumber == wave }
        guard isWaveEmpty else { return }

        // Shift subsequent waves down by 1.
        let matchesToShift = allDoublesMatches.filter {
            $0.session.uniqueIdentifier == session.uniqueIdentifier && $0.waveNumber > wave
        }
        for match in matchesToShift {
            match.waveNumber -= 1
        }
        saveContext()
        refreshData()
    }

    // MARK: - Helper

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context in DrawsManager: \(error)")
        }
    }
}
