import AVFoundation
import Observation

/// Wraps `AVAudioEngine` and exposes the connection graph operations needed by `PlaybackService`.
///
/// Owned by the SwiftUI environment. `AudioSessionManager` starts and restarts the engine
/// around interruptions and scene-phase transitions.
@Observable
final class AudioEngine {

    // MARK: - Public state

    private(set) var isRunning = false

    // MARK: - Private

    private let engine: AVAudioEngine

    var mainMixerNode: AVAudioMixerNode { engine.mainMixerNode }

    // MARK: - Init

    init() {
        engine = AVAudioEngine()
    }

    // MARK: - Lifecycle

    func start() throws {
        guard !engine.isRunning else { return }
        try engine.start()
        isRunning = true
    }

    func stop() {
        engine.stop()
        isRunning = false
    }

    // MARK: - Graph management

    func attach(_ node: AVAudioNode) {
        engine.attach(node)
    }

    func detach(_ node: AVAudioNode) {
        engine.detach(node)
    }

    func connect(_ source: AVAudioNode, to destination: AVAudioNode, format: AVAudioFormat?) {
        engine.connect(source, to: destination, format: format)
    }
}
