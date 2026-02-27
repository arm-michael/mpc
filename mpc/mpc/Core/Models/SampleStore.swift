import Foundation
import Observation

/// Manages the persistence of all 8 pad assignments.
///
/// Owns two storage locations:
///   - `Documents/pad_index.json` — the canonical pad → sample mapping
///   - `Documents/samples/{padID}_{uuid}.wav` — the audio assets
///
/// `init()` is deliberately free of file I/O so it never blocks the main
/// thread.  Call `loadPersisted()` once from a `Task.detached` block after
/// the app's main run loop has started to restore previously saved state.
/// All mutations call `save()` immediately.
@Observable
final class SampleStore {

    // MARK: - Public state

    private(set) var pads: [Pad]

    // MARK: - Private

    private let fileManager: FileManager

    /// Minimum free space required before accepting a write (100 MB).
    private static let minimumFreeSpaceBytes: Int64 = 100 * 1024 * 1024

    /// Resolved lazily on first file access so that init() never calls
    /// fileManager.urls(for:in:) on the main thread — that call contacts the
    /// iOS sandbox-container daemon which can block for minutes in headless
    /// CI environments where the container is not yet provisioned.
    @ObservationIgnored private lazy var documentsURL: URL = {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
    }()

    @ObservationIgnored private lazy var samplesDirectory: URL =
        documentsURL.appendingPathComponent("samples", isDirectory: true)

    @ObservationIgnored private lazy var indexURL: URL =
        documentsURL.appendingPathComponent("pad_index.json")

    // MARK: - Init

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.pads = (0...7).map { Pad(id: $0) }
        // No file I/O here. URL resolution and disk loading are deferred to
        // loadPersisted() so that SampleStore can be created on any thread
        // without blocking.
    }

    // MARK: - Public API

    /// Restores the pad index from disk.
    ///
    /// Designed to be called once from a `Task.detached` block in mpcApp
    /// so the sandbox-directory lookup never blocks the main run loop.
    func loadPersisted() {
        load()
    }

    /// Assigns a WAV file at `sourceURL` to the pad at `padIndex`.
    /// Copies the file into the app sandbox, updates the index.
    @discardableResult
    func assign(sampleAt sourceURL: URL, toPad padIndex: Int, metadata: SampleMetadata) throws -> URL {
        precondition((0...7).contains(padIndex))
        try checkStorageAvailability()
        createSamplesDirectoryIfNeeded()

        let uuid = UUID().uuidString
        let filename = "\(padIndex)_\(uuid).wav"
        let destinationURL = samplesDirectory.appendingPathComponent(filename)

        if let existingURL = pads[padIndex].sampleURL {
            try? fileManager.removeItem(at: existingURL)
        }

        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        pads[padIndex] = Pad(id: padIndex, sampleURL: destinationURL, metadata: metadata)
        try save()
        return destinationURL
    }

    /// Removes the sample assigned to the pad at `padIndex`.
    func removeSample(fromPad padIndex: Int) throws {
        precondition((0...7).contains(padIndex))

        if let existingURL = pads[padIndex].sampleURL {
            try? fileManager.removeItem(at: existingURL)
        }
        pads[padIndex] = Pad(id: padIndex)
        try save()
    }

    /// Deletes orphaned .wav files in the samples directory not referenced in the index.
    func cleanupOrphans() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: samplesDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        let referencedURLs = Set(pads.compactMap(\.sampleURL))
        for file in files where !referencedURLs.contains(file) {
            try? fileManager.removeItem(at: file)
        }
    }

    /// Returns `true` if at least 100 MB of free space is available.
    func hasAvailableStorage() -> Bool {
        guard let available = availableDiskSpaceBytes() else { return true }
        return available >= Self.minimumFreeSpaceBytes
    }

    // MARK: - Private

    private func createSamplesDirectoryIfNeeded() {
        guard !fileManager.fileExists(atPath: samplesDirectory.path) else { return }
        try? fileManager.createDirectory(at: samplesDirectory, withIntermediateDirectories: true)
    }

    private func load() {
        guard fileManager.fileExists(atPath: indexURL.path),
              let data = try? Data(contentsOf: indexURL)
        else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([Pad].self, from: data),
              decoded.count == 8
        else { return }

        // Filter out any pads whose sample file no longer exists on disk
        pads = decoded.map { pad in
            guard let url = pad.sampleURL,
                  fileManager.fileExists(atPath: url.path)
            else {
                return Pad(id: pad.id)
            }
            return pad
        }
    }

    private func save() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(pads)
        try data.write(to: indexURL, options: .atomic)
    }

    private func checkStorageAvailability() throws {
        guard let available = availableDiskSpaceBytes(),
              available < Self.minimumFreeSpaceBytes
        else { return }
        throw StorageError.insufficientSpace(
            available: available,
            required: Self.minimumFreeSpaceBytes
        )
    }

    private func availableDiskSpaceBytes() -> Int64? {
        let values = try? samplesDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage.map { Int64($0) }
    }
}
