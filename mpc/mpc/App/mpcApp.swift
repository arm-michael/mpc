import SwiftUI

/// Top-level container holding all app-scoped services for their lifetime.
///
/// All properties are `lazy` so that `AppModel.init()` is trivially fast
/// and performs no file I/O or audio-daemon access on the main thread.
private final class AppModel {
    lazy var audioEngine = AudioEngine()
    lazy var sampleStore = SampleStore()
    lazy var playbackService: PlaybackService = PlaybackService(engine: audioEngine)
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
                    // Run all startup I/O off the main actor so the main run loop
                    // stays free for XCTest bootstrap. In headless CI simulators the
                    // sandbox-container daemon and CoreAudio daemon may be unavailable,
                    // causing their respective API calls to block for minutes.
                    Task.detached(priority: .userInitiated) {
                        model.sampleStore.loadPersisted()
                        try? AudioSessionManager.shared.configure(for: model.audioEngine)
                    }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                AudioSessionManager.shared.resume()
            }
        }
    }
}
