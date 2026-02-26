import AVFoundation
import Foundation
import Observation

/// Manages preloaded `AVAudioPCMBuffer` instances and one-shot playback for all 8 pads.
///
/// Each pad gets a dedicated `AVAudioPlayerNode` attached to the shared `AudioEngine`.
/// Buffers are decoded at assign time so tap → audio latency is ≤200ms.
@Observable
final class PlaybackService {

    // MARK: - Private

    private let engine: AudioEngine
    private var nodes: [Int: AVAudioPlayerNode] = [:]
    private var buffers: [Int: AVAudioPCMBuffer] = [:]

    // MARK: - Init

    init(engine: AudioEngine) {
        self.engine = engine
    }

    // MARK: - Public API

    /// Decodes the WAV at `url`, converts to canonical format, and attaches a player node.
    /// Replaces any existing sample on `padIndex`.
    func preload(padIndex: Int, url: URL) throws {
        precondition((0...7).contains(padIndex))

        let buffer = try AudioConverter.load(url: url)

        // Tear down existing node for this pad before re-attaching.
        teardown(padIndex: padIndex)

        let node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: buffer.format)

        nodes[padIndex] = node
        buffers[padIndex] = buffer
    }

    /// Plays the preloaded buffer for `padIndex` from the beginning.
    /// Interrupts any currently-playing instance on that pad.
    /// No-ops silently if no buffer is loaded or the engine is not running.
    func play(padIndex: Int) {
        guard
            engine.isRunning,
            let node = nodes[padIndex],
            let buffer = buffers[padIndex]
        else { return }

        node.stop()
        node.scheduleBuffer(buffer, at: nil, options: .interrupts)
        node.play()
    }

    /// Removes the preloaded buffer and detaches the player node for `padIndex`.
    func unload(padIndex: Int) {
        teardown(padIndex: padIndex)
    }

    // MARK: - Private

    private func teardown(padIndex: Int) {
        if let existingNode = nodes[padIndex] {
            existingNode.stop()
            engine.detach(existingNode)
            nodes.removeValue(forKey: padIndex)
        }
        buffers.removeValue(forKey: padIndex)
    }
}
