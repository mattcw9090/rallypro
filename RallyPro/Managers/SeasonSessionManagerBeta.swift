import SwiftUI
import FirebaseFirestore

class SeasonSessionManagerBeta: ObservableObject {
    @Published var seasons: [SeasonBeta] = []
    
    private let db = Firestore.firestore()
    
    // MARK: - Fetch Seasons
    func fetchSeasons() {
        db.collection("seasons").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching seasons: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No seasons found")
                return
            }
            
            DispatchQueue.main.async {
                self.seasons = documents.compactMap { doc in
                    let data = doc.data()
                    guard let seasonNumber = data["seasonNumber"] as? Int else { return nil }
                    let isComplete = data["isComplete"] as? Bool ?? false
                    
                    // Retrieve sessions as an array of dictionaries.
                    let sessionsData = data["sessions"] as? [[String: Any]]
                    var sessions: [SessionBeta] = []
                    if let sessionsData = sessionsData {
                        sessions = sessionsData.compactMap { sessionDict in
                            guard let sessionNumber = sessionDict["sessionNumber"] as? Int,
                                  let id = sessionDict["id"] as? String else { return nil }
                            return SessionBeta(id: id, sessionNumber: sessionNumber)
                        }
                    }
                    
                    return SeasonBeta(id: doc.documentID, seasonNumber: seasonNumber, sessions: sessions, isComplete: isComplete)
                }
            }
        }
    }
    
    // MARK: - Add Season
    func addSeason(seasonNumber: Int, sessions: [SessionBeta]? = nil) {
        let newSeason = SeasonBeta(seasonNumber: seasonNumber, sessions: sessions)
        let seasonData: [String: Any] = [
            "seasonNumber": newSeason.seasonNumber,
            "isComplete": newSeason.isComplete,
            "sessions": newSeason.sessions?.map { ["id": $0.id, "sessionNumber": $0.sessionNumber] } as Any
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
    
    // MARK: - Update Season
    func updateSeason(_ season: SeasonBeta) {
        let seasonData: [String: Any] = [
            "seasonNumber": season.seasonNumber,
            "isComplete": season.isComplete,
            "sessions": season.sessions?.map { ["id": $0.id, "sessionNumber": $0.sessionNumber] } as Any
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
    
    // MARK: - Add Session to a Season
    func addSession(to season: SeasonBeta, sessionNumber: Int) {
        guard let index = seasons.firstIndex(where: { $0.id == season.id }) else { return }
        var updatedSeason = season
        var updatedSessions = updatedSeason.sessions ?? []
        
        let newSession = SessionBeta(sessionNumber: sessionNumber)
        updatedSessions.append(newSession)
        // Optional: sort sessions by session number.
        updatedSessions.sort { $0.sessionNumber < $1.sessionNumber }
        updatedSeason.sessions = updatedSessions
        
        updateSeason(updatedSeason)
    }
    
    // MARK: - Global Add Session Functionality
    func addNextSession() {
        // Ensure we have at least one season available.
        guard let latestSeason = seasons.max(by: { $0.seasonNumber < $1.seasonNumber }) else {
            print("No seasons available. Please add a season first.")
            return
        }
        
        let currentSessions = latestSeason.sessions ?? []
        let latestSessionNumber = currentSessions.map { $0.sessionNumber }.max() ?? 0
        let newSessionNumber = latestSessionNumber + 1
        
        addSession(to: latestSeason, sessionNumber: newSessionNumber)
    }
    
    // MARK: - Global Add Season Functionality
    func addNextSeason() {
        // If no season exists, add season 1.
        if seasons.isEmpty {
            addSeason(seasonNumber: 1, sessions: [])
            return
        }
        
        // Otherwise, get the latest season.
        guard let latestSeason = seasons.max(by: { $0.seasonNumber < $1.seasonNumber }) else {
            print("Unexpected error: could not determine latest season.")
            return
        }
        
        // Check if the latest season is complete.
        if !latestSeason.isComplete {
            print("Latest season is not complete. Please mark it as complete before adding a new season.")
            return
        }
        
        // Create a new season with the next season number.
        let newSeasonNumber = latestSeason.seasonNumber + 1
        addSeason(seasonNumber: newSeasonNumber, sessions: [])
    }

    
    // MARK: - Mark Season as Complete
    func markSeasonAsComplete(_ season: SeasonBeta) {
        var updatedSeason = season
        updatedSeason.isComplete = true
        updateSeason(updatedSeason)
    }
}
