import UIKit
import AVFoundation
import UserNotifications
import FirebaseCore
import FirebaseAuth

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    private var firebaseManager: FirebaseManager?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        FirebaseApp.configure()
        
        requestNotificationPermission(application: application)
        requestMicrophonePermission()

        return true
    }
}

// MARK: - Push Notification Delegate
extension AppDelegate {
    private func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) {
        print("Notification received in foreground: \(notification.request.content.userInfo)")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Notification tapped: \(response.notification.request.content.userInfo)")
        completionHandler()
    }

    // Register for remote notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(tokenString)")
        
        NotificationCenter.default.post(name: .didReceiveDeviceToken, object: nil, userInfo: ["deviceToken": tokenString])
        updateDeviceTokenIfNeeded(newToken: tokenString)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}


// MARK: - Notification and Microphone Permissions
extension AppDelegate {
    private func requestNotificationPermission(application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func requestMicrophonePermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                if granted {
                    print("Microphone permission granted")
                } else {
                    print("Microphone permission denied")
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    print("Microphone permission granted")
                } else {
                    print("Microphone permission denied")
                }
            }
        }
    }
}

// MARK: - Device Token Management
extension AppDelegate {
    private func updateDeviceTokenIfNeeded(newToken: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        firebaseManager = FirebaseManager.shared
        guard let firebaseManager = firebaseManager else {return}
        
        firebaseManager.fetchUserById(currentUserId) { result in
            switch result {
            case .success(let user):
                if user.deviceToken != newToken {
                    let updatedUser = user
                    updatedUser.deviceToken = newToken
                    firebaseManager.updateUser(user: updatedUser) { updateResult in
                        switch updateResult {
                        case .success:
                            print("Device token updated successfully in Firestore.")
                        case .failure(let error):
                            print("Failed to update device token in Firestore: \(error.localizedDescription)")
                        }
                    }
                } else {
                    print("Device token is already up to date.")
                }
            case .failure(let error):
                print("Failed to fetch user: \(error.localizedDescription)")
                do {
                    try firebaseManager.signOut()
                } catch {
                    
                }
            }
        }
    }
}


extension Notification.Name {
    static let didReceiveDeviceToken = Notification.Name("didReceiveDeviceToken")
}
