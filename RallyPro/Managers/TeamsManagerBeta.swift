import SwiftUI
import FirebaseFirestore

class TeamsManagerBeta: ObservableObject {
    @Published var participants: [SessionParticipantBeta] = []
    
    private let db = Firestore.firestore()
    
    /// Fetches session participants for the given session ID.
    func fetchParticipants(for sessionId: String) {
        db.collection("sessionParticipants")
            .whereField("sessionId", isEqualTo: sessionId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching session participants: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No session participants found")
                    return
                }
                
                DispatchQueue.main.async {
                    self.participants = documents.compactMap { doc in
                        let data = doc.data()
                        guard let sessionId = data["sessionId"] as? String,
                              let playerData = data["player"] as? [String: Any],
                              let playerName = playerData["name"] as? String,
                              let statusRaw = playerData["statusRawValue"] as? String,
                              let status = PlayerBeta.PlayerStatus(rawValue: statusRaw)
                        else {
                            return nil
                        }
                        
                        let player = PlayerBeta(
                            id: playerData["id"] as? String ?? UUID().uuidString,
                            name: playerName,
                            status: status,
                            waitlistPosition: playerData["waitlistPosition"] as? Int,
                            isMale: playerData["isMale"] as? Bool
                        )
                        
                        var team: TeamType? = nil
                        if let teamString = data["team"] as? String {
                            team = TeamType(rawValue: teamString)
                        }
                        
                        return SessionParticipantBeta(
                            id: doc.documentID,
                            sessionId: sessionId,
                            player: player,
                            team: team
                        )
                    }
                }
            }
    }
}
