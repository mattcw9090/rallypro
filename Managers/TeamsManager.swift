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
    var redTeamParticipants: [SessionParticipant] {
        participants
            .filter { $0.team == .Red }
            .sorted(by: { $0.teamPosition < $1.teamPosition })
    }

    var blackTeamParticipants: [SessionParticipant] {
        participants
            .filter { $0.team == .Black }
            .sorted(by: { $0.teamPosition < $1.teamPosition })
    }

    var unassignedParticipants: [SessionParticipant] {
        participants
            .filter { $0.team == nil }
    }

    // MARK: - Team Operations

    func updateTeam(for player: Player, to newTeam: Team?) {
        // 1. Get the current participant in the session
        guard let participant = participants.first(where: { $0.player == player }) else { return }

        let oldTeam = participant.team
        let oldPosition = participant.teamPosition

        // 2. If participant is switching *from* a team, dequeue them
        if let oldTeam {
            // Get all teammates in the same team, sorted by position
            var teammates = participants
                .filter { $0.team == oldTeam }
                .sorted(by: { $0.teamPosition < $1.teamPosition })

            // Find index of the exiting participant
            if let index = teammates.firstIndex(where: { $0.player.id == participant.player.id }) {
                // Remove the participant
                teammates.remove(at: index)

                // Reassign teamPositions: compact from 0...n
                for (i, p) in teammates.enumerated() {
                    p.teamPosition = i
                }
            }
        }

        // 3. If moving to a new team, enqueue to the end
        if let newTeam {
            let newTeamMembers = participants
                .filter { $0.team == newTeam }

            let maxPosition = newTeamMembers
                .map(\.teamPosition)
                .max() ?? -1

            participant.team = newTeam
            participant.teamPosition = maxPosition + 1
        } else {
            // 4. Unassigning from all teams
            participant.team = nil
            participant.teamPosition = -1
        }

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

        // 1) Validate team sizes
        let redCount = redTeamParticipants.count
        let blackCount = blackTeamParticipants.count
        guard redCount == 12 && blackCount == 12 else {
            print("Static draw requires exactly 12 Red and 12 Black.")
            return
        }

        // 2) Wipe out existing matches
        deleteExistingDoublesMatches()

        // 3) Build lookup dictionaries: [teamPosition: Player]
        let redLookup = Dictionary(uniqueKeysWithValues: redTeamParticipants.map { ($0.teamPosition + 1, $0.player) })
        let blackLookup = Dictionary(uniqueKeysWithValues: blackTeamParticipants.map { ($0.teamPosition + 1, $0.player) })
        
        // 🔍 Debug print red team lookup
        print("🔍 Red Team Position Lookup:")
        for (position, player) in redLookup.sorted(by: { $0.key < $1.key }) {
            print("  [\(position)]: \(player.name)")
        }

        // 4) Generate matches from staticLineup
        for (waveIndex, wave) in staticLineup.enumerated() {
            for (redPair, blackPair) in wave {
                guard
                    let red1 = redLookup[redPair.0],
                    let red2 = redLookup[redPair.1],
                    let black1 = blackLookup[blackPair.0],
                    let black2 = blackLookup[blackPair.1]
                else {
                    print("❌ Missing players at required teamPositions. Aborting draws.")
                    return
                }

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
        print("Static draws generated (\(staticLineup.count) waves of \(staticLineup.first?.count ?? 0) courts). Please close app and reopen to view.")
    }
    
    func swapParticipants(_ first: Player, _ second: Player) {
        guard
            let participant1 = participants.first(where: { $0.player.id == first.id }),
            let participant2 = participants.first(where: { $0.player.id == second.id })
        else {
            print("❌ Could not find participants for both players in session.")
            return
        }

        // ❌ Restrict unassigned participants
        guard let team1 = participant1.team, let team2 = participant2.team else {
            print("🚫 Cannot swap unassigned players.")
            return
        }

        // ✅ Allow only Red ↔︎ Red, Black ↔︎ Black, Red ↔︎ Black
        let allowedTeams: Set<Set<Team>> = [
            [.Red, .Red],
            [.Black, .Black],
            [.Red, .Black]
        ]

        let actualPair = Set([team1, team2])
        guard allowedTeams.contains(actualPair) else {
            print("🚫 Invalid swap: \(team1.rawValue) ↔︎ \(team2.rawValue) not allowed.")
            return
        }

        // ✅ Proceed with swap
        let tempPosition = participant1.teamPosition
        participant1.teamPosition = participant2.teamPosition
        participant2.teamPosition = tempPosition

        // Swap teams if different
        if team1 != team2 {
            participant1.team = team2
            participant2.team = team1
        }

        print("🔁 Swapped \(participant1.player.name) (\(team1)) ↔︎ \(participant2.player.name) (\(team2))")

        saveContext()
        refreshData()
    }

    func validateTeams() -> Bool {
        // Check that there are no unassigned players.
        if !unassignedParticipants.isEmpty {
            return false
        }

        let totalPlayers = participants.count
        if totalPlayers < 12 || totalPlayers % 2 != 0 {
            return false
        }

        if redTeamParticipants.count != blackTeamParticipants.count {
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
    
    func participant(for player: Player) -> SessionParticipant? {
        participants.first(where: { $0.player.id == player.id })
    }
}
