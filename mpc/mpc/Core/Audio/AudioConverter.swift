import AVFoundation
import Foundation

/// Converts audio files to the app's canonical playback format: 44.1 kHz stereo float32.
enum AudioConverter {

    // MARK: - Target format

    static let targetSampleRate: Double = 44100
    static let targetChannelCount: AVAudioChannelCount = 2

    static let targetFormat: AVAudioFormat = {
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: targetSampleRate,
            channels: targetChannelCount
        ) else {
            preconditionFailure("Failed to create canonical 44.1kHz stereo format")
        }
        return format
    }()

    // MARK: - Public API

    /// Loads the WAV file at `url` and returns an `AVAudioPCMBuffer` in the target format.
    /// Resamples and/or up-mixes as needed. Throws on file read or conversion failure.
    static func load(url: URL) throws -> AVAudioPCMBuffer {
        let file = try AVAudioFile(forReading: url)
        let sourceFormat = file.processingFormat
        let target = targetFormat

        // Fast path — already in target format, read directly.
        if sourceFormat == target {
            return try readDirect(file: file, format: target)
        }

        // Conversion path — resample and/or up-mix.
        guard let converter = AVAudioConverter(from: sourceFormat, to: target) else {
            throw PlaybackError.conversionFailed
        }
        return try convert(file: file, using: converter, sourceFormat: sourceFormat, targetFormat: target)
    }

    // MARK: - Private helpers

    private static func readDirect(file: AVAudioFile, format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(file.length)
        ) else {
            throw PlaybackError.conversionFailed
        }
        try file.read(into: buffer)
        return buffer
    }

    private static func convert(
        file: AVAudioFile,
        using converter: AVAudioConverter,
        sourceFormat: AVAudioFormat,
        targetFormat: AVAudioFormat
    ) throws -> AVAudioPCMBuffer {
        // Read source into input buffer.
        guard let inputBuffer = AVAudioPCMBuffer(
            pcmFormat: sourceFormat,
            frameCapacity: AVAudioFrameCount(file.length)
        ) else {
            throw PlaybackError.conversionFailed
        }
        try file.read(into: inputBuffer)

        // Allocate output buffer with headroom for rounding.
        let ratio = targetFormat.sampleRate / sourceFormat.sampleRate
        let outputCapacity = AVAudioFrameCount(ceil(Double(file.length) * ratio)) + 512
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputCapacity
        ) else {
            throw PlaybackError.conversionFailed
        }

        // Run conversion — input is provided once.
        var inputConsumed = false
        var conversionError: NSError?
        let status = converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
            if inputConsumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            outStatus.pointee = .haveData
            inputConsumed = true
            return inputBuffer
        }

        if let conversionError { throw conversionError }
        guard status != .error else { throw PlaybackError.conversionFailed }
        return outputBuffer
    }
}
