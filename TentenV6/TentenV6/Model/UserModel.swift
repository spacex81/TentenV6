import Foundation
import FirebaseFirestore

class UserModel: Codable, Identifiable, CustomStringConvertible, Equatable {
    @DocumentID var id: String?
    var username: String
    var deviceToken: String
    var profileImageUrl: String
    var pin: String
    var friends: [String]
    var hasIncomingCallRequest: Bool = false  // New property

    init(id: String? = nil, username: String, deviceToken: String, profileImageUrl: String, friends: [String] = [], hasIncomingCallRequest: Bool = false) {
        self.id = id
        self.username = username
        self.deviceToken = deviceToken
        self.profileImageUrl = profileImageUrl
        self.pin = UserModel.generatePin()
        self.friends = friends
        self.hasIncomingCallRequest = hasIncomingCallRequest
    }
    
    var description: String {
        """
        UserModel:
        - ID: \(id ?? "nil")
        - Device Token: \(deviceToken)
        - Username: \(username)
        - Profile Image URL: \(profileImageUrl)
        - PIN: \(pin)
        - Friends: \(friends.joined(separator: ", "))
        - Has Incoming Call Request: \(hasIncomingCallRequest)
        """
    }
    
    static func generatePin() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<7).map { _ in letters.randomElement()! })
    }
    
    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.username == rhs.username &&
               lhs.deviceToken == rhs.deviceToken &&
               lhs.profileImageUrl == rhs.profileImageUrl &&
               lhs.pin == rhs.pin &&
               lhs.friends == rhs.friends &&
               lhs.hasIncomingCallRequest == rhs.hasIncomingCallRequest
    }
}

