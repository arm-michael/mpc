import Foundation
import Testing
@testable import mpc

struct PadGridTests {

    @Test func test_padGridView_renders8Pads() {
        let store = SampleStore()
        #expect(store.pads.count == 8)
        #expect(store.pads.map(\.id) == Array(0..<8))
    }
}
