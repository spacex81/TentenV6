import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private let db = Firestore.firestore()
    let auth = Auth.auth()
    private let storage = Storage.storage()
    
    // auth
    @Published var deviceToken: String? {
        didSet {
            NSLog("LOG: deviceToken: \(String(describing: deviceToken))")
        }
    }
    @Published var isUserLoggedIn: Bool = false
    
    // database
    @Published var user: UserModel?
    @Published var friendsDetails: [UserModel] = []
    @Published var selectedFriend: UserModel? {
        didSet {
            if let selectedFriend = selectedFriend {
                NSLog("Selected friend changed to: \(String(describing: selectedFriend.id))")
            } else {
                print("Selected friend is nil")
            }
        }
    }
    
    var receiverToken: String?
    
    private var userListener: ListenerRegistration?
    private var friendsListeners: [ListenerRegistration] = []
    

    init() {
        isUserLoggedIn = auth.currentUser != nil
    }
    
    deinit {
        userListener?.remove()
        friendsListeners.forEach { $0.remove() }
    }
}

// MARK: Database
extension FirebaseManager {
    func fetchUserById(_ userId: String, completion: @escaping (Result<UserModel, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let user = try document.data(as: UserModel.self)
                    completion(.success(user))
                } catch let error {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
            }
        }
    }

    func addUser(user: UserModel, uid: String, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            try db.collection("users").document(uid).setData(from: user)
            completion(.success(uid))
        } catch let error {
            completion(.failure(error))
        }
    }
    
    func updateUser(user: UserModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = user.id else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID is nil"])))
            return
        }
        
        do {
            try db.collection("users").document(userId).setData(from: user)
            completion(.success(()))
        } catch let error {
            completion(.failure(error))
        }
    }

    func addFriendByPin(currentUserId: String, friendPin: String, completion: @escaping (Result<String, Error>) -> Void) {
        let usersCollection = db.collection("users")
        
        usersCollection.whereField("pin", isEqualTo: friendPin).getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents, let document = documents.first else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user found with this PIN"])))
                return
            }
            
            let friendId = document.documentID
            let currentUserRef = usersCollection.document(currentUserId)
            
            currentUserRef.updateData([
                "friends": FieldValue.arrayUnion([friendId])
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(friendId))
                }
            }
        }
    }
    
    func listenToUser(userId: String, completion: @escaping (UserModel?) -> Void) {
        NSLog("FirestoreManager-listenToUser")
        userListener?.remove()
        userListener = db.collection("users").document(userId).addSnapshotListener { document, error in
            if let document = document, document.exists {
                do {
                    let user = try document.data(as: UserModel.self)
                    self.user = user
                    completion(user)
                } catch let error {
                    print("Error decoding user: \(error.localizedDescription)")
                    completion(nil)
                }
            } else {
                print("Error fetching user: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    
    func listenToFriend(friendId: String) {
        let friendListener = db.collection("users").document(friendId).addSnapshotListener { document, error in
            if let document = document, document.exists {
                do {
                    let friend = try document.data(as: UserModel.self)
                    if let index = self.friendsDetails.firstIndex(where: { $0.id == friend.id }) {
                        self.friendsDetails[index] = friend
                    } else {
                        self.friendsDetails.append(friend)
                    }
                } catch let error {
                    print("Error decoding friend: \(error.localizedDescription)")
                }
            } else {
                print("Error fetching friend: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        friendsListeners.append(friendListener)
    }
    
    func listenToFriends(friendIds: [String]) {
        friendsListeners.forEach { $0.remove() }
        friendsListeners = []
        friendIds.forEach { listenToFriend(friendId: $0) }
    }
    
    func selectFriend(friend: UserModel) {
        self.selectedFriend = friend
        self.receiverToken = friend.deviceToken
    }
    
    func updateCallRequest(friendUid: String, hasIncomingCallRequest: Bool) {
        let friendRef = db.collection("users").document(friendUid)
        friendRef.updateData(["hasIncomingCallRequest": hasIncomingCallRequest]) { error in
            if let error = error {
                NSLog("Error updating call request: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: Auth
extension FirebaseManager {
    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("AuthManager-login: Failed to Login Firebase Auth: \(error)")
                completion(.failure(error))
                return
            }
            if let user = result?.user {
                self.isUserLoggedIn = true
                completion(.success(user))
            }
        }
    }
    
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("AuthManager-signUp: Failed to Create User: \(error)")
                completion(.failure(error))
                return
            }
            if let user = result?.user {
                self.isUserLoggedIn = true
                completion(.success(user))
            }
        }
    }
    
    func signOut() throws {
        NSLog("LOG: signOut")
        try auth.signOut()
        self.isUserLoggedIn = false
    }
}

// MARK: Storage
extension FirebaseManager {
    func uploadProfileImage(uid: String, imageData: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = Storage.storage().reference().child("profile_images").child("\(uid).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("LOG: Failed to Store Profile Image to Firebase Storage: \(error)")
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("LOG: Failed to Get Profile Image Url from Firebase Storage: \(error)")
                    completion(.failure(error))
                    return
                }

                if let url = url {
                    completion(.success(url))
                }
            }
        }
    }
}

