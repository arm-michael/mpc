import Foundation

/// Errors related to audio playback and format conversion.
enum PlaybackError: LocalizedError {
    case engineNotRunning
    case conversionFailed
    case bufferLoadFailed(url: URL)

    var errorDescription: String? {
        switch self {
        case .engineNotRunning:
            return "Audio engine is not running. Please restart the app."
        case .conversionFailed:
            return "Could not convert audio to playback format."
        case .bufferLoadFailed(let url):
            return "Could not load audio sample at \(url.lastPathComponent)."
        }
    }
}
