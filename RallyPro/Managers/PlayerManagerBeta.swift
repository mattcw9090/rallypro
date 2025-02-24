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
        let newPlayer = PlayerBeta(name: name,
                                   status: status,
                                   waitlistPosition: waitlistPosition,
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
        let playerData: [String: Any] = [
            "id": updatedPlayer.id,
            "name": updatedPlayer.name,
            "statusRawValue": updatedPlayer.status.rawValue,
            "waitlistPosition": updatedPlayer.waitlistPosition as Any,
            "isMale": updatedPlayer.isMale as Any
        ]
        db.collection("players").document(updatedPlayer.id).updateData(playerData) { error in
            if let error = error {
                print("Error updating player: \(error.localizedDescription)")
            } else {
                if let index = self.players.firstIndex(where: { $0.id == updatedPlayer.id }) {
                    DispatchQueue.main.async {
                        self.players[index] = updatedPlayer
                    }
                }
            }
        }
    }
}
