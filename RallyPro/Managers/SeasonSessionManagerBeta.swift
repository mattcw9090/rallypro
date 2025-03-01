import SwiftUI
import FirebaseFirestore

class SeasonSessionManagerBeta: ObservableObject {
    @Published var seasons: [SeasonBeta] = []
    
    private let db = Firestore.firestore()
    
    // MARK: - Fetch Seasons with Sessions from Subcollections
    func fetchSeasons() {
        db.collection("seasons").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching seasons: \(error.localizedDescription)")
                return
            }
            
            guard let seasonDocs = snapshot?.documents else {
                print("No seasons found")
                return
            }
            
            var fetchedSeasons: [SeasonBeta] = []
            let group = DispatchGroup()
            
            // Iterate through each season document.
            for doc in seasonDocs {
                // Extract data from the document
                let data = doc.data()
                guard let seasonNumber = data["seasonNumber"] as? Int else { continue }
                let isComplete = data["isComplete"] as? Bool ?? false

                group.enter()
                // Create a SeasonBeta instance with an empty sessions array
                var season = SeasonBeta(id: doc.documentID, seasonNumber: seasonNumber, sessions: [], isComplete: isComplete)
                
                // Query the "sessions" subcollection for this season.
                doc.reference.collection("sessions")
                    .order(by: "sessionNumber", descending: false)
                    .getDocuments { sessionSnapshot, error in
                        if let error = error {
                            print("Error fetching sessions for season \(seasonNumber): \(error.localizedDescription)")
                        } else if let sessionDocs = sessionSnapshot?.documents {
                            let sessions = sessionDocs.compactMap { sessionDoc -> SessionBeta? in
                                let sData = sessionDoc.data()
                                guard let sessionNumber = sData["sessionNumber"] as? Int else { return nil }
                                return SessionBeta(id: sessionDoc.documentID, sessionNumber: sessionNumber)
                            }
                            season.sessions = sessions
                        }
                        fetchedSeasons.append(season)
                        group.leave()
                    }
            }


            
            group.notify(queue: .main) {
                self.seasons = fetchedSeasons
            }
        }
    }
    
    // MARK: - Add Season (writes a season document; sessions are added separately)
    func addSeason(seasonNumber: Int) {
        let newSeason = SeasonBeta(seasonNumber: seasonNumber, sessions: nil, isComplete: false)
        let seasonData: [String: Any] = [
            "seasonNumber": newSeason.seasonNumber,
            "isComplete": newSeason.isComplete
        ]
        
        db.collection("seasons").document(newSeason.id).setData(seasonData) { error in
            if let error = error {
                print("Error adding season: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.seasons.append(newSeason)
                }
            }
        }
    }
    
    // MARK: - Update Season (only updates season-level fields)
    func updateSeason(_ season: SeasonBeta) {
        let seasonData: [String: Any] = [
            "seasonNumber": season.seasonNumber,
            "isComplete": season.isComplete
        ]
        
        db.collection("seasons").document(season.id).updateData(seasonData) { error in
            if let error = error {
                print("Error updating season: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    if let index = self.seasons.firstIndex(where: { $0.id == season.id }) {
                        self.seasons[index] = season
                    }
                }
            }
        }
    }
    
    // MARK: - Add Session to a Season (writes a document in the "sessions" subcollection)
    func addSession(to season: SeasonBeta, sessionNumber: Int) {
        let newSession = SessionBeta(sessionNumber: sessionNumber)
        let seasonRef = db.collection("seasons").document(season.id)
        let sessionData: [String: Any] = [
            "sessionNumber": newSession.sessionNumber
        ]
        
        seasonRef.collection("sessions").document(newSession.id).setData(sessionData) { error in
            if let error = error {
                print("Error adding session: \(error.localizedDescription)")
            } else {
                print("Session \(newSession.sessionNumber) added to season \(season.seasonNumber)")
                // Optionally refresh the seasons list.
                self.fetchSeasons()
            }
        }
    }
    
    // MARK: - Global Add Session Functionality
    func addNextSession() {
        // Ensure we have at least one season available.
        guard let latestSeason = seasons.max(by: { $0.seasonNumber < $1.seasonNumber }) else {
            print("No seasons available. Please add a season first.")
            return
        }
        
        let seasonRef = db.collection("seasons").document(latestSeason.id)
        seasonRef.collection("sessions")
            .order(by: "sessionNumber", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching sessions: \(error.localizedDescription)")
                    return
                }
                let latestSessionNumber = snapshot?.documents.first.flatMap {
                    $0.data()["sessionNumber"] as? Int
                } ?? 0
                let newSessionNumber = latestSessionNumber + 1
                self.addSession(to: latestSeason, sessionNumber: newSessionNumber)
            }
    }
    
    // MARK: - Global Add Season Functionality
    func addNextSeason() {
        // If no season exists, add season 1.
        if seasons.isEmpty {
            addSeason(seasonNumber: 1)
            return
        }
        
        guard let latestSeason = seasons.max(by: { $0.seasonNumber < $1.seasonNumber }) else {
            print("Unexpected error: could not determine latest season.")
            return
        }
        
        if !latestSeason.isComplete {
            print("Latest season is not complete. Please mark it as complete before adding a new season.")
            return
        }
        
        let newSeasonNumber = latestSeason.seasonNumber + 1
        addSeason(seasonNumber: newSeasonNumber)
    }
    
    // MARK: - Mark Season as Complete
    func markSeasonAsComplete(_ season: SeasonBeta) {
        var updatedSeason = season
        updatedSeason.isComplete = true
        updateSeason(updatedSeason)
    }
}
