//
//  HomeView.swift
//  TentenV6
//
//  Created by 조윤근 on 7/29/24.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase

    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    @State private var isSheetPresented: Bool = false

    var body: some View {
        VStack {
            if let user = homeViewModel.selectedFriend {
                VStack {
                    if let url = URL(string: user.profileImageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    
                    Text(user.username)
                        .font(.title)
                        .padding(.top, 10)
                }
                .padding(.bottom, 20)
            } else {
                VStack {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                        .foregroundColor(.gray)
                    
                    Text("No Friend Selected")
                        .font(.title)
                        .padding(.top, 10)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 20)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(homeViewModel.friendsDetails, id: \.id) { friend in
                        VStack {
                            if let url = URL(string: friend.profileImageUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(width: 70, height: 70)
                                        .clipShape(Circle())
                                        .shadow(radius: 10)
                                        .onTapGesture {
                                            homeViewModel.selectFriend(friend: friend)
                                        }
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                            
                            Text(friend.username)
                                .font(.caption)
                                .padding(.top, 5)
                        }
                    }
                }
            }
            .padding(.bottom, 40)
            
            Text(homeViewModel.isConnected ? "Connected" : "Tap to Connect")
                .foregroundColor(homeViewModel.selectedFriend == nil ? .gray : .blue)
                .onTapGesture {
                    guard homeViewModel.selectedFriend != nil else {return}
                    if !homeViewModel.isConnected {
                        Task {
                            await homeViewModel.connect()
                        }
                    } else {
                        homeViewModel.disconnect()
                    }
                }
                .padding(.bottom, 20)
            
            Text(homeViewModel.isPublished ? "Published" : "Tap to Publish")
                .foregroundColor(homeViewModel.selectedFriend == nil ? .gray : .blue)
                .onTapGesture {
                    guard homeViewModel.selectedFriend != nil else {return}
                    if !homeViewModel.isPublished {
                        homeViewModel.publishAudio()
                    } else {
                        Task {
                            await homeViewModel.unpublishAudio()
                        }
                    }
                }
                .padding(.bottom, 20)

            
            Button(action: {
                isSheetPresented = true
            }) {
                Text("Add Friend")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            if let uid = firebaseManager.auth.currentUser?.uid {
                homeViewModel.listenToUser(userId: uid)
            }
        }
        .onChange(of: scenePhase) { oldScenePhase, newScenePhase in
            homeViewModel.handleScenePhaseChange(to: newScenePhase)
        }
        .sheet(isPresented: $isSheetPresented) {
            AddFriendView()
        }
    }
}

#Preview {
    HomeView()
}
