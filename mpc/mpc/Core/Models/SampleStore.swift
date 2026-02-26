import Foundation
import Observation

/// Manages the persistence of all 8 pad assignments.
///
/// Owns two storage locations:
///   - `Documents/pad_index.json` — the canonical pad → sample mapping
///   - `Documents/samples/{padID}_{uuid}.wav` — the audio assets
///
/// All mutations call `save()` immediately. On init, `load()` restores state.
@Observable
final class SampleStore {

    // MARK: - Public state

    private(set) var pads: [Pad]

    // MARK: - Private

    private let fileManager: FileManager
    private let samplesDirectory: URL
    private let indexURL: URL

    /// Minimum free space required before accepting a write (100 MB).
    private static let minimumFreeSpaceBytes: Int64 = 100 * 1024 * 1024

    // MARK: - Init

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.pads = (0...7).map { Pad(id: $0) }

        guard let documents = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            preconditionFailure("Documents directory unavailable")
        }
        samplesDirectory = documents.appendingPathComponent("samples", isDirectory: true)
        indexURL = documents.appendingPathComponent("pad_index.json")

        createSamplesDirectoryIfNeeded()
        load()
    }

    // MARK: - Public API

    /// Assigns a WAV file at `sourceURL` to the pad at `padIndex`.
    /// Copies the file into the app sandbox, updates the index.
    @discardableResult
    func assign(sampleAt sourceURL: URL, toPad padIndex: Int, metadata: SampleMetadata) throws -> URL {
        precondition((0...7).contains(padIndex))
        try checkStorageAvailability()

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
