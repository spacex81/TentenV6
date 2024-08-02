import Combine
import Foundation
import SwiftUI

class HomeViewModel: ObservableObject {
    static let shared = HomeViewModel(liveKitManager: LiveKitManager.shared, firebaseManager: FirebaseManager.shared, audioSessionManager: CustomAudioManager.shared, backgroundTaskManager: BackgroundTaskManager.shared)

    private var liveKitManager: LiveKitManager
    private var firebaseManager: FirebaseManager
    private var audioManager: CustomAudioManager
    private var backgroundTaskManager: BackgroundTaskManager
    
    @Published var user: UserModel?
    @Published var friendsDetails: [UserModel] = []
    @Published var selectedFriend: UserModel?
    
    @Published var isConnected: Bool = false
    @Published var isPublished: Bool = false
    
    @Environment(\.scenePhase) private var scenePhase
    
    var senderToken: String? {
        firebaseManager.user?.deviceToken
    }
    var receiverToken: String? {
        selectedFriend?.deviceToken
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(liveKitManager: LiveKitManager, firebaseManager: FirebaseManager, audioSessionManager: CustomAudioManager, backgroundTaskManager: BackgroundTaskManager) {
        self.liveKitManager = liveKitManager
        self.firebaseManager = firebaseManager
        self.audioManager = audioSessionManager
        self.backgroundTaskManager = backgroundTaskManager
        
        bindFirestoreManager()
        bindLiveKitManager()
    }
    
    private func bindFirestoreManager() {
        firebaseManager.$user
            .assign(to: \.user, on: self)
            .store(in: &cancellables)
        
        firebaseManager.$friendsDetails
            .assign(to: \.friendsDetails, on: self)
            .store(in: &cancellables)
        
        firebaseManager.$selectedFriend
            .assign(to: \.selectedFriend, on: self)
            .store(in: &cancellables)
    }
    
    private func bindLiveKitManager() {
        liveKitManager.$isConnected
            .assign(to: \.isConnected, on: self)
            .store(in: &cancellables)
        
        liveKitManager.$isPublished
            .assign(to: \.isPublished, on: self)
            .store(in: &cancellables)
    }
    
    func listenToUser(userId: String) {
        print("UserViewModel-listenToUser")
        firebaseManager.listenToUser(userId: userId) { [weak self] user in
            guard let self = self else { return }
            if let user = user {
                NSLog("LOG: User fetched")
                print(user)
                handleIncomingCallRequest(user: user)
            } else {
                NSLog("user is nil")
            }
            self.fetchFriendsDetails()
        }
    }
    
    private func handleIncomingCallRequest(user: UserModel) {
        NSLog("handleIncomingCallRequest")
        if user.hasIncomingCallRequest {
            Task {
                await liveKitManager.connect()
            }
        } else {
            Task {
                await liveKitManager.disconnect()
            }
        }
    }
    
    func fetchFriendsDetails() {
        guard let friends = user?.friends else { return }
        firebaseManager.listenToFriends(friendIds: friends)
    }
    
    func addFriendByPin(currentUserId: String, friendPin: String, completion: @escaping (Result<String, Error>) -> Void) {
        firebaseManager.addFriendByPin(currentUserId: currentUserId, friendPin: friendPin, completion: completion)
    }
    
    func selectFriend(friend: UserModel) {
        firebaseManager.selectFriend(friend: friend)
    }
    
    func connect() async {
        guard let friendUid = selectedFriend?.id else {
            NSLog("Friend is not selected")
            return
        }
        
        await liveKitManager.connect()
        firebaseManager.updateCallRequest(friendUid: friendUid, hasIncomingCallRequest: true)
    }
    
    func disconnect() {
        guard let friendUid = selectedFriend?.id else {
            NSLog("Friend is not selected")
            return
        }

        Task {
            await liveKitManager.disconnect()
            firebaseManager.updateCallRequest(friendUid: friendUid, hasIncomingCallRequest: false)
        }
    }
    
    func publishAudio() {
        NSLog("LOG: HomeViewModel-publishAudio")
        Task {
            await liveKitManager.publishAudio()
        }
    }
    
    func unpublishAudio() async {
        await liveKitManager.unpublishAudio()
    }
}

extension HomeViewModel {
    func handleScenePhaseChange(to newScenePhase: ScenePhase) {
        switch newScenePhase {

        case .active:
             NSLog("LOG: App is active and in the foreground")


        case .inactive:
            NSLog("LOG: App is inactive")

        case .background:
            NSLog("LOG: App is in the background")
            audioManager.setupAudioPlayer()
            backgroundTaskManager.startAudioTask()

        @unknown default:
            break
        }
    }
}
