import SwiftUI

struct AddPlayerViewBeta: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var playerManager: PlayerManagerBeta

    @State private var name: String = ""
    @State private var isMale: Bool = true
    @State private var status: PlayerBeta.PlayerStatus = .notInSession
    @State private var waitlistPosition: String = ""

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
                    TextField("Waitlist Position", text: $waitlistPosition)
                        .keyboardType(.numberPad)
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
                        let position = Int(waitlistPosition)
                        playerManager.addPlayer(name: name,
                                                  status: status,
                                                  waitlistPosition: position,
                                                  isMale: isMale)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
