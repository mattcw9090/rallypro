import SwiftUI

struct PlayerRowView: View {
    var player: Player

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(player.isMale ?? true ? .blue : .pink)
            
            VStack(alignment: .leading) {
                Text(player.name)
                    .font(.body)
                
                Text(player.status.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 5)
    }
}
