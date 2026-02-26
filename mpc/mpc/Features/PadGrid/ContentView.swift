import SwiftUI

struct ContentView: View {
    var body: some View {
        PadGridView()
    }
}

#Preview {
    let engine = AudioEngine()
    ContentView()
        .environment(SampleStore())
        .environment(engine)
        .environment(PlaybackService(engine: engine))
}
