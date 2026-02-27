import Foundation
import Observation

/// Per-pad ephemeral UI state for flash animation and action sheet visibility.
@Observable
final class PadViewModel {

    let padIndex: Int
    var isFlashing = false
    var showActionSheet = false

    init(padIndex: Int) {
        self.padIndex = padIndex
    }

    /// Flashes the pad for 0.1 s on the main thread.
    func flash() {
        isFlashing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isFlashing = false
        }
    }
}
