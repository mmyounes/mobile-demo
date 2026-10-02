import SwiftUI
import CouchbaseLiteSwift

// MARK: - Navigation Destination Enum
// Defines the possible views we can navigate to.
enum Destination: String, Hashable, CaseIterable {
    case welcome = "E-Ticket View "
    case water = "Water View "
    
    // Provides the correct SF Symbol name for each destination.
    var iconName: String {
        switch self {
        case .welcome:
            return "airplane"
        case .water:
            return "drop.fill"
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    // State for the navigation path
    @State private var path = NavigationPath()
    
    // State for UI elements
    @State private var username = ""
    @State private var showError = false
    @State private var selectedDestination: Destination = .welcome
    
    @StateObject private var dbMgr = DatabaseManager.shared
    
    var body: some View {
        // Use the path to control the navigation stack
        NavigationStack(path: $path) {
            VStack(spacing: 20) {
                Image("app-logo") // Make sure you have this in your Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                
                Text("Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                .padding(.bottom, 40)

                /*Picker("Destination", selection: $selectedDestination) {
                    ForEach(Destination.allCases, id: \.self) { destination in
                        Label(destination.rawValue, systemImage: destination.iconName).tag(destination)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 40)*/
                
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 40)
                    .autocapitalization(.none)
                    .onChange(of: username) {
                        if showError { showError = false }
                    }
                
                SecureField("Password", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.password)
                    .padding(.horizontal, 40)
                    
                
                if showError {
                    Text("Invalid username! Please enter a valid username.")
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.top, 5)
                }
                
                Button(action: loginUser) {
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
            // MARK: - Updated Navigation Destination
            // This modifier listens for changes to the path and navigates accordingly.
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .welcome:
                    WelcomeView(username: username)
                case .water:
                    WaterView(username: username)
                }
            }
        } .preferredColorScheme(.light)
    }
    
    // MARK: - Login Logic
    private func loginUser() {
        do {
            // Fetch the document
            if let document = try dbMgr.usersColl?.document(id: username) {
                print("Document retrieved: \(document.toDictionary())")
                showError = false
                // On successful login, add the selected destination to the path
                path.append(selectedDestination)
            } else {
                print("Document not found")
                showError = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        } catch {
            print("Error retrieving document: \(error)")
            showError = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}
