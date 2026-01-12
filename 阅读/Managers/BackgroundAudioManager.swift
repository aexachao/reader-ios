import Foundation
import AVFoundation

final class BackgroundAudioManager {
    static let shared = BackgroundAudioManager()

    private init() {}

    private var isActive = false

    /// Activate audio session for background audio. Requires Background Modes > Audio in Capabilities.
    func start() {
        guard !isActive else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
            isActive = true
            log("Activated audio session for background playback")
        } catch {
            log("Failed to activate audio session: \(error)")
        }
    }

    func stop() {
        guard isActive else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false)
            isActive = false
            log("Deactivated audio session")
        } catch {
            log("Failed to deactivate audio session: \(error)")
        }
    }

    private func log(_ message: String) {
        #if DEBUG
        print("[BackgroundAudioManager] \(message)")
        #endif
    }
}
