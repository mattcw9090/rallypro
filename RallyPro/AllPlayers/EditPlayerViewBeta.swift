import SwiftUI

struct EditPlayerViewBeta: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var playerManager: PlayerManagerBeta
    
    var player: PlayerBeta
    
    @State private var name: String
    @State private var isMale: Bool
    @State private var status: PlayerBeta.PlayerStatus
    @State private var waitlistPosition: String

    init(player: PlayerBeta) {
        self.player = player
        _name = State(initialValue: player.name)
        _isMale = State(initialValue: player.isMale ?? true)
        _status = State(initialValue: player.status)
        _waitlistPosition = State(initialValue: player.waitlistPosition != nil ? String(player.waitlistPosition!) : "")
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
                    TextField("Waitlist Position", text: $waitlistPosition)
                        .keyboardType(.numberPad)
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
                        let position = Int(waitlistPosition)
                        let updatedPlayer = PlayerBeta(id: player.id,
                                                       name: name,
                                                       status: status,
                                                       waitlistPosition: position,
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
