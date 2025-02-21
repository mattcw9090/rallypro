import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSignUpMode = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Welcome to RallyPro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.gray)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                        SecureField("Password", text: $password)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Button(action: {
                    if isSignUpMode {
                        authManager.signUp(email: email, password: password) { error in
                            self.errorMessage = error?.localizedDescription
                        }
                    } else {
                        authManager.signIn(email: email, password: password) { error in
                            self.errorMessage = error?.localizedDescription
                        }
                    }
                }) {
                    Text(isSignUpMode ? "Sign Up" : "Sign In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                
                Button(action: { isSignUpMode.toggle() }) {
                    Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    let rootVC = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .first?.windows.first?.rootViewController ?? UIViewController()
                    authManager.signInWithGoogle(presenting: rootVC) { error in
                        self.errorMessage = error?.localizedDescription
                    }
                }) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                            .font(.title)
                        Text("Sign in with Google")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                
                Button(action: {
                    authManager.signInWithApple { error in
                        self.errorMessage = error?.localizedDescription
                    }
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.title)
                        Text("Sign in with Apple")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 50)
        }
    }
}
