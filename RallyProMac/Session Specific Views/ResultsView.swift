import SwiftUI
import SwiftData
import AppKit

struct ResultsView: View {
    let session: Session
    @EnvironmentObject var resultsManager: ResultsManager

    private var totalRedScore: Int { resultsManager.totalRedScore(for: session) }
    private var totalBlackScore: Int { resultsManager.totalBlackScore(for: session) }
    private var participantScores: [(String, Int)] { resultsManager.participantScores(for: session) }

    private var displayContent: some View {
        VStack(spacing: 20) {
            VStack {
                Text("Team Scores")
                    .font(.headline)
                    .padding(.vertical)

                HStack {
                    VStack {
                        Text("Red Team")
                            .font(.subheadline)
                        Text("\(totalRedScore)")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                    Spacer()
                    VStack {
                        Text("Black Team")
                            .font(.subheadline)
                        Text("\(totalBlackScore)")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                }
                .padding()
            }
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(10)
            .padding(.horizontal)

            VStack(alignment: .leading) {
                Text("Player's Net Score Differences")
                    .font(.headline)
                    .padding(.bottom, 10)

                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(participantScores, id: \.0) { name, score in
                        SessionResultsRowView(playerName: name, playerScore: score)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    var body: some View {
        ScrollView {
            displayContent
        }
        .navigationTitle("Results")
        .onAppear { resultsManager.refreshData() }
    }
}

struct SessionResultsRowView: View {
    var playerName: String
    var playerScore: Int

    var body: some View {
        HStack {
            Text(playerName)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(playerScore) points")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 5)
    }
}
