import SwiftUI
 
struct AddFriendView: View {
    @Environment(\.dismiss) var dismiss
    @State private var friendPin: String = ""
    @EnvironmentObject var addFriendViewModel: AddFriendViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Friend")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let userPin = addFriendViewModel.user?.pin {
                Text("Your PIN: \(userPin)")
                    .font(.headline)
                    .padding()
            }
            
            TextField("Enter Friend's PIN", text: $friendPin)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            
            Button(action: {
                friendPin = friendPin.lowercased()
                addFriend()
            }) {
                Text("Add Friend")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Button(action: {
                addFriendViewModel.signOut()
            }) {
                Text("Sign Out")
                    .font(.title2)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
    }
    
    private func addFriend() {
        guard let uid = addFriendViewModel.uid else {
            NSLog("user is not set")
            return
        }
        
        addFriendViewModel.addFriendByPin(currentUserId: uid, friendPin: friendPin) { result in
            switch result {
            case .success(let friendId):
                NSLog("Friend added with ID: \(friendId)")
                dismiss()
            case .failure(let error):
                NSLog("Failed to add friend: \(error.localizedDescription)")
            }
        }
    }

}

