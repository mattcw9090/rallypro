import SwiftUI
import SwiftData

class TeamsManager: ObservableObject {
    private var context: ModelContext

    @Published var session: Session?
    @Published var allParticipants: [SessionParticipant] = []
    @Published var allDoublesMatches: [DoublesMatch] = []
    @Published var allPlayers: [Player] = []

    init(modelContext: ModelContext) {
        self.context = modelContext
        fetchAllPlayers()
        fetchAllParticipants()
        fetchAllDoublesMatches()
    }

    func setSession(_ session: Session) {
        self.session = session
    }

    private func fetchAllParticipants() {
        let descriptor = FetchDescriptor<SessionParticipant>()
        do {
            allParticipants = try context.fetch(descriptor)
        } catch {
            print("Error fetching all participants: \(error)")
        }
    }

    private func fetchAllDoublesMatches() {
        let descriptor = FetchDescriptor<DoublesMatch>()
        do {
            allDoublesMatches = try context.fetch(descriptor)
        } catch {
            print("Error fetching all doubles matches: \(error)")
        }
    }

    private func fetchAllPlayers() {
        let descriptor = FetchDescriptor<Player>(sortBy: [SortDescriptor(\.name)])
        do {
            allPlayers = try context.fetch(descriptor)
        } catch {
            print("Error fetching all players: \(error)")
        }
    }

    var participants: [SessionParticipant] {
        guard let session = session else { return [] }
        return allParticipants.filter { $0.session.uniqueIdentifier == session.uniqueIdentifier }
    }

    var doublesMatches: [DoublesMatch] {
        guard let session = session else { return [] }
        return allDoublesMatches.filter { $0.session.uniqueIdentifier == session.uniqueIdentifier }
    }

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

    func updateTeam(for player: Player, to newTeam: Team?) {
        guard let participant = participants.first(where: { $0.player == player }) else { return }
        let oldTeam = participant.team
        if let oldTeam {
            var teammates = participants
                .filter { $0.team == oldTeam }
                .sorted(by: { $0.teamPosition < $1.teamPosition })
            if let index = teammates.firstIndex(where: { $0.player.id == participant.player.id }) {
                teammates.remove(at: index)
                for (i, p) in teammates.enumerated() {
                    p.teamPosition = i
                }
            }
        }
        if let newTeam {
            let newTeamMembers = participants
                .filter { $0.team == newTeam }
            let maxPosition = newTeamMembers
                .map(\.teamPosition)
                .max() ?? -1
            participant.team = newTeam
            participant.teamPosition = maxPosition + 1
        } else {
            participant.team = nil
            participant.teamPosition = -1
        }
        saveContext()
        refreshData()
    }

    func moveToWaitlist(player: Player) {
        guard let participant = participants.first(where: { $0.player == player }) else { return }
        context.delete(participant)
        player.status = .onWaitlist
        let currentMaxPosition = allPlayers
            .filter { $0.status == .onWaitlist }
            .compactMap { $0.waitlistPosition }
            .max() ?? 0
        player.waitlistPosition = currentMaxPosition + 1
        saveContext()
        refreshData()
    }

    func deleteExistingDoublesMatches() {
        for match in doublesMatches {
            context.delete(match)
        }
        saveContext()
        refreshData()
        print("All existing DoublesMatch records for this session have been deleted.")
    }
    
    private let staticLineup: [[((Int,Int),(Int,Int))]] = [
        [ ((6,9),(6,9)),
          ((5,7),(4,8)),
          ((4,8),(5,7)) ],
        [ ((1,8),(2,6)),
          ((3,11),(4,10)),
          ((4,10),(3,11)) ],
        [ ((5,12),(7,11)),
          ((2,6),(1,8)),
          ((7,11),(5,12)) ],
        [ ((3,9),(1,12)),
          ((2,10),(2,10)),
          ((1,12),(3,9)) ],
        [ ((11,12),(11,12)),
          ((3,4),(3,4)),
          ((7,8),(7,8)) ],
        [ ((1,2),(1,2)),
          ((9,10),(9,10)),
          ((5,6),(5,6)) ]
    ]

    func generateDrawsStatic() {
        guard let session = session else { return }
        let redCount = redTeamParticipants.count
        let blackCount = blackTeamParticipants.count
        guard redCount == 12 && blackCount == 12 else {
            print("Static draw requires exactly 12 Red and 12 Black.")
            return
        }
        deleteExistingDoublesMatches()
        let redLookup = Dictionary(uniqueKeysWithValues: redTeamParticipants.map { ($0.teamPosition + 1, $0.player) })
        let blackLookup = Dictionary(uniqueKeysWithValues: blackTeamParticipants.map { ($0.teamPosition + 1, $0.player) })
        print("🔍 Red Team Position Lookup:")
        for (position, player) in redLookup.sorted(by: { $0.key < $1.key }) {
            print("  [\(position)]: \(player.name)")
        }
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
        guard let team1 = participant1.team, let team2 = participant2.team else {
            print("🚫 Cannot swap unassigned players.")
            return
        }
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
        let tempPosition = participant1.teamPosition
        participant1.teamPosition = participant2.teamPosition
        participant2.teamPosition = tempPosition
        if team1 != team2 {
            participant1.team = team2
            participant2.team = team1
        }
        print("🔁 Swapped \(participant1.player.name) (\(team1)) ↔︎ \(participant2.player.name) (\(team2))")
        saveContext()
        refreshData()
    }

    func validateTeams() -> Bool {
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

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    func refreshData() {
        fetchAllPlayers()
        fetchAllParticipants()
        fetchAllDoublesMatches()
    }
    
    func participant(for player: Player) -> SessionParticipant? {
        participants.first(where: { $0.player.id == player.id })
    }
}
