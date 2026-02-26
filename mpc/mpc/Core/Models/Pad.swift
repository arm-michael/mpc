import Foundation

/// The playback mode of a pad sample.
/// Reserved for Phase 2 — default is `oneShot` in Phase 1.
enum PadMode: String, Codable {
    case oneShot
    case hold      // Phase 2
}

/// Metadata stored alongside a pad's WAV asset.
struct SampleMetadata: Codable, Equatable {
    let duration: TimeInterval
    let sampleRate: Double
    let channelCount: Int
    let createdAt: Date

    /// The text prompt used to generate this sample, if any.
    let originalPrompt: String?

    // MARK: - Phase 2 reserved fields

    /// Playback mode — defaults to .oneShot; Phase 2 will add .hold.
    var mode: PadMode

    /// Project identifier for future save/load support (Phase 2).
    var projectId: String?

    init(
        duration: TimeInterval,
        sampleRate: Double,
        channelCount: Int,
        createdAt: Date = Date(),
        originalPrompt: String? = nil,
        mode: PadMode = .oneShot,
        projectId: String? = nil
    ) {
        self.duration = duration
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.createdAt = createdAt
        self.originalPrompt = originalPrompt
        self.mode = mode
        self.projectId = projectId
    }

    // Explicit CodingKeys so synthesised init(from:) can decode.
    private enum CodingKeys: String, CodingKey {
        case duration, sampleRate, channelCount, createdAt
        case originalPrompt, mode, projectId
    }

    // Custom encode: emit `null` for nil optional fields so the JSON index
    // explicitly records absence rather than omitting keys entirely.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(duration, forKey: .duration)
        try c.encode(sampleRate, forKey: .sampleRate)
        try c.encode(channelCount, forKey: .channelCount)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(originalPrompt, forKey: .originalPrompt)
        try c.encode(mode, forKey: .mode)
        try c.encode(projectId, forKey: .projectId)
    }
}

/// Represents a single pad in the 8-pad grid.
struct Pad: Codable, Identifiable, Equatable {
    /// Pad index 0–7, corresponding to grid position.
    let id: Int

    /// URL of the assigned .wav file in the app sandbox, if any.
    var sampleURL: URL?

    /// Metadata for the assigned sample, if any.
    var metadata: SampleMetadata?

    var hasSample: Bool { sampleURL != nil }

    init(id: Int, sampleURL: URL? = nil, metadata: SampleMetadata? = nil) {
        precondition((0...7).contains(id), "Pad id must be in range 0–7")
        self.id = id
        self.sampleURL = sampleURL
        self.metadata = metadata
    }

    // Explicit CodingKeys so synthesised init(from:) can decode.
    private enum CodingKeys: String, CodingKey {
        case id, sampleURL, metadata
    }

    // Custom encode: emit `null` for nil optional fields.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(sampleURL, forKey: .sampleURL)
        try c.encode(metadata, forKey: .metadata)
    }
}
