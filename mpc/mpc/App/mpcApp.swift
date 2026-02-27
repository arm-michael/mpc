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

    /// `true` when the app process is a test host (an `.xctest` bundle is loaded).
    ///
    /// Evaluated once at the call site. XCTest / Swift Testing inject the test
    /// bundle before `UIApplicationMain` returns, so this check is reliable by
    /// the time SwiftUI evaluates `body` or fires `.task {}`.
    private static let isRunningInTestHost: Bool =
        Bundle.allBundles.contains { $0.bundlePath.hasSuffix(".xctest") }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model.audioEngine)
                .environment(model.sampleStore)
                .environment(model.playbackService)
                .task {
                    // Skip all startup I/O when running as a test host.  The
                    // sandbox-container daemon and CoreAudio daemon may be
                    // unavailable in headless CI simulators (CODE_SIGNING_ALLOWED=NO),
                    // which can crash the process before XCTest bootstraps.
                    guard !Self.isRunningInTestHost else { return }
                    Task.detached(priority: .userInitiated) {
                        model.sampleStore.loadPersisted()
                        try? AudioSessionManager.shared.configure(for: model.audioEngine)
                    }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, !Self.isRunningInTestHost {
                AudioSessionManager.shared.resume()
            }
        }
    }
}
