
import SwiftUI

@main
struct MobileApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(iOS 26.0, *) {
                LoginView()
            } else {
                // Fallback on earlier versions
            }
        }
    }
}
