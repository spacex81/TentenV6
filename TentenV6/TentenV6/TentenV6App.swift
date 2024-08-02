import SwiftUI
import LiveKit

@main
struct TentenV6App: App {
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(FirebaseManager.shared)
                .environmentObject(CustomAudioManager.shared)
                .environmentObject(BackgroundTaskManager(audioManager: CustomAudioManager.shared, liveKitManager: LiveKitManager.shared))
                .environmentObject(HomeViewModel(liveKitManager: LiveKitManager.shared, firebaseManager: FirebaseManager.shared, audioSessionManager: CustomAudioManager.shared, backgroundTaskManager: BackgroundTaskManager.shared))
                .environmentObject(AuthViewModel(firebaseManager: FirebaseManager.shared))
                .environmentObject(AddFriendViewModel(firebaseManager: FirebaseManager.shared))
        }
    }
    
}
