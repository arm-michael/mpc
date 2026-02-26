1 — Spec-generation prompt (copy/paste)

Write a precise product specification for an iOS native app (iPhone) that mimics an 8-pad MPC layout (2 rows × 4 pads) with two core Phase-1 features: 1) on-device text→audio generation using Stability AI’s Stable Audio Open Small model and 2) loading local .wav samples from the phone file system. Keep the app intentionally minimal and production-grade.

Requirements to include in the spec:
	•	Target platform: iOS native (Swift + SwiftUI for UI; AVAudioEngine for audio playback). Offline first: the audio generation must run on-device using Stable Audio Open Small (optimized for Arm CPUs). Cite model limits: generates up to ~11s, stereo at 44.1kHz. Include model licensing consideration (Stability AI).  ￼
	•	Primary UX flow: launch → 8 pads visible → long-press any pad for 5 seconds → contextual menu with two options: “Generate (Stable Audio)” and “Load from Files.” Long-press timeout = 5s. “Generate” opens a single-line prompt input; typing a prompt and confirming triggers on-device generation; generated .wav is attached to the pad. “Load from Files” opens UIDocumentPicker to select a .wav. Only one-shot playback in Phase-1 (tap plays sample once). Changing a pad’s sample repeats the same long-press flow. Include accessibility labels for pads and menu items.
	•	Audio format and constraints: accept .wav files; normalize/resample generated outputs to app audio engine native sample rate (44.1kHz preferred). Enforce max sample length = model max (~11s) for generated audio; set upper limit for imported files (e.g., 15s) and document behavior for longer files (truncate with warning or downsample).
	•	UX states, error handling and progress UI: generation progress indicator, cancel option, graceful failure text when model fails or device resource insufficient, low-storage warning, and permission flows for file access and microphone (if Phase-2 requires recording later).
	•	Engineering deliverables: UI mocks (screen states), data flow diagram, on-device model integration plan (runtime, conversion steps), memory/CPU budget, background/foreground audio behavior, unit + integration test plan, and an acceptance test checklist.
	•	Phase-2 brief (do not implement now): add hold vs one-shot modes, recording and sequencing, pad MIDI out, sample trimming and basic ADSR, save/load projects. Provide a migration plan so Phase-2 doesn’t require data model rework.

Finally, output:
	•	a one-page executive summary,
	•	a detailed spec (epics → stories → acceptance criteria),
	•	UI wireframes or description for 4 key screens,
	•	a technical integration appendix with concrete steps to add the Stable Audio Open Small model on iOS (conversion, runtime options, expected model limits),
	•	a risk register with mitigations (battery/thermal, legal/licensing, device compatibility).

2 — Compact actionable spec (engineer-ready)

Executive summary

iOS native MPC-style app (8 pads). Phase 1: attach samples to pads either by generating them on-device via Stability AI’s Stable Audio Open Small model or by loading local .wav files. Playback is one-shot per tap. Long press (5s) invokes the add/change flow. Phase 2: add hold playback, recording/sequencing, trimming, and project saves.

Key constraints & facts you must design around
	•	Stable Audio Open Small is intended to run on Arm CPUs and is optimized for on-device use; it generates up to ~11 seconds of stereo audio at 44.1kHz. Use this as the canonical generation length and sample rate target.  ￼
	•	Model is a compact variant (reported ~341M parameters) and optimized for smartphone inference; conversion and runtime options exist (Arm/LiteRT paths). Plan for device CPU inference times measured in seconds (not minutes).  ￼
	•	Pick WAV as the internal interchange format for generated and imported samples (model outputs WAV). Accept mono or stereo, but normalize to stereo 44.1kHz.  ￼

User flows (Phase 1)

Primary screen — Pad Grid
	•	UI: 2 rows × 4 pads, each pad shows label and small waveform thumbnail if sample present.
	•	Tap: one-shot play of the assigned sample. Visual tap feedback (flash + transient waveform).
	•	Long press: 5 seconds (exact). After 5s, show modal menu with two options:
	•	Generate with Stable Audio
	•	Load from Files

Generate flow
	•	Modal text input with placeholder “Describe the sound (e.g., ‘short punchy kick, 100ms, lo-fi’)”.
	•	Confirm button labeled “Generate”.
	•	On confirm: show progress modal with spinner + estimated time. Allow user to cancel.
	•	When generation completes: model returns up to 11s stereo WAV. App converts/resamples if needed, saves as pad asset, updates pad thumbnail.
	•	Acceptance: after generation success, tapping pad plays new sample within 200ms of UI action.

Load from Files flow
	•	Open UIDocumentPicker limited to audio/* and .wav. On selection, validate file (sample rate, channels, duration).
	•	If sample rate ≠ 44.1kHz, resample to 44.1kHz. If duration > 15s, present truncation dialog or reject with reason.
	•	Save sample to app sandbox, assign to pad.

Pad replacement
	•	Long press → same menu → either regenerate or reload. Confirm any destructive replacement with a one-tap confirm.

Phase-1 playback behavior
	•	One-shot only. No hold sustain. Disable hold behavior until Phase-2.

Acceptance criteria (testable)
	1.	UI: Pads load and display waveform thumbnail when sample exists; empty pads show “+” label.
	2.	Long press behavior: holding a pad for at least 5.0s opens the menu; less than 5.0s does not.
	3.	Generate: providing a prompt triggers on-device generation; progress UI appears; resulting sample length ≤ model max (~11s); resulting sample assigned to pad and plays on tap.
	•	If model fails due to device resources, show human-readable error and allow retry.
	4.	Load: selecting a .wav assigns it to pad. If sample longer than limit, user is warned and given choice to truncate.
	5.	Playback latency: audible start within 200ms of tap on modern iPhone hardware (e.g., A14 or later expected).
	6.	Offline operation: generation and load must work without network connectivity (model runs locally).
	7.	File handling: app stores .wav assets in app sandbox and uses system file browser for imports.

Technical appendix — integration notes (engineering)
	•	Runtime options:
	•	Preferred: run the Stable Audio Open Small model via an on-device runtime optimized for Arm (Arm KleidiAI/LiteRT or converted Core ML if feasible). Use code samples and conversion guide from Arm/Stability AI resources.  ￼
	•	Evaluate model size & memory footprint on target iPhone families (A14 and up recommended). If memory is constrained, implement a fallback UX telling users device is unsupported.
	•	Model facts to encode in app:
	•	Max generated length ≈ 11s; stereo; 44.1kHz sample rate. Enforce these programmatically.  ￼
	•	Audio engine:
	•	AVAudioEngine + AVAudioPlayerNode for sample playback, low latency.
	•	Preload audio buffers for immediate playback; decode and store compressed on disk as WAV (or store decoded PCM in memory for active pads with memory cap).
	•	Resample inputs to 44.1kHz using AVAudioConverter when necessary.
	•	Storage:
	•	Store pad assets in app Documents (or Library/Application Support) with clear naming {padID}_{uuid}.wav, and maintain an index JSON for pad assignment and metadata (duration, original prompt, date).
	•	Implement cleanup policy for low disk space.
	•	Permissions:
	•	UIDocumentPicker (file access) requires no explicit permissions beyond the system picker. If Phase-2 introduces recording, request microphone permission at that time.
	•	Background/Interrupt handling:
	•	App should stop generation if interrupted by low memory; gracefully abort with message. Suspend generation when app goes to background and restore state on resume.
	•	Testing:
	•	Unit tests: pad assignment, file validation, resampling.
	•	Integration tests: end-to-end generate→assign→play on test devices (A14/A15/A16).
	•	Performance tests: measure CPU, memory, and latency of generation on target devices. Create a bench script that runs model and logs duration.
	•	Licensing & legal:
	•	Check Stability AI license for commercial use and include required attribution/safeguards where applicable. Implement terms acceptance at first-launch if required.  ￼

Edge cases & risk mitigations
	•	Low memory / thermal throttling: detect device model and throttle generation concurrency; show “device not supported” if below threshold.
	•	Battery drain: warn users in release notes; consider a “Low Power Mode” that disables generation.
	•	Large imported files: resample and truncate with clear prompt; give “trim” option only in Phase-2.
	•	Copyright: generated audio may sample training data; include a Terms/Disclaimer about ownership and use, and implement export restrictions if required by Stability AI license.  ￼

Minimal set of user stories (Phase 1)

Epic: Pad sample management
	•	Story 1: As a user, I can long-press any pad for 5s to open Generate/Load menu. Acceptance: menu opens after ≥5.0s.
	•	Story 2: As a user, I can generate a sample from text on device and assign it to a pad. Acceptance: generated WAV assigned and plays.
	•	Story 3: As a user, I can load a .wav from Files and assign it to a pad. Acceptance: imported sample plays; resampled if needed.
	•	Story 4: As a user, tapping a pad plays its sound as a single one-shot. Acceptance: audible within 200ms, no sustain behavior.

Deliverables for the first sprint
	•	Interactive wireframes: pad grid, long-press menu, generate modal, file picker flow, generation progress modal.
	•	Technical spike: prototype running Stable Audio Open Small on a modern iPhone and logging generation time and memory usage.
	•	Core implementation: pad grid UI, long-press detection, file import plumbing, AVAudioEngine playback stub.
	•	Integration: on-device model integration and sample assignment flow (end-to-end working for at least one device model).
	•	Tests: device performance reports and acceptance test checklist completed.

Quick developer checklist (actionable)
	•	Wireframes for 4 screens
	•	Create pad asset schema & persistence
	•	Implement pad grid + stable long-press (5s)
	•	Implement UIDocumentPicker import + WAV validation/resample
	•	Integrate AVAudioEngine playback and preload buffers
	•	Prototype Stable Audio Open Small on device (Arm/LiteRT or conversion)
	•	Add generation progress UI + cancel
	•	Add error handling and low-resource UX
	•	Prepare test matrix (A14/A15/A16) and run perf tests
	•	Legal review for model license and attribution

Citations / supporting references
	•	Stability AI announcement and Arm partnership explaining Stable Audio Open Small and on-device orientation.  ￼
	•	Hugging Face model page and details: generates up to ~11s, stereo at 44.1kHz.  ￼
	•	Arm developer guide / LiteRT resources for running Stable Audio Open Small on mobile CPUs.  ￼
	•	Industry coverage and quick stats on model size/behavior.  ￼