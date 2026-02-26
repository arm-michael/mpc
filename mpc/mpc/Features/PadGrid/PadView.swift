import SwiftUI

/// Renders a single MPC pad: empty state ("+") or loaded state (waveform).
///
/// Tap plays the loaded sample with a 0.1 s flash animation.
/// Holding for 5 s presents an action sheet to assign or remove a sample.
struct PadView: View {

    let padIndex: Int

    @Environment(SampleStore.self) private var store
    @Environment(PlaybackService.self) private var playback
    @State private var viewModel: PadViewModel

    private var pad: Pad { store.pads[padIndex] }

    init(padIndex: Int) {
        self.padIndex = padIndex
        _viewModel = State(wrappedValue: PadViewModel(padIndex: padIndex))
    }

    // MARK: - Body

    var body: some View {
        @Bindable var vm = viewModel
        padContent
            .opacity(vm.isFlashing ? 0.4 : 1.0)
            .animation(.easeOut(duration: 0.1), value: vm.isFlashing)
            .onTapGesture(perform: handleTap)
            .onLongPressGesture(minimumDuration: 5.0, perform: handleLongPress)
            .confirmationDialog(
                "Pad \(padIndex + 1)",
                isPresented: $vm.showActionSheet,
                titleVisibility: .visible
            ) {
                actionButtons
            }
            .accessibilityLabel("Pad \(padIndex + 1)")
            .accessibilityHint("Double-tap to play. Hold for 5 seconds to assign.")
    }

    // MARK: - Subviews

    @ViewBuilder
    private var padContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(pad.hasSample
                    ? Color.accentColor.opacity(0.3)
                    : Color.secondary.opacity(0.2))
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.5), lineWidth: 1)
            if let url = pad.sampleURL {
                WaveformThumbnailView(url: url)
                    .padding(8)
            } else {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private var actionButtons: some View {
        Button("Generate with Stable Audio") {
            // TODO(#26): wire to GenerationView
        }
        Button("Load from Files") {
            // TODO(#28): wire to DocumentPickerView
        }
        if pad.hasSample {
            Button("Remove Sample", role: .destructive) {
                try? store.removeSample(fromPad: padIndex)
                playback.unload(padIndex: padIndex)
            }
        }
    }

    // MARK: - Actions

    private func handleTap() {
        guard pad.hasSample else { return }
        playback.play(padIndex: padIndex)
        viewModel.flash()
    }

    private func handleLongPress() {
        viewModel.showActionSheet = true
    }
}
