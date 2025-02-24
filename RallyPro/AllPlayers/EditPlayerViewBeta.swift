import SwiftUI

struct EditPlayerViewBeta: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var playerManager: PlayerManagerBeta
    
    var player: PlayerBeta
    
    @State private var name: String
    @State private var isMale: Bool
    @State private var status: PlayerBeta.PlayerStatus

    init(player: PlayerBeta) {
        self.player = player
        _name = State(initialValue: player.name)
        _isMale = State(initialValue: player.isMale ?? true)
        _status = State(initialValue: player.status)
        // Removed waitlistPosition state initialization
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Player Info")) {
                    TextField("Name", text: $name)
                    Toggle("Is Male", isOn: $isMale)
                    Picker("Status", selection: $status) {
                        ForEach(PlayerBeta.PlayerStatus.allCases, id: \.self) { stat in
                            Text(stat.rawValue).tag(stat)
                        }
                    }
                    // Removed Waitlist Position input as it is not user-editable.
                }
            }
            .navigationTitle("Edit Player")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Preserve the existing waitlistPosition by using the original player's value.
                        let updatedPlayer = PlayerBeta(id: player.id,
                                                       name: name,
                                                       status: status,
                                                       waitlistPosition: player.waitlistPosition,
                                                       isMale: isMale)
                        playerManager.updatePlayer(updatedPlayer)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
