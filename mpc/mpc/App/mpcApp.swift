import SwiftUI

/// Top-level container holding all app-scoped services for their lifetime.
private final class AppModel {
    let audioEngine = AudioEngine()
    let sampleStore = SampleStore()
    let playbackService: PlaybackService

    init() {
        playbackService = PlaybackService(engine: audioEngine)
    }
}

@main
struct MPCApp: App {

    @State private var model = AppModel()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model.audioEngine)
                .environment(model.sampleStore)
                .environment(model.playbackService)
                .task {
                    try? AudioSessionManager.shared.configure(for: model.audioEngine)
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                AudioSessionManager.shared.resume()
            }
        }
    }
}
