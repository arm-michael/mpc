import SwiftUI

/// Displays all 8 pads in a 2-row × 4-column grid.
struct PadGridView: View {

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<8, id: \.self) { index in
                PadView(padIndex: index)
            }
        }
        .padding()
    }
}
