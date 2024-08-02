import Foundation
import UIKit

class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager(audioManager: CustomAudioManager.shared, liveKitManager: LiveKitManager.shared)
    private let audioManager: CustomAudioManager
    private let liveKitManager: LiveKitManager

    var liveKitTaskId: UIBackgroundTaskIdentifier = .invalid
    var audioTaskId: UIBackgroundTaskIdentifier = .invalid
    
    var isBackgroundAudioTaskRunning = false
    
    init(audioManager: CustomAudioManager, liveKitManager: LiveKitManager) {
        self.audioManager = audioManager
        self.liveKitManager = liveKitManager
    }
}

// MARK: LiveKit background task
extension BackgroundTaskManager {
    func startLiveKitTask() {
        liveKitTaskId = UIApplication.shared.beginBackgroundTask(withName: "LiveKitTask") {
            self.endLiveKitTask()
        }

        guard liveKitTaskId != .invalid else {
            print("Failed to start LiveKit background task!")
            return
        }

        DispatchQueue.global(qos: .background).async {
            self.handleLiveKitTask()
        }
    }
    
    private func endLiveKitTask() {
        NSLog("LOG: LiveKit background task ended")
        if liveKitTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(liveKitTaskId)
            liveKitTaskId = .invalid
        }
    }

    private func handleLiveKitTask() {
        Task {
            await liveKitManager.connect()
        }
    }
}

// MARK: test audio background task
extension BackgroundTaskManager {
    func startAudioTask() {
        NSLog("LOG: Starting background audio task")
        endAudioTask()
        
        audioTaskId = UIApplication.shared.beginBackgroundTask(withName: "AudioTask") {
            self.endAudioTask()
        }
        
        guard audioTaskId != .invalid else {
            NSLog("LOG: Failed to start audio background task")
            return
        }
        
        isBackgroundAudioTaskRunning = true
        DispatchQueue.global(qos: .background).async {
            self.handleAudioTask()
        }
    }
    
    func endAudioTask() {
        isBackgroundAudioTaskRunning = false
        NSLog("LOG: Ending background audio task")
        if audioTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(audioTaskId)
            audioTaskId = .invalid
        }
    }
    
    func stopAudioTask() {
        audioManager.stopTestAudio()
        endAudioTask()
    }
    
    func handleAudioTask() {
        audioManager.playTestAudio()
        
        for i in 1...30 {
            if !isBackgroundAudioTaskRunning {
                break
            }
            if let player = audioManager.audioPlayer, player.isPlaying {
                NSLog("LOG: Playing silent audio(\(i))...")
            }
            sleep(1)
        }

        audioManager.stopTestAudio()
        
        if isBackgroundAudioTaskRunning {
            startAudioTask()
        }
    }

}

// MARK: LiveKit background task
extension BackgroundTaskManager {
    
}

