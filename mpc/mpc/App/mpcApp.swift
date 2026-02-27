import SwiftUI

/// Top-level container holding all app-scoped services for their lifetime.
///
/// All properties are `lazy` so that `AppModel.init()` is trivially fast.
/// Heavy initialisation (AVAudioEngine, FileManager sandbox access) is
/// deferred until SwiftUI first accesses each property when evaluating
/// `body`, which happens after the main run loop has started and XCTest
/// has had the chance to bootstrap in test environments.
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
                    // Run audio session setup off the main actor so the main run loop
                    // stays free for XCTest bootstrap in headless CI environments where
                    // the CoreAudio daemon is unavailable and setActive / start() block.
                    Task.detached(priority: .userInitiated) {
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
