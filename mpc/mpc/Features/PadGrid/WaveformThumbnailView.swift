import AVFoundation
import SwiftUI

/// Renders a simplified peak-amplitude waveform from an audio file URL.
struct WaveformThumbnailView: View {

    let url: URL

    @State private var samples: [Float] = []

    var body: some View {
        Canvas { context, size in
            guard !samples.isEmpty else { return }
            let midY = size.height / 2
            let step = size.width / CGFloat(samples.count)
            var path = Path()
            for (index, sample) in samples.enumerated() {
                let xPos = CGFloat(index) * step + step / 2
                let amplitude = CGFloat(sample) * midY
                path.move(to: CGPoint(x: xPos, y: midY - amplitude))
                path.addLine(to: CGPoint(x: xPos, y: midY + amplitude))
            }
            context.stroke(path, with: .color(.accentColor), lineWidth: 1.5)
        }
        .task(id: url) {
            samples = await computeSamples(from: url)
        }
    }

    // MARK: - Private

    private func computeSamples(from sampleURL: URL, count: Int = 80) async -> [Float] {
        await Task.detached(priority: .userInitiated) {
            guard
                let file = try? AVAudioFile(forReading: sampleURL),
                let buffer = AVAudioPCMBuffer(
                    pcmFormat: file.processingFormat,
                    frameCapacity: AVAudioFrameCount(file.length)
                ),
                (try? file.read(into: buffer)) != nil,
                let channelData = buffer.floatChannelData?[0]
            else { return [] }

            let frameCount = Int(buffer.frameLength)
            let chunkSize = max(1, frameCount / count)
            var result: [Float] = []
            result.reserveCapacity(count)
            for chunkIndex in 0..<count {
                let start = chunkIndex * chunkSize
                let end = min(start + chunkSize, frameCount)
                guard start < end else { break }
                var maxAmp: Float = 0
                for frameIndex in start..<end {
                    let absVal = abs(channelData[frameIndex])
                    if absVal > maxAmp { maxAmp = absVal }
                }
                result.append(maxAmp)
            }
            return result
        }.value
    }
}
