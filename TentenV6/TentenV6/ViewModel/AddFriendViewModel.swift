import Foundation
import Combine

class AddFriendViewModel: ObservableObject {
    private var firebaseManager: FirebaseManager
    
    @Published var user: UserModel?
    
    var uid: String? {
        return firebaseManager.auth.currentUser?.uid
    }
    
    private var cancellables = Set<AnyCancellable>()
     
    init(firebaseManager: FirebaseManager) {
        self.firebaseManager = firebaseManager
        
        bindFirebaseManager()
    }
    
    private func bindFirebaseManager() {
        firebaseManager.$user
            .assign(to: \.user, on: self)
            .store(in: &cancellables)
    }

    func addFriendByPin(currentUserId: String, friendPin: String, completion: @escaping (Result<String, Error>) -> Void) {
        firebaseManager.addFriendByPin(currentUserId: currentUserId, friendPin: friendPin, completion: completion)
    }
    
    func signOut() {
        NSLog("AddFriendViewModel-signOut")
        do {
            try firebaseManager.signOut()
        } catch {
            NSLog("kailed to signout: \(error)")
        }
    }
}

