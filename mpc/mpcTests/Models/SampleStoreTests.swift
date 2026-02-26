import Testing
import Foundation
@testable import mpc

// Tests share the simulator's Documents directory via SampleStore — run serially.
@Suite(.serialized)
struct SampleStoreTests {

    // MARK: - Helpers

    /// Creates a temporary directory for each test, cleaned up on deinit.
    private func makeTemporaryStore() -> (store: SampleStore, tempDir: URL) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // SampleStore uses FileManager.default's Documents directory, so we use
        // the real store for integration-style tests. For isolated unit tests we
        // verify behaviour via the public API.
        let store = SampleStore()
        return (store, tempDir)
    }

    private func makeTempWAV(in directory: URL, name: String = "test.wav") throws -> URL {
        let url = directory.appendingPathComponent(name)
        // Write minimal valid WAV header + silence (44 bytes header, 0 data frames)
        var wav = Data()
        func append(_ string: String) { wav.append(contentsOf: string.utf8) }
        func append32LE(_ value: UInt32) {
            wav.append(UInt8(value & 0xFF))
            wav.append(UInt8((value >> 8) & 0xFF))
            wav.append(UInt8((value >> 16) & 0xFF))
            wav.append(UInt8((value >> 24) & 0xFF))
        }
        func append16LE(_ value: UInt16) {
            wav.append(UInt8(value & 0xFF))
            wav.append(UInt8((value >> 8) & 0xFF))
        }
        append("RIFF"); append32LE(36); append("WAVE")
        append("fmt "); append32LE(16); append16LE(1) // PCM
        append16LE(2)       // channels
        append32LE(44100)   // sample rate
        append32LE(176400)  // byte rate
        append16LE(4)       // block align
        append16LE(16)      // bits per sample
        append("data"); append32LE(0)
        try wav.write(to: url)
        return url
    }

    // MARK: - Init

    @Test func test_store_init_creates8EmptyPads() {
        let store = SampleStore()
        #expect(store.pads.count == 8)
        #expect(store.pads.allSatisfy { !$0.hasSample })
    }

    @Test func test_store_init_padIdsAre0Through7() {
        let store = SampleStore()
        let ids = store.pads.map(\.id)
        #expect(ids == [0, 1, 2, 3, 4, 5, 6, 7])
    }

    // MARK: - Assign

    @Test func test_store_assign_padHasSampleAfterAssignment() throws {
        let store = SampleStore()
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let wavURL = try makeTempWAV(in: tempDir)
        let meta = SampleMetadata(duration: 0.0, sampleRate: 44100, channelCount: 2)

        try store.assign(sampleAt: wavURL, toPad: 0, metadata: meta)
        #expect(store.pads[0].hasSample)
    }

    @Test func test_store_assign_destinationFileExists() throws {
        let store = SampleStore()
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let wavURL = try makeTempWAV(in: tempDir)
        let meta = SampleMetadata(duration: 0.0, sampleRate: 44100, channelCount: 2)

        let destURL = try store.assign(sampleAt: wavURL, toPad: 1, metadata: meta)
        #expect(FileManager.default.fileExists(atPath: destURL.path))
    }

    // MARK: - Remove

    @Test func test_store_remove_padBecomesEmptyAfterRemoval() throws {
        let store = SampleStore()
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let wavURL = try makeTempWAV(in: tempDir)
        let meta = SampleMetadata(duration: 0.0, sampleRate: 44100, channelCount: 2)
        try store.assign(sampleAt: wavURL, toPad: 2, metadata: meta)

        try store.removeSample(fromPad: 2)
        #expect(!store.pads[2].hasSample)
    }

    // MARK: - Persistence

    @Test func test_store_save_and_reload_restoresPadAssignment() throws {
        let store = SampleStore()
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let wavURL = try makeTempWAV(in: tempDir)
        let meta = SampleMetadata(
            duration: 1.0,
            sampleRate: 44100,
            channelCount: 2,
            originalPrompt: "test prompt"
        )
        try store.assign(sampleAt: wavURL, toPad: 3, metadata: meta)

        // Re-initialize store — should reload from disk
        let reloaded = SampleStore()
        #expect(reloaded.pads[3].hasSample)
        #expect(reloaded.pads[3].metadata?.originalPrompt == "test prompt")
    }

    // MARK: - Storage check

    @Test func test_store_hasAvailableStorage_returnsTrue_onDev() {
        // On a development machine there should always be >100MB free.
        let store = SampleStore()
        #expect(store.hasAvailableStorage())
    }
}
