import SwiftUI

struct AuthView: View {
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack {
            Picker(selection: $isLoginMode, label: Text("Mode")) {
                Text("Login")
                    .tag(true)
                Text("Sign Up")
                    .tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if !isLoginMode {
                Button(action: {
                    isImagePickerPresented.toggle()
                }) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            .shadow(radius: 10)
                    } else {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                }
                .padding()

                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5.0)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5.0)
                
            } else {
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5.0)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5.0)
            }

            Button(action: {
                isLoginMode ?
                authViewModel.login(email: self.email, password: self.password) :
                authViewModel.signUp(email: self.email, password: self.password, selectedImage: self.selectedImage)
            }) {
                Text(isLoginMode ? "Login" : "Sign Up")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10.0)
            }
            .padding(.top, 20)

            Spacer()
        }
        .padding()
        .fullScreenCover(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage)
        }
    }
}

//struct AuthView_Previews: PreviewProvider {
//    static var previews: some View {
//        AuthView()
//            .environmentObject(AuthViewModel(firestoreManager: FirestoreManager()))
//    }
//}
