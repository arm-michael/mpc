import SwiftUI

@main
struct MPCApp: App {

    @State private var audioEngine: AudioEngine
    @State private var sampleStore: SampleStore
    @State private var playbackService: PlaybackService

    @Environment(\.scenePhase) private var scenePhase

    init() {
        let engine = AudioEngine()
        _audioEngine = State(wrappedValue: engine)
        _sampleStore = State(wrappedValue: SampleStore())
        _playbackService = State(wrappedValue: PlaybackService(engine: engine))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(audioEngine)
                .environment(sampleStore)
                .environment(playbackService)
                .task {
                    try? AudioSessionManager.shared.configure(for: audioEngine)
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                AudioSessionManager.shared.resume()
            }
        }
    }
}
