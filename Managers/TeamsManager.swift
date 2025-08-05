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
    
    private let staticLineup: [[((Int,Int),(Int,Int))]] = [
        // Wave 1
        [ ((6,9),(6,9)),
          ((5,7),(4,8)),
          ((4,8),(5,7)) ],
        // Wave 2
        [ ((1,8),(2,6)),
          ((3,11),(4,10)),
          ((4,10),(3,11)) ],
        // Wave 3
        [ ((5,12),(7,11)),
          ((2,6),(1,8)),
          ((7,11),(5,12)) ],
        // Wave 4
        [ ((3,9),(1,12)),
          ((2,10),(2,10)),
          ((1,12),(3,9)) ],
        // Wave 5
        [ ((11,12),(11,12)),
          ((3,4),(3,4)),
          ((7,8),(7,8)) ],
        // Wave 6
        [ ((1,2),(1,2)),
          ((9,10),(9,10)),
          ((5,6),(5,6)) ]
    ]

    func generateDrawsStatic() {
        guard let session = session else { return }

        // 1) Exactly 24 participants, split 12 vs 12
        let redCount = redTeamMembers.count
        let blackCount = blackTeamMembers.count
        guard redCount == 12 && blackCount == 12 else {
            print("Static draw requires exactly 12 Red and 12 Black.")
            return
        }

        // 2) Wipe out any existing matches
        deleteExistingDoublesMatches()

        // 3) Walk our staticLineup
        for (waveIndex, wave) in staticLineup.enumerated() {
            for (redPair, blackPair) in wave {
                let red1 = redTeamMembers[redPair.0 - 1]
                let red2 = redTeamMembers[redPair.1 - 1]
                let black1 = blackTeamMembers[blackPair.0 - 1]
                let black2 = blackTeamMembers[blackPair.1 - 1]

                let match = DoublesMatch(
                    session: session,
                    waveNumber: waveIndex + 1,
                    redPlayer1: red1,
                    redPlayer2: red2,
                    blackPlayer1: black1,
                    blackPlayer2: black2
                )
                context.insert(match)
            }
        }

        // 4) Save & refresh
        saveContext()
        refreshData()
        print("Static draws generated (\(staticLineup.count) waves of \(staticLineup.first?.count ?? 0) courts).")
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
    func refreshData() {
        fetchAllPlayers()
        fetchAllParticipants()
        fetchAllDoublesMatches()
    }
}
