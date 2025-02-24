import SwiftUI

struct AddPlayerViewBeta: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var playerManager: PlayerManagerBeta

    @State private var name: String = ""
    @State private var isMale: Bool = true
    @State private var status: PlayerBeta.PlayerStatus = .notInSession

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Info")) {
                    TextField("Name", text: $name)
                    Toggle("Is Male", isOn: $isMale)
                    Picker("Status", selection: $status) {
                        ForEach(PlayerBeta.PlayerStatus.allCases, id: \.self) { stat in
                            Text(stat.rawValue).tag(stat)
                        }
                    }
                    // Removed Waitlist Position input as it will be handled internally
                }
            }
            .navigationTitle("Add Player")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Pass nil for waitlistPosition; it can be set/updated in the future as needed.
                        playerManager.addPlayer(name: name,
                                                  status: status,
                                                  waitlistPosition: nil,
                                                  isMale: isMale)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
