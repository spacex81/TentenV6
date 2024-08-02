import FirebaseAuth
import FirebaseStorage
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    private var deviceToken: String?
    
    private var firebaseManager: FirebaseManager

    private var cancellables = Set<AnyCancellable>()
    
    var isUserLoggedIn: Bool {
        return firebaseManager.isUserLoggedIn
    }
    var uid: String? {
        return firebaseManager.auth.currentUser?.uid
    }
    
    init(firebaseManager: FirebaseManager) {
        self.firebaseManager = firebaseManager
        
        bindFirebaseManager()
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceTokenNotification(_:)), name: .didReceiveDeviceToken, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .didReceiveDeviceToken, object: nil)
    }
    
    private func bindFirebaseManager() {
        firebaseManager.$isUserLoggedIn
            .sink { [weak self] isLoggedIn in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    @objc private func handleDeviceTokenNotification(_ notification: Notification) {
        NSLog("handleDeviceTokenNotification")
        if let token = notification.userInfo?["deviceToken"] as? String {
            self.deviceToken = token
            self.firebaseManager.deviceToken = token
        }
    }
    
    func login(email: String, password: String) {
        firebaseManager.login(email: email, password: password) { [weak self] result in
            guard let _ = self else { return }
            switch result {
            case .success(let user):
                print("User logged in: \(user.uid)")
            case .failure(let error):
                print("AuthViewModel-login: Failed to Login Firebase Auth: \(error)")
            }
        }
    }
    
    func signUp(email: String, password: String, selectedImage: UIImage?) {
        NSLog("AuthViewModel-signUp")
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.8) else {
            NSLog("Failed to Process Image")
            return
        }
        guard let deviceToken = self.deviceToken else {
            NSLog("deviceToken is not set")
            return
        }

        firebaseManager.signUp(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let user):
                let uid = user.uid
                self.firebaseManager.uploadProfileImage(uid: uid, imageData: imageData) { result in
                    switch result {
                    case .success(let url):
                        let profileImageUrl = url.absoluteString
                        let userModel = UserModel(
                            id: uid,
                            username: email.split(separator: "@").first.map(String.init) ?? "User",
                            deviceToken: deviceToken,
                            profileImageUrl: profileImageUrl
                        )
                        
                        self.firebaseManager.addUser(user: userModel, uid: uid) { result in
                            switch result {
                            case .success(let userId):
                                print("User added with ID: \(userId)")
                            case .failure(let error):
                                print("Failed to save UserModel to Firebase Firestore: \(error)")
                            }
                        }
                    case .failure(let error):
                        print("AuthViewModel-signUp: Failed to upload profile image: \(error)")
                    }
                }
            case .failure(let error):
                print("AuthViewModel-signUp: Failed to Create User: \(error)")
            }
        }
    }
    
    func signOut() {
        do {
            try firebaseManager.signOut()
        } catch {
            print("Failed to signOut: \(error)")
        }
    }
}
