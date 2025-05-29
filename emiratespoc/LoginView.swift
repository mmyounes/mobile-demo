import SwiftUI
import CouchbaseLiteSwift

// MARK: - Login View
struct LoginView: View {
    @State private var username = ""
    @State private var isLoggedIn = false
    @State private var showError = false
    @StateObject private var dbMgr = DatabaseManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Simple Login App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                Spacer()
                
                TextField("Enter Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 40)
                    .autocapitalization(.none)
                    .onChange(of: username) { _ in
                        // Hide error when user starts typing again
                        if showError {
                            showError = false
                        }
                    }
                
                if showError {
                    Text("Invalid username! Please enter a valid username.")
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.top, 5)
                }
                
                
                
                
                Button(action: {
                    do {
                        // Fetch the document
                        if let document = try dbMgr.usersColl?.document(id: username) {
                            print("Document retrieved: \(document.toDictionary())")
                            isLoggedIn = true
                            showError = false
                        } else {
                            print("Document not found")
                            showError = true
                            // Optional: Haptic feedback for error
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                        }
                    } catch {
                        print("Error retrieving document: \(error)")
                        showError = true
                        // Optional: Haptic feedback for error
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                    }
                }) {
                    Text("Login")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(username.isEmpty)
                
                Spacer()
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                WelcomeView(username: username)
            }
        }
    }
}


