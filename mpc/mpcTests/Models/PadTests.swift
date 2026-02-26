import Testing
import Foundation
@testable import mpc

struct PadTests {

    // MARK: - Pad

    @Test func test_pad_init_validId() {
        let pad = Pad(id: 3)
        #expect(pad.id == 3)
        #expect(pad.sampleURL == nil)
        #expect(pad.metadata == nil)
        #expect(pad.hasSample == false)
    }

    @Test func test_pad_hasSample_trueWhenURLAssigned() {
        let url = URL(filePath: "/tmp/test.wav")
        let metadata = SampleMetadata(duration: 2.0, sampleRate: 44100, channelCount: 2)
        let pad = Pad(id: 0, sampleURL: url, metadata: metadata)
        #expect(pad.hasSample == true)
    }

    @Test func test_pad_codable_roundTrip() throws {
        let url = URL(filePath: "/tmp/0_abc.wav")
        let metadata = SampleMetadata(
            duration: 3.5,
            sampleRate: 44100,
            channelCount: 2,
            createdAt: Date(timeIntervalSince1970: 1_000_000),
            originalPrompt: "punchy kick",
            mode: .oneShot,
            projectId: nil
        )
        let original = Pad(id: 0, sampleURL: url, metadata: metadata)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Pad.self, from: data)

        #expect(decoded == original)
    }

    @Test func test_pad_nilOptionalFields_encodedAsNull() throws {
        let pad = Pad(id: 1)
        let encoder = JSONEncoder()
        let data = try encoder.encode(pad)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // sampleURL and metadata must be present as null, not missing
        #expect(json?["sampleURL"] is NSNull)
        #expect(json?["metadata"] is NSNull)
    }

    // MARK: - SampleMetadata

    @Test func test_sampleMetadata_defaultMode_isOneShot() {
        let meta = SampleMetadata(duration: 1.0, sampleRate: 44100, channelCount: 2)
        #expect(meta.mode == .oneShot)
    }

    @Test func test_sampleMetadata_codable_roundTrip() throws {
        let original = SampleMetadata(
            duration: 5.0,
            sampleRate: 44100,
            channelCount: 2,
            createdAt: Date(timeIntervalSince1970: 500_000),
            originalPrompt: "snare hit",
            mode: .oneShot,
            projectId: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SampleMetadata.self, from: data)

        #expect(decoded == original)
    }

    @Test func test_sampleMetadata_reservedProjectId_encodedAsNull() throws {
        let meta = SampleMetadata(duration: 1.0, sampleRate: 44100, channelCount: 2)
        let encoder = JSONEncoder()
        let data = try encoder.encode(meta)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["projectId"] is NSNull)
    }
}
