import SwiftData
import SwiftUI

class SeasonSessionManager: ObservableObject {
    private var modelContext: ModelContext

    @Published var allSeasons: [Season] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchSeasons()
    }

    func fetchSeasons() {
        let descriptor = FetchDescriptor<Season>(
            sortBy: [SortDescriptor(\.seasonNumber, order: .reverse)]
        )
        do {
            allSeasons = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching seasons: \(error)")
        }
    }

    var latestSeason: Season? {
        allSeasons.first
    }
    
    var latestSession: Session? {
        guard let season = latestSeason else { return nil }
        let sessionDescriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.sessionNumber, order: .reverse)]
        )
        do {
            let sessions = try modelContext.fetch(sessionDescriptor)
            return sessions.first { $0.season == season }
        } catch {
            print("Error fetching sessions: \(error)")
            return nil
        }
    }
}
