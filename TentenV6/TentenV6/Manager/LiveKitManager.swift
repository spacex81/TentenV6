import LiveKit 
import UIKit
import AVFAudio
import Foundation

class LiveKitManager: RoomDelegate {
    static let shared = LiveKitManager()
    private let audioSessionManager = CustomAudioManager.shared

    // LiveKit
    var room: Room?

    let livekitUrl = "wss://tentwenty-bp8gb2jg.livekit.cloud"
    let handleLiveKitTokenUrl = "https://us-central1-tentenv2-36556.cloudfunctions.net/handleLivekitToken"
    let handleRegularNotificationUrl = "https://us-central1-tentenv2-36556.cloudfunctions.net/handleRegularNotification"
    
    @Published var isConnected: Bool = false
    @Published var isPublished: Bool = false

    private var localAudioTrack: LocalAudioTrack?
    private var trackPublication: LocalTrackPublication?
    
    init() {
        AudioManager.shared.customConfigureAudioSessionFunc = customConfig
        
        let roomOptions = RoomOptions(adaptiveStream: true, dynacast: true)
        room = Room(delegate: self, roomOptions: roomOptions)
        
    }

    
    func connect() async {
        NSLog("LOG: Connecting to LiveKit")
        guard let room  = self.room else {
            print("Room is not set")
            return
        }
        
        let token = await fetchLivekitToken()
        guard let livekitToken = token else {
            print("Failed to fetch livekit access token")
            return
        }
        
        do {
            try await room.connect(url: livekitUrl, token: livekitToken)
            DispatchQueue.main.async {
                self.isConnected = true
            }
            NSLog("LOG: LiveKit Connected")
        } catch {
            print("Failed to connect to LiveKit Room")
        }
    }
    
    func disconnect() async {
        NSLog("LOG: Disconnecting from LiveKit")
        guard let room  = self.room else {
            print("Room is not set")
            return
        }

        if isPublished {
            await unpublishAudio()
        }
        await room.disconnect()
        self.localAudioTrack = nil
        self.trackPublication = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
        }
        
        NSLog("LOG: LiveKit disconnected")
    }
    
    func publishAudio() async {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            NSLog("LOG: Failed to setup audio session before publishing local track")
        }
        NSLog("LOG: Start publishing local LiveKit audio track")
        guard let room  = self.room else {
            NSLog("Room is not set")
            return
        }

        do {
            let localAudioTrack = LocalAudioTrack.createTrack()
            self.localAudioTrack = localAudioTrack
            self.trackPublication = try await room.localParticipant.publish(audioTrack: localAudioTrack)
            DispatchQueue.main.async {
                self.isPublished = true
            }
            NSLog("LOG: LiveKit Audio track Published")
        } catch {
            NSLog("Failed to publish local audio track to LiveKit Room")
        }
    }
    
    func unpublishAudio() async {
        guard let room  = self.room else {
            NSLog("Room is not set")
            return
        }

        if let publication = trackPublication {
            do {
                try await room.localParticipant.unpublish(publication: publication)
                DispatchQueue.main.async {
                    self.isPublished = false
                }

                self.localAudioTrack = nil
                self.trackPublication = nil
                NSLog("LOG: LiveKit Audio Unpublished")
            } catch {
                NSLog("Failed to unpublish local audio track: \(error)")
            }
        }
    }

    func fetchLivekitToken() async -> String? {
        guard let url = URL(string: handleLiveKitTokenUrl) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            return json?["livekitToken"] as? String
        } catch {
            NSLog("Failed to fetch token: \(error)")
            return nil
        }
    }
}

extension LiveKitManager {
    
    func customConfig(newState: AudioManager.State, oldState: AudioManager.State) {
    }
    
}
