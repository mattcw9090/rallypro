import SwiftUI
import SwiftData

enum DetailSegment: String, CaseIterable, Identifiable {
    case teams = "Teams"
    case draws = "Draws"
    case results = "Results"
    case payments = "Payments"
    
    var id: String { rawValue }
}

struct SessionDetailView: View {
    let session: Session
    @State private var selectedSegment: DetailSegment = .teams

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedSegment) {
                    ForEach(DetailSegment.allCases) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding([.top, .bottom])

                Divider()

                Group {
                    switch selectedSegment {
                    case .teams:
                        TeamsView(session: session)
                    case .draws:
                        DrawsView(session: session)
                    case .results:
                        ResultsView(session: session)
                    case .payments:
                        PaymentsView(session: session)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Season \(session.seasonNumber) Session \(session.sessionNumber)")
        }
    }
}
