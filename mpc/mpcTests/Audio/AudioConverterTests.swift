import AVFoundation
import Foundation
import Testing
@testable import mpc

struct AudioConverterTests {

    // MARK: - Helpers

    /// Writes a minimal PCM WAV to `url` with the specified format (16-bit, 256 frames of silence).
    private func makeWAV(at url: URL, sampleRate: UInt32, channelCount: UInt16) throws {
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

        let bitsPerSample: UInt16 = 16
        let blockAlign = channelCount * (bitsPerSample / 8)
        let byteRate = sampleRate * UInt32(blockAlign)
        let frameCount: UInt32 = 256
        let dataSize = frameCount * UInt32(blockAlign)

        append("RIFF"); append32LE(36 + dataSize); append("WAVE")
        append("fmt "); append32LE(16); append16LE(1) // PCM
        append16LE(channelCount)
        append32LE(sampleRate)
        append32LE(byteRate)
        append16LE(blockAlign)
        append16LE(bitsPerSample)
        append("data"); append32LE(dataSize)
        wav.append(Data(count: Int(dataSize))) // silence

        try wav.write(to: url)
    }

    // MARK: - Tests

    @Test func test_audioConverter_48kHzStereoTo441kHz() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let url = tempDir.appendingPathComponent("48khz_stereo.wav")
        try makeWAV(at: url, sampleRate: 48000, channelCount: 2)

        let buffer = try AudioConverter.load(url: url)

        #expect(buffer.format.sampleRate == AudioConverter.targetSampleRate)
        #expect(buffer.format.channelCount == AudioConverter.targetChannelCount)
        #expect(buffer.frameLength > 0)
    }

    @Test func test_audioConverter_monoTo441kHzStereo() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let url = tempDir.appendingPathComponent("44100hz_mono.wav")
        try makeWAV(at: url, sampleRate: 44100, channelCount: 1)

        let buffer = try AudioConverter.load(url: url)

        #expect(buffer.format.channelCount == AudioConverter.targetChannelCount)
        #expect(buffer.format.sampleRate == AudioConverter.targetSampleRate)
    }

    @Test func test_audioConverter_44kHzStereo_fastPath() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let url = tempDir.appendingPathComponent("44100hz_stereo.wav")
        try makeWAV(at: url, sampleRate: 44100, channelCount: 2)

        let buffer = try AudioConverter.load(url: url)

        #expect(buffer.format.sampleRate == AudioConverter.targetSampleRate)
        #expect(buffer.format.channelCount == AudioConverter.targetChannelCount)
        #expect(buffer.frameLength == 256)
    }
}
