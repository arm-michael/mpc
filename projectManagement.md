# projectManagement.md — MPC iOS App Phase 1

> Generated: 2026-02-26
> Orchestrator: ACTIVATE
> Phase: DEFINE → PLAN → ENGINEER PLAN
> Team: PM · TPM · UI/UX · SWE

---

## ORCHESTRATOR SESSION STATE

```
ORCHESTRATOR SESSION STATE:
  Active Program: MPC iOS App — Phase 1
  Phase: Engineer Plan (pre-implementation)
  Sprint: 1 (starts 2026-02-26)

  PM:
    Mode: DEFINITION (complete)
    Active PRD: MPC iOS App Phase 1 — v1.0
    Pending Handoffs: Design: pending | Engineering: pending

  TPM:
    Mode: PLANNING (complete)
    Critical Path: 🟡 (E5 spike risk unresolved)
    Open Blockers: 2 (R1 license, R9 branch protection)
    Next Milestone: M1 — Infrastructure Complete (2026-03-13)

  UI/UX:
    Mode: DESIGN (pending handoff from PM)
    Active Feature: Pad Grid + Generation Flow + Import Flow
    Design Status: not started
    Accessibility: pending audit

  SWE:
    Mode: PLANNER (complete)
    Active Story: —
    Active Branch: —
    Last PR: —
    Tests: 0 (empty scaffold)
    DoR Met: no (pending design handoff + GitHub Issues creation)

  Shared:
    GitHub Repo: arm-michael/mpc
    Gate Status: Repo init ✅ | PRD ✅ | Program Plan ✅ | Engineering Plan ✅
                 Design Handoff: PENDING | Issues Created: PENDING
    Blockers: R1 (license), R9 (branch protection solo-merge)
```

---

# PART 1 — PRODUCT MANAGEMENT (PM)

## PRD: MPC iOS App — Phase 1

**Version:** 1.0 | **Status:** Approved | **Owner:** PM Agent
**Repo:** arm-michael/mpc | **Updated:** 2026-02-26

### TL;DR

Musicians and sound designers lack a fast, offline way to experiment with custom pad-mapped sounds on mobile. The MPC iOS App Phase 1 delivers an 8-pad sampler that lets users assign sounds two ways — generating audio on-device via Stable Audio Open Small (text prompt → WAV) or loading a local `.wav` file — then plays them back as one-shot triggers with sub-200ms latency. Phase 1 establishes the core loop (pad grid → long press → assign → tap to play) as the foundation for all future features.

### Background & Context

Consumer music production apps require cloud connectivity for AI audio generation, introducing latency, privacy concerns, and offline failure. The emergence of Stability AI's Stable Audio Open Small (~341M params, optimized for Arm CPUs) makes on-device text-to-audio generation practical on iPhone A14+. The existing codebase is a bare SwiftUI scaffold (Hello World only) — all product functionality is built from scratch.

### Goals (Measurable)

1. Users can assign a sample to any pad in < 30 seconds (prompt → generate → play)
2. Playback latency ≤ 200ms from tap on A14+ device
3. All 7 acceptance criteria from the product spec verified and closed
4. App runs fully offline — zero network calls during normal operation
5. Zero SEV-0 or SEV-1 bugs at launch gate

### Non-Goals (Phase 2 — explicitly out of scope)

- Hold/one-shot mode toggle
- Recording (microphone input)
- Sequencing / BPM / pattern playback
- Pad MIDI out
- Sample trimming and ADSR envelope controls
- Save/load named projects
- Audio export or sharing

### User Personas

**Primary — The Pocket Producer:** Creates beats on iPhone during commutes. Wants instant, tactile sample experimentation without a laptop or internet connection.

**Secondary — The Field Recordist:** Records ambient sounds in the field, imports them as `.wav` files, maps them to pads, and triggers them in live performance.

### User Stories (MoSCoW)

#### Must Have (P0 — blocks core loop)
- As a Pocket Producer, I want to see 8 pads in a 2×4 grid so I have a familiar MPC layout
- As a Pocket Producer, I want to long-press a pad for 5 seconds to assign a sound so the gesture is deliberate and avoids accidental triggers
- As a Field Recordist, I want to load a `.wav` file from my phone and assign it to a pad so I can use my own sounds
- As a Pocket Producer, I want to tap a pad and hear its sound immediately so I can jam in real time
- As a Pocket Producer, I want assigned pads to show a waveform thumbnail so I know which pads have sounds

#### Must Have (P1 — AI generation)
- As a Pocket Producer, I want to type a text prompt and generate a sound on-device so I can create original samples without the internet

#### Should Have (P2)
- As a user, I want clear progress feedback during generation so I know the app is working
- As a user, I want to cancel an in-progress generation so I can try a different prompt
- As a user, I want to replace a pad's sound using the same long-press flow so I can iterate quickly
- As a user, I want a confirmation when replacing an existing sample so I don't accidentally lose a sound I like

#### Could Have (P3)
- As a user, I want accessibility labels on all pads so VoiceOver users can use the app
- As a user, I want a low-storage warning so I know when my device is running out of space

---

### Functional Requirements

**FR-1: Pad Grid Display**
The app shall display 8 pads in a 2-row × 4-column grid on launch.
- AC: Given the app is launched, when the pad grid loads, then 8 pads are visible, empty pads show "+", pads with samples show a waveform thumbnail.

**FR-2: Long-Press Detection**
A long-press gesture of exactly 5.0 seconds shall open the sample assignment menu.
- AC: Given a pad exists, when the user holds it for ≥ 5.0s, then the menu appears. Given the user holds for < 5.0s, then no menu appears.

**FR-3: AI Generation Flow**
The user shall be able to generate a sample by typing a text prompt; the app runs Stable Audio Open Small on-device and assigns the WAV to the pad.
- AC: Given the user opens Generate, when they enter a prompt and tap Generate, then progress UI shows; when generation completes, the sample (≤ 11s, stereo 44.1kHz WAV) is assigned to the pad and plays within 200ms of tap. If model fails, a human-readable error is shown and retry is offered.

**FR-4: File Import Flow**
The user shall be able to import a `.wav` from the iOS Files app and assign it to a pad.
- AC: Given the user opens Load from Files, when they select a `.wav`, then the file is validated; if sample rate ≠ 44.1kHz it is resampled; if duration > 15s a truncation dialog is shown; valid file is assigned to pad.

**FR-5: One-Shot Playback**
Tapping a pad shall play its assigned sample once, with audible start within 200ms.
- AC: Given a pad has an assigned sample, when tapped, then sound is audible within 200ms with no sustain or loop.

**FR-6: Offline Operation**
All generation and import flows shall work with airplane mode enabled.
- AC: Given the device has no network, when the user generates or imports, then the flow completes successfully.

**FR-7: Pad Asset Persistence**
Assigned samples shall persist across app restarts.
- AC: Given pads have assigned samples, when the app is force-quit and relaunched, then all pads reload their samples with thumbnails.

---

### Non-Functional Requirements

| Concern | Requirement |
|---------|-------------|
| Performance | Playback latency ≤ 200ms (tap to audible) on A14+ |
| Performance | Generation time: measured and logged; target < 30s on A14 |
| Accessibility | VoiceOver labels on all pads and interactive controls |
| Offline | All features work in airplane mode |
| Storage | Samples stored in app sandbox (`Documents/samples/`); cleanup on low disk |
| Security | No network calls; no user credentials; model weights bundled or downloaded to sandbox |
| Compatibility | iOS 17+, A14 chip or later for generation; A12+ for import/playback |
| Legal | Stable Audio Open Small license reviewed; attribution implemented per license terms |

---

### UX Requirements (for UI/UX Agent)

Design required for these screens/states:

1. **Pad Grid** — default, all-empty; partially loaded; fully loaded; tap feedback
2. **Long-Press Affordance** — visual hint / progress ring during 5s hold
3. **Action Sheet** — "Generate with Stable Audio" / "Load from Files" / "Cancel" (+ "Replace" variant for occupied pads)
4. **Generate Modal** — text input field, placeholder text, Generate button, keyboard handling
5. **Generation Progress** — spinner, estimated time label, Cancel button
6. **Generation Error** — human-readable message, Retry / Dismiss
7. **File Picker** — system UIDocumentPicker (no custom design needed, but integration flow matters)
8. **Truncation Dialog** — "File is Xs long (max 15s). Truncate to 15s or Cancel?"
9. **Replacement Confirmation** — "Replace existing sample on Pad N? This will remove your current sound."
10. **Device Unsupported** — "Your device doesn't support on-device generation. You can still load files."
11. **Low Storage Warning** — banner/alert

---

### Rollout Plan

- Phase 1: Internal (solo dev) → TestFlight → App Store (public)
- No feature flags needed (entire Phase 1 is the product)
- No A/B testing in Phase 1
- Kill switch: disable AI generation via remote config flag (future) — leave hook in GenerationService

---

### Success Metrics

| Metric | Baseline | Target | Timeframe |
|--------|----------|--------|-----------|
| All 7 ACs passing | 0 | 7/7 | M6 |
| Playback latency | — | ≤ 200ms on A14 | M2 |
| Generation latency | — | ≤ 30s on A14 | M5 |
| Zero SEV-0/1 bugs | — | 0 open | M6 |
| CI green rate | — | 100% on merged PRs | ongoing |

---

### Failure Thresholds / Rollback

- If Stable Audio Open Small commercial license blocks distribution → cut AI generation from Phase 1 v1.0; ship import-only with Phase 1.1 re-introducing generation
- If generation time > 30s on A14 → scope minimum device to A16+, or ship without generation and treat as Phase 1.1
- If memory footprint causes OOM on 4GB devices → define A15+ minimum for generation; show "device not supported"

---

# PART 2 — GITHUB ISSUES HIERARCHY

> All issues to be created in arm-michael/mpc before Sprint 1 begins.
> Numbering is sequential — actual GitHub issue numbers assigned on creation.

## EPIC ISSUES

```
EPIC #1: E1 — Project Infrastructure & Dev Setup
Label: epic
Body: Establish folder structure, SwiftLint, CI hardening, and audio
      session bootstrap. Must complete before any other epic begins.

EPIC #2: E2 — Pad Grid UI
Label: epic
Body: 2x4 SwiftUI pad grid, waveform thumbnail, tap feedback,
      5-second long-press detection, action sheet routing, accessibility.

EPIC #3: E3 — Sample Management & Persistence
Label: epic
Body: Pad + Sample data models, JSON index in Documents/samples/,
      SampleStore lifecycle (add/replace/delete), storage cleanup.

EPIC #4: E4 — Audio Playback Engine
Label: epic
Body: AVAudioEngine + AVAudioPlayerNode, buffer preloading, one-shot
      playback (≤200ms), AVAudioConverter resampling, session management.

EPIC #5: E5 — On-Device AI Generation
Label: epic
Body: Stable Audio Open Small integration (LiteRT or Core ML), text
      prompt modal, progress + cancel UI, WAV output → pad assignment,
      device capability check, legal/license compliance.

EPIC #6: E6 — File Import
Label: epic
Body: UIDocumentPicker, WAV validation, AVAudioConverter resampling,
      >15s truncation dialog, invalid file error handling.

EPIC #7: E7 — Error Handling & UX Polish
Label: epic
Body: Low memory, thermal throttle, low storage, model failure,
      device unsupported, generation cancel, pad replacement confirmation.
```

## FEATURE STORIES (under epics)

### E1 — Infrastructure

```
FEATURE: Restructure Xcode project folder layout
Label: feat | Part of #1 (E1) | Priority: P0
User Story: As SWE, I want a consistent folder structure so that each
            feature area has a clear home and files are findable.
ACs:
  - Given the Xcode project, when opened, then folders exist:
    App/, Features/PadGrid/, Features/Generation/, Features/FileImport/,
    Core/Audio/, Core/Models/, Core/Errors/, Resources/
  - Given a new Swift file is added, when placed correctly, then SwiftLint
    does not flag a file-location violation
Files affected: mpc.xcodeproj/project.pbxproj, all Swift file paths

FEATURE: Add SwiftLint and enforce in CI
Label: feat | Part of #1 (E1) | Priority: P0
ACs:
  - Given a PR with a lint violation, when CI runs, then the lint job fails
  - Given a PR with no lint violations, when CI runs, then lint passes
Files affected: .swiftlint.yml, .github/workflows/ci.yml

FEATURE: Harden CI workflow (pin Xcode, add lint, artifact upload)
Label: feat | Part of #1 (E1) | Priority: P0
ACs:
  - Given a PR, when CI runs, then Xcode version is pinned (not 'latest')
  - Given tests run, when complete, then test results artifact is uploaded
Files affected: .github/workflows/ci.yml

FEATURE: Verify branch protection allows solo-dev merge after CI
Label: chore | Part of #1 (E1) | Priority: P0
ACs:
  - Given a PR with CI passing, when the repo owner clicks merge, then
    merge succeeds without requiring a second human approver
  - If not: update branch protection rules to require CI but 0 reviewers
Files affected: GitHub Settings (not code)
```

### E2 — Pad Grid UI

```
FEATURE: PadGridView — 2x4 grid with empty and loaded states
Label: feat | Part of #2 (E2) | Priority: P0
User Story: As a user, I want to see 8 pads so I have a familiar MPC layout.
ACs:
  - Given app launches, when pad grid renders, then 8 pads show in 2 rows x 4 cols
  - Given a pad has no sample, then it shows "+" label
  - Given a pad has a sample, then it shows a waveform thumbnail
  - Given any pad exists, then it has an accessibilityLabel ("Pad 1"..."Pad 8")
Files: Features/PadGrid/PadGridView.swift, Features/PadGrid/PadView.swift

FEATURE: Long-press gesture — 5.0s triggers action sheet
Label: feat | Part of #2 (E2) | Priority: P0
User Story: As a user, I want to long-press for 5s to assign a sound so
            the gesture is intentional and avoids accidents.
ACs:
  - Given a pad, when held for ≥ 5.0s, then action sheet appears with
    "Generate with Stable Audio" and "Load from Files"
  - Given a pad, when held for < 5.0s, then action sheet does not appear
  - Given a loaded pad, when held 5.0s, then action sheet includes
    "Replace" option with destructive confirmation
Files: Features/PadGrid/PadView.swift, Features/PadGrid/PadViewModel.swift

FEATURE: Tap feedback animation
Label: feat | Part of #2 (E2) | Priority: P1
ACs:
  - Given a pad with a sample, when tapped, then pad flashes briefly
  - Given an empty pad, when tapped, then no playback occurs and no flash
Files: Features/PadGrid/PadView.swift

FEATURE: Waveform thumbnail component
Label: feat | Part of #2 (E2) | Priority: P1
ACs:
  - Given a pad has an assigned WAV, when thumbnail renders, then a
    simplified waveform visualization of the audio is shown
  - Given the WAV is replaced, when thumbnail updates, then new waveform shown
Files: Features/PadGrid/WaveformThumbnailView.swift
```

### E3 — Sample Management & Persistence

```
FEATURE: Pad and Sample data models
Label: feat | Part of #3 (E3) | Priority: P0
ACs:
  - Given a Pad struct, it has: id (0-7), sampleURL (optional), metadata (optional)
  - Given a SampleMetadata struct, it has: duration, originalPrompt (optional),
    createdAt, sampleRate, channelCount
  - Given Codable conformance, when encoded and decoded, then all fields match
  - Given Phase-2 schema extensibility, Pad includes reserved fields: mode
    (default "oneShot"), projectId (nil), adsrEnvelope (nil)
Files: Core/Models/Pad.swift, Core/Models/SampleMetadata.swift

FEATURE: SampleStore — JSON index read/write/delete
Label: feat | Part of #3 (E3) | Priority: P0
ACs:
  - Given app launch, when SampleStore initializes, then it reads
    Documents/pad_index.json and restores all pad assignments
  - Given a sample is assigned to a pad, when saved, then
    Documents/samples/{padID}_{uuid}.wav exists and pad_index.json updated
  - Given a sample is replaced, when old sample deleted, then the .wav
    file is removed from Documents/samples/
  - Given a round-trip encode/decode, when JSON is read back, then all
    pad assignments and metadata are identical
Files: Core/Models/SampleStore.swift, Core/Models/PadStore.swift

FEATURE: Storage cleanup policy
Label: feat | Part of #3 (E3) | Priority: P2
ACs:
  - Given orphaned .wav files in Documents/samples/ (not in index),
    when cleanup runs, then orphaned files are deleted
  - Given available disk < 100MB, when generation or import is attempted,
    then low-storage warning is shown
Files: Core/Models/SampleStore.swift, Core/Errors/StorageError.swift
```

### E4 — Audio Playback Engine

```
FEATURE: AudioEngine service — init and audio session
Label: feat | Part of #4 (E4) | Priority: P0
ACs:
  - Given app launch, when AudioEngine initializes, then AVAudioEngine is
    running and audio session is active (.playback category, .mixWithOthers)
  - Given a phone call interrupts, when interruption ends, then engine
    resumes without crash
  - Given app goes to background, when backgrounded, then engine suspends;
    when foregrounded, engine restarts
Files: Core/Audio/AudioEngine.swift, Core/Audio/AudioSessionManager.swift

FEATURE: Buffer preloading from Documents/
Label: feat | Part of #4 (E4) | Priority: P0
ACs:
  - Given a pad has an assigned WAV, when app launches or sample is assigned,
    then WAV is decoded into AVAudioPCMBuffer and held in memory
  - Given 8 pads are all loaded, then total buffer memory is within
    a defined cap (max 8 × 11s × 44100 × 2ch × 4 bytes ≈ ~31MB)
Files: Core/Audio/AudioEngine.swift, Core/Audio/PlaybackService.swift

FEATURE: One-shot playback with ≤200ms latency
Label: feat | Part of #4 (E4) | Priority: P0
ACs:
  - Given a pad is tapped, when played, then audio is audible within 200ms
  - Given two pads are tapped in quick succession, both play independently
  - Given no sample assigned, when pad tapped, then no audio plays
Files: Core/Audio/PlaybackService.swift

FEATURE: AVAudioConverter resampling
Label: feat | Part of #4 (E4) | Priority: P0
ACs:
  - Given a WAV at 48kHz, when loaded, then it is converted to 44.1kHz
  - Given a mono WAV, when loaded, then it is normalized to stereo
  - Given conversion completes, when played, then audio is correct pitch/speed
Files: Core/Audio/AudioConverter.swift
```

### E5 — On-Device AI Generation

```
FEATURE: Model spike — load Stable Audio on physical device
Label: feat | Part of #5 (E5) | Priority: P0 (SPIKE)
ACs:
  - Given a physical A14+ iPhone, when Stable Audio Open Small is loaded,
    then generation completes and returns a ≤11s WAV
  - Spike report includes: generation time (seconds), peak RSS (MB),
    CPU % during inference, chosen runtime (LiteRT or Core ML), device model
  - Spike includes written rationale for integration approach
Files: Spike branch only (not merged to main)

FEATURE: License review for Stable Audio Open Small
Label: chore | Part of #5 (E5) | Priority: P0 (BLOCKER)
ACs:
  - Given Stability AI's model license, when reviewed, then commercial use
    status is documented (permitted / restricted / requires attribution)
  - Given license outcome, when documented, then attribution or disclaimer
    is added to app if required
Files: docs/legal/stable-audio-license.md (new)

FEATURE: GenerationService — text prompt → WAV
Label: feat | Part of #5 (E5) | Priority: P1
ACs:
  - Given a text prompt string, when GenerationService.generate() is called,
    then it runs inference on-device and returns a URL to the output WAV
  - Given generation is running, when cancel() is called, then inference
    stops and no WAV is written
  - Given model fails (OOM, thermal), when error occurs, then
    GenerationError is thrown with a human-readable message
Files: Features/Generation/GenerationService.swift

FEATURE: Text prompt modal and progress UI
Label: feat | Part of #5 (E5) | Priority: P1
ACs:
  - Given "Generate with Stable Audio" is tapped, when modal opens, then
    text field with placeholder "Describe the sound..." is shown
  - Given "Generate" is tapped, when inference runs, then progress spinner
    and estimated time are shown with a "Cancel" button
  - Given cancel is tapped, when inference is running, then it stops and
    modal dismisses
Files: Features/Generation/GenerationView.swift,
       Features/Generation/GenerationProgressView.swift

FEATURE: Device capability check
Label: feat | Part of #5 (E5) | Priority: P1
ACs:
  - Given a device below the minimum threshold, when app launches or
    Generate is tapped, then "device not supported" message is shown
  - Given an A14+ device, when Generate is tapped, then generation proceeds
Files: Core/Models/DeviceCapabilityChecker.swift
```

### E6 — File Import

```
FEATURE: UIDocumentPicker integration
Label: feat | Part of #6 (E6) | Priority: P0
ACs:
  - Given "Load from Files" is tapped, when picker opens, then only
    audio/* and .wav files are shown
  - Given a .wav is selected, when import completes, then it is
    copied to Documents/samples/ and assigned to the pad
Files: Features/FileImport/DocumentPickerView.swift (UIViewControllerRepresentable)

FEATURE: WAV validation and resampling
Label: feat | Part of #6 (E6) | Priority: P0
ACs:
  - Given a WAV with sample rate ≠ 44.1kHz, when imported, then
    AVAudioConverter resamples to 44.1kHz before saving
  - Given a mono WAV, when imported, then normalized to stereo
  - Given a non-WAV file (wrong extension/MIME), when selected,
    then ImportError.invalidFormat is shown
Files: Features/FileImport/FileValidationService.swift,
       Core/Audio/AudioConverter.swift

FEATURE: >15s truncation dialog
Label: feat | Part of #6 (E6) | Priority: P0
ACs:
  - Given an imported WAV longer than 15s, when validated, then
    a dialog "File is Xs — maximum is 15s. Truncate to 15s or Cancel?" is shown
  - Given user taps Truncate, then file is trimmed and assigned
  - Given user taps Cancel, then file is rejected and pad unchanged
Files: Features/FileImport/FileValidationService.swift,
       Features/FileImport/TruncationAlertView.swift
```

### E7 — Error Handling & UX Polish

```
FEATURE: Generation error states (model failure, OOM, thermal)
Label: feat | Part of #7 (E7) | Priority: P1
ACs:
  - Given model fails to load, when error occurs, then "Generation failed.
    Your device may not have enough memory. Please try again." is shown
  - Given thermal state is .serious or .critical, when Generate is tapped,
    then "Device is too hot for generation. Let it cool and try again." is shown
  - Given error is shown, when Retry is tapped, then generation re-attempts
Files: Features/Generation/GenerationView.swift, Core/Errors/GenerationError.swift

FEATURE: Device unsupported fallback
Label: feat | Part of #7 (E7) | Priority: P1
ACs:
  - Given an unsupported device (below minimum chip), when the pad grid loads,
    then a banner "On-device generation requires iPhone X or later" is shown
  - Given unsupported device, when Generate is tapped, then action sheet
    only shows "Load from Files" (Generate is hidden or disabled)
Files: Core/Models/DeviceCapabilityChecker.swift,
       Features/PadGrid/PadViewModel.swift

FEATURE: Low memory and low storage warnings
Label: feat | Part of #7 (E7) | Priority: P2
ACs:
  - Given available storage < 100MB, when generation or import is triggered,
    then "Low storage. Free up space before adding more samples." is shown
  - Given system memory pressure notification, when generation is running,
    then generation aborts with "Not enough memory. Try closing other apps."
Files: Core/Errors/StorageError.swift, Features/Generation/GenerationService.swift

FEATURE: Pad replacement confirmation
Label: feat | Part of #7 (E7) | Priority: P1
ACs:
  - Given a loaded pad is long-pressed, when the user selects Generate or Load,
    then a confirmation "Replace existing sample?" is shown before proceeding
  - Given user confirms, then new sample replaces old; old .wav deleted
  - Given user cancels, then pad unchanged
Files: Features/PadGrid/PadViewModel.swift
```

---

# PART 3 — PROGRAM MANAGEMENT (TPM)

## Program Charter

**Objective:** Deliver a production-grade offline-first iOS 8-pad MPC app (Phase 1) enabling a solo developer to assign sounds to pads via on-device AI text-to-audio (Stable Audio Open Small) or local WAV import, with one-shot playback and sub-200ms latency — no network required.

**Success Criteria:** All 7 prompt.md ACs verified; CI green; ≤200ms playback latency confirmed on A14; license reviewed; zero SEV-0/1 bugs at launch.

---

## Milestones

| ID | Milestone | Sprint | Target | Definition |
|----|-----------|--------|--------|------------|
| M1 | Infrastructure Complete | 1 | 2026-03-13 | Folder structure, SwiftLint, CI lint+Xcode pin, all GitHub Issues created, branch protection verified |
| M2 | UI + Persistence + Playback | 2 | 2026-03-27 | PadGridView, 5s long-press, tap plays WAV within 200ms on simulator, JSON index round-trips |
| M3 | Model Spike Go/No-Go | 2 | 2026-03-27 | Stable Audio loaded on physical A14; gen time/mem measured; LiteRT vs Core ML decided; license documented |
| M4 | File Import + Import Errors | 3 | 2026-04-10 | UIDocumentPicker, resampling, truncation dialog, all import error states working |
| M5 | AI Generation End-to-End | 4 | 2026-04-24 | Generate→assign→play on physical A14; cancellation; device check; all generation errors |
| M6 | QA, Polish, Launch Gate | 5 | 2026-05-08 | All ACs verified; CI green; perf logs attached; Go/No-Go signed off; legal attribution in-app |

---

## Sprint Plans

### Sprint 1 (2026-02-26 → 2026-03-13) — "Build the Floor"

**Goal:** Establish CI, folder structure, data model, and populate the full backlog.

**Committed:**
- E1: Folder restructure, SwiftLint, CI hardening, branch protection verify
- E3: Pad + Sample models, SampleStore (JSON index), unit tests

**Stretch:** PadGridView skeleton (static, no gesture)

**Risks this sprint:** R9 (branch protection), R13 (SwiftLint config), R14 (Xcode pin)

---

### Sprint 2 (2026-03-16 → 2026-03-27) — "Core Loop + Model Spike"

**Goal:** Ship pad grid, playback, and decide the AI integration approach.

**Committed:**
- E2: PadGridView, long-press, tap animation, accessibility labels
- E4: AudioEngine, buffer preload, one-shot playback (≤200ms), interruption handling
- E5 SPIKE: Load model on A14+, measure perf, decide LiteRT vs Core ML
- E5 LICENSE: Review Stability AI terms

**Stretch:** WaveformThumbnailView, long-press progress ring affordance

**Risks this sprint:** R1 (license gate), R2 (conversion), R3 (inference time), R4 (memory), R8 (throughput)

---

### Sprint 3 (2026-03-30 → 2026-04-10) — "File Import + Model Integration Begins"

**Goal:** Complete file import and open the AI integration branch.

**Committed:**
- E6: UIDocumentPicker, WAV validation, resampling, truncation dialog
- E5 (partial): GenerationService scaffold, prompt modal, progress UI
- E7 (partial): Import-side errors

**Gate:** M3 must be closed before E5 full integration begins

---

### Sprint 4 (2026-04-13 → 2026-04-24) — "AI Generation Complete"

**Goal:** Generate → assign → play working on physical device.

**Committed:**
- E5 (complete): Full generation pipeline, device check, WAV output → pad
- E7 (complete): All error states (model failure, OOM, thermal, cancellation, replacement confirm)

---

### Sprint 5 (2026-04-27 → 2026-05-08) — "QA + Launch Gate"

**Goal:** CI green, all ACs verified, Go/No-Go signed off.

**Committed:**
- Accessibility polish (VoiceOver labels, action sheet labels)
- Performance regression run (playback latency + generation time benchmarks)
- Legal attribution in-app
- Release notes
- Go/No-Go checklist

---

## Dependency Map

```
E1 → E2, E3, E4, E5, E6, E7    (infrastructure gate — CI must be green)
E3 → E2                          (PadGridView binds to Pad model)
E3 → E4                          (AudioEngine reads WAV paths from SampleStore)
E3 → E5, E6                      (generation + import write through SampleStore)
E4 → E6                          (import assigns WAV → AudioEngine preloads)
E4 → E5                          (generation assigns WAV → AudioEngine preloads)
E5-Spike → E5-Full               (approach must be decided before full integration)
E5-Full → E7 (generation errors) (error paths require functional E5)
E6 → E7 (import errors)          (error paths require functional E6)
E4 → E7 (audio session errors)   (interruption errors require functional E4)
E2 → E7 (replacement confirm)    (replacement dialog requires functional long-press)
```

---

## Risk Register

| ID | Risk | Prob | Impact | Score | Mitigation | Owner | Status |
|----|------|------|--------|-------|------------|-------|--------|
| R1 | Stable Audio Open Small commercial license blocks App Store distribution | H | H | 9 | Sprint 2 license review is a hard M3 gate. If blocked: cut generation from v1.0, ship import-only, add generation in v1.1 | TPM | OPEN 🔴 |
| R2 | Model conversion to LiteRT or Core ML fails or produces incorrect output | M | H | 6 | Timebox spike to 5 days. Evaluate both paths. Fallback: mock GenerationService returning static WAV unblocks UI while fix continues | SWE | OPEN 🔴 |
| R3 | On-device inference time > 30s on A14 — unacceptable UX | M | H | 6 | Measure in spike. If >30s: scope to A16+, quantized model variant, or cut generation from Phase 1 | SWE | OPEN 🔴 |
| R4 | ~341M param model causes OOM on 4GB RAM devices | M | H | 6 | Measure peak RSS in spike. If >1.5GB: set minimum device (A15+) and disable generation on incompatible hardware | SWE | OPEN 🔴 |
| R8 | Solo developer throughput: any blocker has outsized schedule impact | H | M | 6 | Front-load E5 spike to Sprint 2. Maintain prioritized backlog. Agent team pre-drafts specs and boilerplate. TPM flags >80% sprint load | TPM | OPEN 🔴 |
| R9 | Branch protection requires 1 human reviewer → blocks solo-dev self-merge | H | M | 6 | Sprint 1: reconfigure branch protection to require CI status checks but 0 human approvers | SWE | OPEN 🔴 |
| R5 | Thermal throttling during generation causes abort or inconsistent perf | M | M | 4 | Detect ProcessInfo.thermalState; disable generation on .serious/.critical | SWE | OPEN 🟡 |
| R6 | WAV edge cases (8kHz mono, corrupt headers, non-PCM) crash import pipeline | M | M | 4 | Build edge-case WAV test suite; wrap AVAudioConverter in defensive error handling | SWE | OPEN 🟡 |
| R7 | Phase 2 data model incompatibility with Phase 1 JSON schema | L | H | 3 | Reserve extensible fields in schema now: mode, projectId, adsrEnvelope (null) | SWE | OPEN 🟡 |
| R11 | Generated audio may embed copyrighted training data | L | H | 3 | First-launch disclaimer; no export/sharing in Phase 1; legal review at M6 | TPM | OPEN 🟡 |
| R10 | AVAudioSession conflicts with phone calls or Music app | L | M | 2 | Implement interruption handling; configure .mixWithOthers | SWE | OPEN 🟢 |
| R12 | Low device storage causes Documents/ write to fail mid-generation | L | M | 2 | Check FileManager.volumeAvailableCapacity before generation; show warning if <100MB | SWE | OPEN 🟢 |
| R13 | SwiftLint misconfiguration blocks CI unexpectedly | L | L | 1 | Start with relaxed ruleset; run lint locally before push | SWE | OPEN 🟢 |
| R14 | Xcode version mismatch between local dev and CI runner | L | M | 2 | Pin Xcode version in CI (Sprint 1) | SWE | OPEN 🟢 |

**Summary:** 6 RED · 4 YELLOW · 4 GREEN

---

## Go/No-Go Checklist (M6)

```
Product Readiness:
  - [ ] All 7 prompt.md acceptance criteria closed as GitHub Issues
  - [ ] Long-press 5.0s verified on physical A14+ device
  - [ ] Generate → assign → play end-to-end on physical device
  - [ ] Load → assign → play end-to-end on physical device
  - [ ] Waveform thumbnail renders for all assigned pads
  - [ ] Release notes drafted

Engineering Readiness:
  - [ ] CI green on release candidate (build + unit + integration tests)
  - [ ] Zero SEV-0 or SEV-1 open bugs
  - [ ] Playback latency ≤200ms verified on A14 (benchmark log attached)
  - [ ] Generation time benchmark logged for A14 and A15
  - [ ] Peak memory during generation within safe threshold (log attached)
  - [ ] Audio session interruption tested (phone call scenario)
  - [ ] Low storage warning fires when <100MB available

Design & Accessibility:
  - [ ] VoiceOver labels on all pads ("Pad 1" through "Pad 8")
  - [ ] Action sheet items labelled correctly for VoiceOver
  - [ ] Tap feedback animation present on all loaded pads
  - [ ] Device unsupported fallback shown on non-A14 hardware

Legal & Compliance:
  - [ ] Stability AI license reviewed and documented
  - [ ] Attribution implemented in-app if required by license
  - [ ] First-launch disclaimer shown if required
  - [ ] Generated audio export disabled (Phase 1)
```

---

# PART 4 — ENGINEERING PLAN (SWE)

## Architecture Decision Records

### ADR-001: Audio Engine Ownership

**Status:** Proposed | **Date:** 2026-02-26

**Context:** AVAudioEngine requires careful lifecycle management. Should it be a singleton or owned by a view model?

**Decision:** `AudioEngine` is a class owned by a top-level `@StateObject` (`AudioEngineViewModel` or `AppEnvironment`) injected via `.environmentObject`. Singleton is avoided — testability requires injection.

**Alternatives:**
| Alternative | Pros | Cons | Why Not |
|------------|------|------|---------|
| Global singleton | Simple access | Untestable, no lifecycle control | Untestable |
| Per-pad engine | Total isolation | 8 engines = too much overhead | Memory wasteful |
| Owned by App / Environment | Lifecycle controlled, injectable | Slightly more setup | ✅ Chosen |

---

### ADR-002: Pad State Management

**Status:** Proposed | **Date:** 2026-02-26

**Context:** SwiftUI state: `@Observable` macro (iOS 17+) vs `ObservableObject` + `@Published`.

**Decision:** Use `@Observable` macro (iOS 17+) for `PadStore`. iOS 17 is the minimum target — `@Observable` is available and eliminates boilerplate. Wrap in `@State` at the top-level view.

**Alternatives:**
| Alternative | Pros | Cons | Why Not |
|------------|------|------|---------|
| ObservableObject + @Published | Widely documented | Verbose, forces @StateObject | Unnecessary on iOS 17+ |
| @Observable (iOS 17+) | Clean, modern, less boilerplate | Requires iOS 17+ | ✅ Chosen |
| Redux/TCA | Predictable | Massive overhead for this app size | Over-engineered |

---

### ADR-003: Stable Audio Runtime — LiteRT vs Core ML

**Status:** Proposed — REQUIRES SPIKE TO FINALIZE | **Date:** 2026-02-26

**Context:** Stable Audio Open Small can run via Arm/LiteRT (on-device Arm runtime) or Core ML (Apple's native inference framework). Both have been discussed as valid paths by Stability AI and Arm.

**Decision (provisional — confirm in Sprint 2 spike):**
- **Primary path:** Attempt Core ML conversion using `coremltools` + `ct.convert()` from the model's PyTorch checkpoint. Core ML is native to iOS, avoids third-party frameworks, and integrates directly with AVAudioEngine output buffers.
- **Fallback path:** LiteRT (formerly TFLite) via the `TensorFlowLiteSwift` SPM package if Core ML conversion fails or produces incorrect output.

**Spike must answer:**
1. Does Core ML conversion succeed with correct audio output?
2. What is Core ML inference time vs LiteRT on A14?
3. What is peak memory for both paths on 4GB RAM?
4. Does LiteRT require adding a ~20MB SPM dependency?

**This ADR must be finalized by end of Sprint 2 (M3 gate).**

---

### ADR-004: Model Bundling Strategy

**Status:** Proposed | **Date:** 2026-02-26

**Context:** The Stable Audio Open Small model is ~341M parameters. As a Core ML `.mlpackage` or `.tflite` file it will be in the range of 700MB–1.4GB (float32) or ~350–700MB (int8 quantized). App Store upload limit is 4GB but OTA download limit is 200MB.

**Decision:** On-demand download on first launch. Bundle a small placeholder. On first-launch over WiFi, download the model to `Library/Application Support/model/`. Show a one-time "Downloading generation model (~XXX MB)" progress screen. Cache permanently — never re-download unless user resets.

**Alternatives:**
| Alternative | Pros | Cons | Why Not |
|------------|------|------|---------|
| Bundle in IPA | Always available | Exceeds OTA download limit (200MB) | Fails OTA install |
| On-demand download | Passes OTA limit | First-launch friction | ✅ Chosen |
| App Store On-Demand Resource | Apple-hosted, clean | Complex setup for one file | Overkill |

---

### ADR-005: Audio Buffer Strategy

**Status:** Proposed | **Date:** 2026-02-26

**Context:** 8 pads × 11s × 44100Hz × 2ch × 4 bytes = ~31MB max if all pads loaded with max-length stereo samples. Is this worth preloading?

**Decision:** Preload all assigned buffers into `AVAudioPCMBuffer` on app launch and on each sample assignment. 31MB is acceptable on modern iPhones. Apply a soft cap: if total buffer memory exceeds 50MB, load remaining pads lazily (decode on first tap, with a brief warm-up delay). For Phase 1 with ≤11s samples, all-preload should fit within the soft cap.

**Alternatives:**
| Alternative | Pros | Cons | Why Not |
|------------|------|------|---------|
| Preload all (up to cap) | ≤200ms guaranteed | Up to 31MB memory | ✅ Chosen for Phase 1 |
| Lazy load (decode on tap) | Lower memory | First-tap latency spike | Violates 200ms AC |
| Stream from disk | Minimal memory | Complex + higher latency | Not needed at this scale |

---

## Engineering Epic Breakdown

### E1 — Project Infrastructure

**Stories:**

**S1.1 — Restructure Xcode project folders (P0)**
- T1.1.1: Create folder groups in Xcode: App/, Features/PadGrid/, Features/Generation/, Features/FileImport/, Core/Audio/, Core/Models/, Core/Errors/, Resources/
- T1.1.2: Move mpcApp.swift → App/; ContentView.swift → Features/PadGrid/ (temporary)
- T1.1.3: Update project.pbxproj with new paths
- T1.1.4: Verify build passes after restructure

**S1.2 — SwiftLint config and CI integration (P0)**
- T1.2.1: Create .swiftlint.yml with agreed rules (disabled: force_cast, type_body_length; enabled: trailing_whitespace, unused_import, let_var_whitespace)
- T1.2.2: Add `swiftlint` run script build phase to Xcode target
- T1.2.3: Add lint step to `.github/workflows/ci.yml` before build
- T1.2.4: Run lint locally and fix all violations

**S1.3 — CI hardening (P0)**
- T1.3.1: Pin Xcode version in CI (`sudo xcode-select -s /Applications/Xcode_16.2.app`)
- T1.3.2: Add test result artifact upload step
- T1.3.3: Add a `Makefile` with `make lint`, `make build`, `make test` targets

**S1.4 — Branch protection solo-dev verification (P0)**
- T1.4.1: Open a test feature branch, create a PR, confirm CI runs
- T1.4.2: Confirm repo owner can merge without a human reviewer after CI passes
- T1.4.3: If blocked: adjust branch protection rules (require CI checks, 0 required reviewers)

---

### E2 — Pad Grid UI

**Stories:**

**S2.1 — PadGridView 2×4 grid (P0)**
- T2.1.1: Create `PadGridView.swift` with LazyVGrid(columns: 4) rendering 8 PadView cells
- T2.1.2: Create `PadView.swift` with two states: `.empty` (shows "+") and `.loaded(WaveformThumbnailView)`
- T2.1.3: Replace ContentView.swift with PadGridView as root view in mpcApp.swift
- T2.1.4: Add accessibilityLabel("Pad \(index + 1)") to each pad
- T2.1.5: Unit test: PadGridView renders exactly 8 pads

**S2.2 — Long-press 5s gesture and action sheet (P0)**
- T2.2.1: Add `LongPressGesture(minimumDuration: 5.0)` to PadView
- T2.2.2: On gesture completion, present `confirmationDialog` with "Generate with Stable Audio" and "Load from Files"
- T2.2.3: If pad has existing sample, add "Replace" action with destructive style and confirmation
- T2.2.4: Unit test: gesture fires at 5.0s; does NOT fire at 4.9s
- Subtask: Test that gesture cancels cleanly if finger is lifted early

**S2.3 — Tap feedback animation (P1)**
- T2.3.1: On tap, animate pad background with a brief flash (opacity 0.5 → 1.0, duration 0.1s)
- T2.3.2: Ensure tap gesture and long-press gesture coexist without conflicts

**S2.4 — Waveform thumbnail component (P1)**
- T2.4.1: Create `WaveformThumbnailView.swift` that takes a `URL` and renders a simplified waveform
- T2.4.2: Downsample PCM buffer to 100 amplitude points; render as Path/Shape
- T2.4.3: Animate thumbnail update when sample changes

---

### E3 — Sample Management & Persistence

**Stories:**

**S3.1 — Pad and Sample data models (P0)**
- T3.1.1: Define `Pad: Codable, Identifiable` struct with id, sampleURL (URL?), metadata (SampleMetadata?)
- T3.1.2: Define `SampleMetadata: Codable` struct with duration, originalPrompt, createdAt, sampleRate, channelCount, plus reserved optional fields: mode (String? = "oneShot"), projectId (String? = nil), adsrEnvelope (AdsrEnvelope? = nil)
- T3.1.3: Unit test: Codable round-trip encode/decode for both types
- T3.1.4: Unit test: nil optional fields encode as null, not missing key

**S3.2 — SampleStore persistence (P0)**
- T3.2.1: Implement `SampleStore: @Observable` class managing array of 8 Pads
- T3.2.2: Implement `load()` — reads `Documents/pad_index.json` on init
- T3.2.3: Implement `save()` — writes `Documents/pad_index.json` after every mutation
- T3.2.4: Implement `assign(sample:toPad:)` — copies WAV to `Documents/samples/{padID}_{uuid}.wav`, updates index
- T3.2.5: Implement `remove(pad:)` — deletes WAV, updates index
- T3.2.6: Unit test: assign → save → reload → verify pad has sample URL
- T3.2.7: Unit test: remove → reload → verify pad has no sample
- T3.2.8: Integration test: write index file, kill store, re-init, confirm restoration

**S3.3 — Storage cleanup (P2)**
- T3.3.1: Implement `cleanupOrphans()` — list `Documents/samples/*.wav`, cross-reference against index, delete unreferenced files
- T3.3.2: Call cleanup on app launch after index load
- T3.3.3: Implement `availableStorageCheck() -> Bool` — returns false if <100MB free

---

### E4 — Audio Playback Engine

**Stories:**

**S4.1 — AudioEngine initialization and session management (P0)**
- T4.1.1: Create `AudioEngine: @Observable` class wrapping AVAudioEngine
- T4.1.2: Create `AudioSessionManager` configuring `.playback` category with `.mixWithOthers`
- T4.1.3: Handle `AVAudioSession.interruptionNotification`: stop on began, restart on ended
- T4.1.4: Handle `UIApplication.didEnterBackgroundNotification`: pause engine; `didBecomeActiveNotification`: restart
- T4.1.5: Unit test: session category is correctly set on initialization

**S4.2 — Buffer preloading (P0)**
- T4.2.1: Create `PlaybackService` that maintains a dict of `[PadID: AVAudioPCMBuffer]`
- T4.2.2: On `assign(sample:)`, read WAV via `AVAudioFile`, convert to engine's processing format, store buffer
- T4.2.3: Implement buffer memory cap: if total > 50MB, log warning (Phase 1: all should fit easily)
- T4.2.4: Unit test: buffer count matches number of assigned pads

**S4.3 — One-shot playback (P0)**
- T4.3.1: Create `play(padID:)` method — calls `AVAudioPlayerNode.scheduleBuffer(:completionHandler:)` with `.interrupts` option
- T4.3.2: Tap gesture on PadView calls `audioEngine.play(padID:)`
- T4.3.3: Performance test: measure time from `play()` call to `AVAudioPlayerNode` start (target ≤ 200ms)
- T4.3.4: Manual test: tap two pads rapidly — both play independently

**S4.4 — AVAudioConverter resampling (P0)**
- T4.4.1: Create `AudioConverter` utility that converts `AVAudioFile` to target format (44.1kHz, stereo, float32)
- T4.4.2: Wire `AudioConverter` into `PlaybackService.assign(sample:)`
- T4.4.3: Unit test: 48kHz input → 44.1kHz output with correct frame count ratio
- T4.4.4: Unit test: mono input → stereo output with identical L/R channels

---

### E5 — On-Device AI Generation

**Stories:**

**S5.0 — Model spike (P0 — Sprint 2, timebox 5 days)**
- T5.0.1: Download Stable Audio Open Small weights from Hugging Face
- T5.0.2: Attempt Core ML conversion using `coremltools`; document result
- T5.0.3: Attempt LiteRT path using Arm tooling; document result
- T5.0.4: Run working conversion on physical A14+ iPhone
- T5.0.5: Log generation time (seconds), peak RSS (MB), CPU%, device model
- T5.0.6: Review Stability AI model license; document commercial use terms
- T5.0.7: Write spike report (update ADR-003 with final decision)
- Subtask: If both conversion paths fail, report immediately to escalate scope decision

**S5.1 — GenerationService (P1 — Sprint 3/4, after spike)**
- T5.1.1: Create `GenerationService: @Observable` class
- T5.1.2: Implement `generate(prompt: String) async throws -> URL` — loads model, runs inference, returns WAV URL
- T5.1.3: Implement cancellation via `Task` + cooperative cancellation check
- T5.1.4: Implement `GenerationError` enum: `.modelLoadFailed`, `.inferenceError(String)`, `.resourceInsufficient`, `.cancelled`, `.thermalThrottle`
- T5.1.5: Unit test: cancelled task returns `.cancelled` error
- T5.1.6: Unit test: invalid model path throws `.modelLoadFailed`

**S5.2 — Prompt modal and progress UI (P1)**
- T5.2.1: Create `GenerationView.swift` — modal with TextField (placeholder: "Describe the sound…"), Generate button
- T5.2.2: Create `GenerationProgressView.swift` — spinner, "Generating… (may take a few seconds)", Cancel button
- T5.2.3: Wire cancel button to `GenerationService.cancel()`
- T5.2.4: On completion: dismiss modal, call `SampleStore.assign(sample:toPad:)`, update thumbnail
- T5.2.5: Integration test: prompt entered → progress shown → WAV returned → pad updated

**S5.3 — Device capability check (P1)**
- T5.3.1: Create `DeviceCapabilityChecker` — inspect chip generation via `sysctlbyname("hw.machine")`
- T5.3.2: Define minimum device constant (e.g., A14 = iPhone 12 family)
- T5.3.3: In `PadViewModel`: if device unsupported, hide "Generate" from action sheet; show info banner

---

### E6 — File Import

**Stories:**

**S6.1 — UIDocumentPicker integration (P0)**
- T6.1.1: Create `DocumentPickerView.swift` as `UIViewControllerRepresentable` wrapping `UIDocumentPickerViewController`
- T6.1.2: Configure content types: `[.wav, .audio]`
- T6.1.3: On selection, pass URL to `FileValidationService`
- T6.1.4: Coordinator handles `didPickDocumentsAt` and `cancel`

**S6.2 — WAV validation and resampling (P0)**
- T6.2.1: Create `FileValidationService` — accepts URL, returns `ValidatedAudioFile` or throws `ImportError`
- T6.2.2: Check: file extension is `.wav`; use `AVAudioFile` to read format; validate sampleRate, channelCount, duration
- T6.2.3: Resample via `AudioConverter` if sampleRate ≠ 44.1kHz or mono
- T6.2.4: Define `ImportError`: `.invalidFormat`, `.fileTooLong(Duration)`, `.corruptFile`, `.unsupportedEncoding`
- T6.2.5: Unit test: 48kHz WAV → validated and resampled to 44.1kHz
- T6.2.6: Unit test: non-WAV file → `.invalidFormat` thrown
- T6.2.7: Unit test: corrupt WAV → `.corruptFile` thrown
- T6.2.8: Unit test: mono WAV → normalized to stereo

**S6.3 — Truncation dialog (P0)**
- T6.3.1: If `duration > 15s`, present alert: "This file is [Xs]. Maximum is 15 seconds. Truncate to 15s or cancel?"
- T6.3.2: On Truncate: trim buffer to 15s; save truncated WAV to sandbox
- T6.3.3: On Cancel: abort import; pad unchanged
- T6.3.4: Unit test: file exactly 15.001s → truncation dialog shown
- T6.3.5: Unit test: file exactly 15.0s → no truncation dialog

---

### E7 — Error Handling & UX Polish

**Stories:**

**S7.1 — Generation error states (P1)**
- T7.1.1: In `GenerationView`: catch `GenerationError` types; map to user-facing messages
- T7.1.2: `.resourceInsufficient` → "Not enough memory. Close other apps and try again." + Retry
- T7.1.3: `.thermalThrottle` → "Device is too warm for generation. Wait a moment and try again." + Retry
- T7.1.4: `.modelLoadFailed` → "Generation model could not be loaded. Try reinstalling the app." + Dismiss
- T7.1.5: `.inferenceError` → "Generation failed. Please try again." + Retry
- T7.1.6: Retry button re-triggers `GenerationService.generate(prompt:)`

**S7.2 — Device unsupported fallback (P1)**
- T7.2.1: On app launch, `DeviceCapabilityChecker.isSupported()` — if false, set flag in app environment
- T7.2.2: PadViewModel: if unsupported, action sheet shows "Load from Files" only; "Generate" hidden
- T7.2.3: Info banner: "AI generation requires iPhone 12 or later. You can still load samples from Files."

**S7.3 — Low memory and low storage (P2)**
- T7.3.1: In `GenerationService.generate()`: check `SampleStore.availableStorageCheck()`; if false, throw `.lowStorage`
- T7.3.2: Subscribe to `UIApplication.didReceiveMemoryWarningNotification`; if generation running, cancel and show error
- T7.3.3: In `FileValidationService`: check storage before copy; throw `.insufficientStorage` if needed

**S7.4 — Pad replacement confirmation (P1)**
- T7.4.1: In `PadViewModel`, if pad has existing sample and user chooses Generate or Load, present confirmation: "Replace existing sample on Pad [N]?"
- T7.4.2: On Confirm: proceed with generation/import flow
- T7.4.3: On Cancel: dismiss; pad unchanged

---

## Test Design Summary

### Unit Tests (Swift Testing — mpcTests.swift)

```
Pad/SampleMetadata:
  - test_pad_codable_roundTrip
  - test_sampleMetadata_codable_roundTrip
  - test_pad_nilOptionalFields_encodedAsNull

SampleStore:
  - test_sampleStore_assignAndReload
  - test_sampleStore_removeAndReload
  - test_sampleStore_cleanupOrphans

AudioConverter:
  - test_audioConverter_48kHzTo441kHz
  - test_audioConverter_monoToStereo
  - test_audioConverter_preservesDuration

FileValidationService:
  - test_fileValidation_validWAV_passes
  - test_fileValidation_nonWAV_throwsInvalidFormat
  - test_fileValidation_corruptFile_throwsCorruptFile
  - test_fileValidation_over15s_throwsFileTooLong
  - test_fileValidation_exactly15s_passes
  - test_fileValidation_monoInput_normalizedToStereo

GenerationService:
  - test_generation_cancelledTask_returnsCancelledError
  - test_generation_invalidModelPath_throwsModelLoadFailed

DeviceCapabilityChecker:
  - test_deviceCheck_A14_isSupported
  - test_deviceCheck_belowThreshold_isUnsupported

Long-press gesture:
  - test_longPress_5sThreshold_triggersMenu
  - test_longPress_below5s_doesNotTriggerMenu
```

### Integration Tests (XCTest — mpcUITests.swift)

```
  - test_assignWAV_tapPad_playsAudio
  - test_importWAV_persistsAcrossRestart
  - test_replaceAssignment_confirmationRequired
  - test_generation_progressUI_appearsOnGenerate  [requires model mock]
  - test_generation_cancel_abortsInference  [requires model mock]
  - test_truncation_over15s_dialogAppears
  - test_truncation_confirm_trimsSample
```

### Performance Tests

```
  - measure_playbackLatency_tapToAudio  (target ≤ 200ms)
  - measure_generation_time_A14  (log; target < 30s)
  - measure_bufferPreload_8Pads  (must complete before first tap)
  - measure_peakMemory_duringGeneration  (log; must not OOM)
```

### Manual Acceptance Tests (matching prompt.md ACs)

```
  AC-1: Launch app → 8 pads show, empty = "+", loaded = waveform thumbnail
  AC-2: Hold pad for 5.0s → menu appears; hold 4.9s → menu does NOT appear
  AC-3: Enter prompt → tap Generate → progress shows → sample assigned → tap → sound plays
        (negative: model fails → human-readable error → retry works)
  AC-4: Load a 20s WAV → truncation dialog → truncate → assigned and plays
  AC-5: Tap assigned pad → audio audible within 200ms (measured on A14)
  AC-6: Enable airplane mode → generate and load both complete successfully
  AC-7: Force-quit app → relaunch → all pads restore with correct thumbnails
```

---

## Definition of Ready — Per Epic

| Epic | DoR Status | Blockers |
|------|-----------|---------|
| E1 Infrastructure | ✅ Ready | None |
| E2 Pad Grid UI | ✅ Ready | E3 data model must merge first |
| E3 Data Model | ✅ Ready | None |
| E4 Audio Playback | ✅ Ready | E3 must merge first |
| E5 AI Generation | ⚠️ Spike required | ADR-003 not final; license not reviewed |
| E6 File Import | ✅ Ready | E3 + E4 must merge first |
| E7 Error Handling | ⚠️ Partially blocked | E4, E5, E6 must be functional first |

---

# PART 5 — UI/UX DESIGN REQUIREMENTS

## Screens to Design (Priority Order)

### P0 — Core Flow (required before SWE E2 implementation)

1. **Pad Grid — empty state** (all 8 pads, "+", dark/minimal aesthetic typical of hardware MPC)
2. **Pad Grid — loaded state** (pads with waveform thumbnails, waveform color + pad label)
3. **Long-press affordance** (5s hold — consider progress ring or ripple to indicate time remaining)
4. **Action sheet** — Generate / Load / Cancel (and replacement variant)

### P1 — Generation Flow

5. **Generate modal** — text input, placeholder, Generate button, keyboard-up layout
6. **Generation progress** — spinner, time estimate label, Cancel button
7. **Generation error** — message variants for OOM, thermal, model failure; Retry button

### P2 — Import + Edge Cases

8. **Truncation dialog** — clear duration messaging, Truncate/Cancel
9. **Replacement confirmation** — which pad, what's being replaced
10. **Device unsupported banner** — inline, non-blocking
11. **Low storage alert** — modal or banner

## Design Tokens Required

```
Colors:
  - padEmpty: background, label color
  - padLoaded: background, waveform color, label color
  - padTapFlash: overlay color
  - accentPrimary: Generate button, progress indicator
  - accentDestructive: Replace action

Typography:
  - padLabel: size, weight
  - modalTitle: size, weight
  - bodyText: size, weight
  - caption: size, weight (for waveform duration label)

Spacing:
  - padGridSpacing: gap between pads
  - padCornerRadius
  - modalPadding

Animation:
  - tapFlashDuration: 0.1s
  - longPressProgressRing: 5.0s fill animation
```

## Accessibility Requirements

- All pads: `accessibilityLabel("Pad \(n)")`, `accessibilityHint("Double-tap to play. Hold for 5 seconds to assign.")`
- Action sheet items: clear VoiceOver labels
- Error messages: `accessibilityAnnouncement` for dynamic errors
- Color contrast: WCAG 2.1 AA (4.5:1 for text, 3:1 for UI components)
- Minimum touch target: 44×44pt per Apple HIG

---

# PART 6 — HANDOFF STATUS

## PM → UI/UX Handoff

```
Status: PENDING
Trigger: PRD approved ✅
PM Provides:
  ✅ PRD with UX Requirements section (Part 1 above)
  ✅ Feature stories with ACs
  ✅ Personas (Pocket Producer, Field Recordist)
  ✅ Platform: iOS 17+, iPhone, portrait
  ✅ Accessibility: WCAG 2.1 AA
  ✅ 11 screens/states requiring design
  ❌ Figma file not yet created
Command: ROUTE: UIUX DESIGN — design pad grid, generation flow,
         import flow, error states per Part 5 above
```

## PM → SWE Handoff

```
Status: PENDING (awaiting design + DoR verification)
Trigger: PRD approved ✅ | Design: pending
PM Provides:
  ✅ PRD with API/Data Requirements
  ✅ All stories with Given/When/Then ACs
  ✅ Out-of-scope items explicit (Phase 2 list)
  ✅ Rollout: internal → TestFlight → App Store
  ✅ No feature flags needed
Command: ROUTE: PM DEFINITION — HANDOFF: ENGINEERING
         (execute after UI/UX design handoff complete)
```

## UI/UX → SWE Handoff

```
Status: NOT STARTED
Requires: UIUX DESIGN to produce wireframe specs, component specs,
          design tokens, accessibility spec, and handoff doc
```

---

# APPENDIX A — FOLDER STRUCTURE (Target)

```
mpc/
  mpc/
    App/
      mpcApp.swift
    Features/
      PadGrid/
        PadGridView.swift
        PadView.swift
        WaveformThumbnailView.swift
        PadViewModel.swift
      Generation/
        GenerationView.swift
        GenerationProgressView.swift
        GenerationService.swift
      FileImport/
        DocumentPickerView.swift
        FileValidationService.swift
        TruncationAlertView.swift
    Core/
      Audio/
        AudioEngine.swift
        AudioSessionManager.swift
        PlaybackService.swift
        AudioConverter.swift
      Models/
        Pad.swift
        SampleMetadata.swift
        SampleStore.swift
        DeviceCapabilityChecker.swift
      Errors/
        GenerationError.swift
        ImportError.swift
        StorageError.swift
        PlaybackError.swift
    Resources/
      Assets.xcassets/
  mpcTests/
    Models/
      PadTests.swift
      SampleStoreTests.swift
    Audio/
      AudioConverterTests.swift
      PlaybackServiceTests.swift
    Import/
      FileValidationTests.swift
    Generation/
      GenerationServiceTests.swift
  mpcUITests/
    PadGridUITests.swift
    GenerationUITests.swift
    ImportUITests.swift
```

---

*Last updated: 2026-02-26 | Next update: end of Sprint 1 (2026-03-13)*
