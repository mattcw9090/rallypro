import SwiftUI

enum DetailSegmentBeta: String, CaseIterable, Identifiable {
    case teams = "Teams"
    case draws = "Draws"
    case results = "Results"
    case payments = "Payments"
    
    var id: String { rawValue }
}

struct SessionDetailViewBeta: View {
    let session: SessionBeta
    let seasonNumber: Int
    
    @State private var selectedSegment: DetailSegmentBeta = .teams

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedSegment) {
                    ForEach(DetailSegmentBeta.allCases) { segment in
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
                        TeamsViewBeta(session: session)
                    case .draws:
                        DrawsViewBeta(session: session)
                    case .results:
                        ResultsViewBeta(session: session)
                    case .payments:
                        PaymentsViewBeta(session: session)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Season \(seasonNumber) Session \(session.sessionNumber)")
        }
    }
}

struct TeamsViewBeta: View {
    let session: SessionBeta
    var body: some View {
        Text("Teams for Session \(session.sessionNumber)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue.opacity(0.1))
    }
}

struct DrawsViewBeta: View {
    let session: SessionBeta
    var body: some View {
        Text("Draws for Session \(session.sessionNumber)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.green.opacity(0.1))
    }
}

struct ResultsViewBeta: View {
    let session: SessionBeta
    var body: some View {
        Text("Results for Session \(session.sessionNumber)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.orange.opacity(0.1))
    }
}

struct PaymentsViewBeta: View {
    let session: SessionBeta
    var body: some View {
        Text("Payments for Session \(session.sessionNumber)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.purple.opacity(0.1))
    }
}
