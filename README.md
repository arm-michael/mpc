# MPC

iOS native MPC-style sampler. 8 pads. Assign sounds by generating audio on-device via Stable Audio Open Small or loading local `.wav` files. Offline-first.

## Phase 1

- 8-pad grid (2 rows × 4 pads)
- Long-press (5s) to assign a sample: generate via AI or load from Files
- On-device text-to-audio generation via Stability AI's Stable Audio Open Small (up to ~11s stereo 44.1kHz)
- One-shot playback per tap (≤ 200ms latency)
- Offline — no network required

## Phase 2 (planned)

Hold/one-shot modes, recording, sequencing, MIDI out, sample trimming, ADSR, project save/load.

## Requirements

- iOS 17+
- iPhone with A14 chip or later (for on-device AI inference)
- Swift 5.9+ / Xcode 15+

## Setup

```bash
# Clone and open in Xcode
git clone <repo-url>
open MPC.xcodeproj
```

## License

See LICENSE. Note: Stable Audio Open Small is subject to Stability AI's model license — review before distribution.
