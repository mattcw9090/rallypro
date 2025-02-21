import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ZStack {
            TabView {
                SessionsView()
                    .tabItem {
                        Label("Sessions", systemImage: "list.bullet")
                    }
                
                WaitlistView()
                    .tabItem {
                        Label("Waitlist", systemImage: "person.fill.badge.plus")
                    }
                
                AllPlayersView()
                    .tabItem {
                        Label("All Players", systemImage: "person.3.fill")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
    }
}
