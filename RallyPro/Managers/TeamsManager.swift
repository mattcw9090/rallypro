import SwiftUI
import SwiftData

/// Manages team‑related logic using in‑memory filtering.
class TeamsManager: ObservableObject {
    private var context: ModelContext

    /// The active session. Must be set by the view.
    @Published var session: Session?

    // All data from the database (not session filtered).
    @Published var allParticipants: [SessionParticipant] = []
    @Published var allDoublesMatches: [DoublesMatch] = []
    @Published var allPlayers: [Player] = []

    init(modelContext: ModelContext) {
        self.context = modelContext
        fetchAllPlayers()
        fetchAllParticipants()
        fetchAllDoublesMatches()
    }

    /// Call this to configure the manager for a particular session.
    func setSession(_ session: Session) {
        self.session = session
    }

    /// Fetch all SessionParticipants from the context (without filtering).
    private func fetchAllParticipants() {
        let descriptor = FetchDescriptor<SessionParticipant>()
        do {
            allParticipants = try context.fetch(descriptor)
        } catch {
            print("Error fetching all participants: \(error)")
        }
    }

    /// Fetch all DoublesMatches from the context (without filtering).
    private func fetchAllDoublesMatches() {
        let descriptor = FetchDescriptor<DoublesMatch>()
        do {
            allDoublesMatches = try context.fetch(descriptor)
        } catch {
            print("Error fetching all doubles matches: \(error)")
        }
    }

    /// Fetch all Players from the context.
    private func fetchAllPlayers() {
        let descriptor = FetchDescriptor<Player>(sortBy: [SortDescriptor(\.name)])
        do {
            allPlayers = try context.fetch(descriptor)
        } catch {
            print("Error fetching all players: \(error)")
        }
    }

    /// Computed property filtering participants for the active session.
    var participants: [SessionParticipant] {
        guard let session = session else { return [] }
        return allParticipants.filter { $0.session.uniqueIdentifier == session.uniqueIdentifier }
    }

    /// Computed property filtering doubles matches for the active session.
    var doublesMatches: [DoublesMatch] {
        guard let session = session else { return [] }
        return allDoublesMatches.filter { $0.session.uniqueIdentifier == session.uniqueIdentifier }
    }

    /// Computed properties for team members.
    var redTeamMembers: [Player] {
        participants.filter { $0.team == .Red }.map { $0.player }
    }

    var blackTeamMembers: [Player] {
        participants.filter { $0.team == .Black }.map { $0.player }
    }

    var unassignedMembers: [Player] {
        participants.filter { $0.team == nil }.map { $0.player }
    }

    // MARK: - Team Operations

    func updateTeam(for player: Player, to team: Team?) {
        // Find the participant corresponding to this player in the filtered (session) list.
        guard let participant = participants.first(where: { $0.player == player }) else { return }
        participant.team = team
        saveContext()
        refreshData()
    }

    func moveToWaitlist(player: Player) {
        guard let participant = participants.first(where: { $0.player == player }) else { return }
        // Remove the participant from the session.
        context.delete(participant)
        player.status = .onWaitlist
        // Determine the new waitlist position based on all players.
        let currentMaxPosition = allPlayers
            .filter { $0.status == .onWaitlist }
            .compactMap { $0.waitlistPosition }
            .max() ?? 0
        player.waitlistPosition = currentMaxPosition + 1

        saveContext()
        refreshData()
    }

    /// Deletes all doubles matches for the active session.
    func deleteExistingDoublesMatches() {
        for match in doublesMatches {
            context.delete(match)
        }
        saveContext()
        refreshData()
        print("All existing DoublesMatch records for this session have been deleted.")
    }

    func generateDraws(numberOfWaves: Int, numberOfCourts: Int, numberOfPlayersPerTeam: Int = 6) {
        guard validateTeams() else {
            print("Team validation failed.")
            return
        }

        let logic = Logic()
        if let overallLineup = logic.generateCombinedLineup(
            numberOfPlayersPerTeam: numberOfPlayersPerTeam,
            numberOfWaves: numberOfWaves,
            numberOfCourts: numberOfCourts
        ) {
            print("Overall Lineup: \(overallLineup)")
            deleteExistingDoublesMatches()

            guard let session = session else { return }
            for (waveIndex, wave) in overallLineup.enumerated() {
                for match in wave {
                    let firstPair = match[0]
                    let secondPair = match[1]

                    let redMembers = redTeamMembers
                    let blackMembers = blackTeamMembers

                    let newMatch = DoublesMatch(
                        session: session,
                        waveNumber: waveIndex + 1,
                        redPlayer1: redMembers[firstPair.0 - 1],
                        redPlayer2: redMembers[firstPair.1 - 1],
                        blackPlayer1: blackMembers[secondPair.0 - 1],
                        blackPlayer2: blackMembers[secondPair.1 - 1]
                    )
                    context.insert(newMatch)
                }
            }
            saveContext()
            refreshData()
        } else {
            print("No valid lineup found after attempts.")
        }
    }

    func validateTeams() -> Bool {
        // Check that there are no unassigned players.
        if !unassignedMembers.isEmpty {
            return false
        }

        let totalPlayers = participants.count
        if totalPlayers < 12 || totalPlayers % 2 != 0 {
            return false
        }

        if redTeamMembers.count != blackTeamMembers.count {
            return false
        }
        return true
    }

    // MARK: - Helper Methods

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    /// Refresh all data from the persistent store.
    private func refreshData() {
        fetchAllPlayers()
        fetchAllParticipants()
        fetchAllDoublesMatches()
    }
}
