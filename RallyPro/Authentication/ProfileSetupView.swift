import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var authManager: AuthManager
    @State private var fullName: String = ""
    @State private var bio: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var navigateToContent: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Complete Your Profile")
                    .font(.title)
                    .padding(.bottom, 20)
                
                TextField("Full Name", text: $fullName)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                TextField("Bio", text: $bio)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    isLoading = true
                    print("DEBUG: Attempting to save profile with fullName: \(fullName), bio: \(bio)")
                    profileManager.saveUserProfile(fullName: fullName, bio: bio) { error in
                        isLoading = false
                        if let error = error {
                            errorMessage = error.localizedDescription
                            print("DEBUG: Error saving profile: \(error.localizedDescription)")
                        } else {
                            print("DEBUG: Profile saved successfully, navigating to ContentView.")
                            navigateToContent = true
                        }
                    }
                }) {
                    Text(isLoading ? "Saving..." : "Save Profile")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                NavigationLink(destination: ContentView(), isActive: $navigateToContent) {
                    EmptyView()
                }
                
                Spacer()
            }
            .padding()
        }
    }
}
