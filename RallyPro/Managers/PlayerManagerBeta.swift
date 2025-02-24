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
        // Create a new player instance using PlayerBeta.
        let newPlayer = PlayerBeta(name: name,
                                   status: status,
                                   waitlistPosition: waitlistPosition,
                                   isMale: isMale)
        
        let playerData: [String: Any] = [
            "id": newPlayer.id, // Store the id generated in the model.
            "name": newPlayer.name,
            "statusRawValue": newPlayer.status.rawValue,
            "waitlistPosition": newPlayer.waitlistPosition as Any,
            "isMale": newPlayer.isMale as Any
        ]
        
        // Using the player's id as the document ID ensures uniqueness.
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
}
