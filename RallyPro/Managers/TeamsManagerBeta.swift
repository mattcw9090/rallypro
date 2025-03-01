import SwiftUI
import FirebaseFirestore

class TeamsManagerBeta: ObservableObject {
    @Published var participants: [SessionParticipantBeta] = []
    let db = Firestore.firestore()
    
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
    
    /// Now updated: This function queries the latest season document and then its "sessions" subcollection.
    func getLatestSession(completion: @escaping (SessionBeta?) -> Void) {
        // First, get the latest season from the "seasons" collection.
        db.collection("seasons")
            .order(by: "seasonNumber", descending: true)
            .limit(to: 1)
            .getDocuments { seasonSnapshot, error in
                if let error = error {
                    print("Error fetching latest season: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                guard let seasonDoc = seasonSnapshot?.documents.first else {
                    print("No season document found")
                    completion(nil)
                    return
                }
                // Now query the "sessions" subcollection under the latest season document.
                seasonDoc.reference.collection("sessions")
                    .order(by: "sessionNumber", descending: true)
                    .limit(to: 1)
                    .getDocuments { sessionSnapshot, error in
                        if let error = error {
                            print("Error fetching latest session: \(error.localizedDescription)")
                            completion(nil)
                            return
                        }
                        print("Found \(sessionSnapshot?.documents.count ?? 0) session(s) in the latest season")
                        guard let sessionDoc = sessionSnapshot?.documents.first,
                              let sessionNumber = sessionDoc.data()["sessionNumber"] as? Int
                        else {
                            completion(nil)
                            return
                        }
                        let session = SessionBeta(id: sessionDoc.documentID, sessionNumber: sessionNumber)
                        completion(session)
                    }
            }
    }
    
    func addParticipant(for sessionId: String, player: PlayerBeta, team: TeamType? = nil, completion: @escaping (Error?) -> Void) {
        let newParticipant = SessionParticipantBeta(sessionId: sessionId, player: player, team: team)
        let data: [String: Any] = [
            "sessionId": newParticipant.sessionId,
            "player": [
                "id": newParticipant.player.id,
                "name": newParticipant.player.name,
                "statusRawValue": newParticipant.player.status.rawValue,
                "waitlistPosition": newParticipant.player.waitlistPosition as Any,
                "isMale": newParticipant.player.isMale as Any
            ],
            "team": newParticipant.team?.rawValue as Any
        ]
        db.collection("sessionParticipants").document(newParticipant.id).setData(data, completion: { error in
            if let error = error {
                print("Error setting data for new participant: \(error.localizedDescription)")
            } else {
                print("Successfully added participant with ID: \(newParticipant.id)")
            }
            completion(error)
        })
    }
}
