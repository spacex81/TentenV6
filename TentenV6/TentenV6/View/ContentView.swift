import SwiftUI

struct ContentView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager

    var body: some View {
        if firebaseManager.isUserLoggedIn {
            HomeView()
        } else {
            AuthView()
        }
    }
}

#Preview {
    ContentView()
}


