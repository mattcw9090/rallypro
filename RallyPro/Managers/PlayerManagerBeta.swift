import SwiftUI
import FirebaseFirestore

class PlayerManagerBeta: ObservableObject {
    @Published var players: [PlayerBeta] = []
    
    private let db = Firestore.firestore()
    
    init() {
        fetchPlayers()
    }
    
    func fetchPlayers() {
        db.collection("players").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching players: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No players found")
                return
            }
            
            DispatchQueue.main.async {
                self.players = documents.compactMap { doc in
                    let data = doc.data()
                    guard let name = data["name"] as? String else { return nil }
                    let statusRawValue = data["statusRawValue"] as? String ?? PlayerBeta.PlayerStatus.notInSession.rawValue
                    let waitlistPosition = data["waitlistPosition"] as? Int
                    let isMale = data["isMale"] as? Bool
                    
                    return PlayerBeta(id: data["id"] as? String ?? UUID().uuidString,
                                      name: name,
                                      status: PlayerBeta.PlayerStatus(rawValue: statusRawValue) ?? .notInSession,
                                      waitlistPosition: waitlistPosition,
                                      isMale: isMale)
                }
            }
        }
    }
    
    func addPlayer(name: String,
                   status: PlayerBeta.PlayerStatus = .notInSession,
                   waitlistPosition: Int? = nil,
                   isMale: Bool? = nil) {
        // If the status is onWaitlist and no waitlist position was provided,
        // compute the next available waitlist position.
        var computedWaitlistPosition = waitlistPosition
        if status == .onWaitlist && computedWaitlistPosition == nil {
            let currentPositions = players.filter { $0.status == .onWaitlist }
                                          .compactMap { $0.waitlistPosition }
            let maxPosition = currentPositions.max() ?? 0
            computedWaitlistPosition = maxPosition + 1
        }
        
        let newPlayer = PlayerBeta(name: name,
                                   status: status,
                                   waitlistPosition: computedWaitlistPosition,
                                   isMale: isMale)
        
        let playerData: [String: Any] = [
            "id": newPlayer.id,
            "name": newPlayer.name,
            "statusRawValue": newPlayer.status.rawValue,
            "waitlistPosition": newPlayer.waitlistPosition as Any,
            "isMale": newPlayer.isMale as Any
        ]
        
        db.collection("players").document(newPlayer.id).setData(playerData) { error in
            if let error = error {
                print("Error adding player: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.players.append(newPlayer)
                }
            }
        }
    }

    
    // MARK: - New Delete Functionality
    func deletePlayer(at offsets: IndexSet) {
        offsets.forEach { index in
            let player = players[index]
            db.collection("players").document(player.id).delete { error in
                if let error = error {
                    print("Error deleting player: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.players.remove(at: index)
                    }
                }
            }
        }
    }
    
    // MARK: - New Update Functionality
    func updatePlayer(_ updatedPlayer: PlayerBeta) {
        var newUpdatedPlayer = updatedPlayer
        var removedPosition: Int? = nil
        
        if let oldPlayer = self.players.first(where: { $0.id == updatedPlayer.id }) {
            // If switching from not on waitlist to onWaitlist, assign next available position.
            if oldPlayer.status != .onWaitlist && updatedPlayer.status == .onWaitlist {
                if updatedPlayer.waitlistPosition == nil {
                    let currentPositions = players.filter { $0.status == .onWaitlist }
                                                  .compactMap { $0.waitlistPosition }
                    let maxPosition = currentPositions.max() ?? 0
                    newUpdatedPlayer.waitlistPosition = maxPosition + 1
                }
            }
            // If switching from onWaitlist to not in session, clear the waitlist position.
            if oldPlayer.status == .onWaitlist && updatedPlayer.status != .onWaitlist {
                removedPosition = oldPlayer.waitlistPosition
                newUpdatedPlayer.waitlistPosition = nil
            }
        }
        
        let playerData: [String: Any] = [
            "id": newUpdatedPlayer.id,
            "name": newUpdatedPlayer.name,
            "statusRawValue": newUpdatedPlayer.status.rawValue,
            "waitlistPosition": newUpdatedPlayer.waitlistPosition as Any,
            "isMale": newUpdatedPlayer.isMale as Any
        ]
        
        db.collection("players").document(newUpdatedPlayer.id).updateData(playerData) { error in
            if let error = error {
                print("Error updating player: \(error.localizedDescription)")
            } else {
                if let index = self.players.firstIndex(where: { $0.id == newUpdatedPlayer.id }) {
                    DispatchQueue.main.async {
                        self.players[index] = newUpdatedPlayer
                    }
                }
                // If the player was removed from the waitlist, adjust the positions of the others.
                if let removed = removedPosition {
                    self.reorderWaitlistAfterRemoval(removalPosition: removed)
                }
            }
        }
    }
    
    func movePlayerToWaitlist(_ player: PlayerBeta) {
        // Calculate the current maximum waitlist position among players on waitlist.
        let currentPositions = players.filter { $0.status == .onWaitlist }
                                      .compactMap { $0.waitlistPosition }
        let maxPosition = currentPositions.max() ?? 0
        let newPosition = maxPosition + 1

        var updatedPlayer = player
        updatedPlayer.status = .onWaitlist
        updatedPlayer.waitlistPosition = newPosition

        // Update the player record (both in Firestore and locally).
        updatePlayer(updatedPlayer)
    }
    
    func reorderWaitlistAfterRemoval(removalPosition: Int) {
        // Find players in waitlist with a position higher than the one being removed.
        let affectedPlayers = players.filter { $0.status == .onWaitlist && ($0.waitlistPosition ?? 0) > removalPosition }
        for var player in affectedPlayers {
            if let currentPosition = player.waitlistPosition {
                let newPosition = currentPosition - 1
                player.waitlistPosition = newPosition
                let playerData: [String: Any] = [
                    "id": player.id,
                    "name": player.name,
                    "statusRawValue": player.status.rawValue,
                    "waitlistPosition": player.waitlistPosition as Any,
                    "isMale": player.isMale as Any
                ]
                db.collection("players").document(player.id).updateData(playerData) { error in
                    if let error = error {
                        print("Error updating player waitlist position: \(error.localizedDescription)")
                    } else {
                        DispatchQueue.main.async {
                            if let index = self.players.firstIndex(where: { $0.id == player.id }) {
                                self.players[index] = player
                            }
                        }
                    }
                }
            }
        }
    }

}
