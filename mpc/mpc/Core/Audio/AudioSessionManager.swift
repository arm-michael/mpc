import AVFoundation
import Foundation

/// Configures `AVAudioSession` and re-starts `AudioEngine` after interruptions.
///
/// Call `configure(for:)` once at app launch. Scene-phase transitions (background/foreground)
/// are handled in `mpcApp` via SwiftUI's `scenePhase` environment value.
final class AudioSessionManager {

    // MARK: - Shared instance

    static let shared = AudioSessionManager()

    // MARK: - Private

    private weak var engine: AudioEngine?

    private init() {}

    // MARK: - Public API

    /// Sets the audio session category, activates it, and starts the engine.
    func configure(for engine: AudioEngine) throws {
        self.engine = engine
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, options: .mixWithOthers)
        try session.setActive(true)
        try engine.start()
        observeInterruptions()
    }

    /// Re-activates the session and restarts the engine after a scene foreground transition.
    func resume() {
        guard let engine else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        try? engine.start()
    }

    // MARK: - Private helpers

    private func observeInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            engine?.stop()
        case .ended:
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            guard options.contains(.shouldResume) else { return }
            resume()
        @unknown default:
            break
        }
    }
}
