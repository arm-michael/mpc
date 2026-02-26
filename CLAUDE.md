# CLAUDE.md — MPC iOS App

> Master configuration for all Claude agents on this project.
> All agents must read this file first, before any agent-specific file.

---

## Project Overview

**Name:** MPC
**Platform:** iOS native (iPhone)
**Language:** Swift + SwiftUI
**Audio engine:** AVAudioEngine + AVAudioPlayerNode
**On-device AI:** Stability AI — Stable Audio Open Small (Arm/LiteRT or Core ML)
**Connectivity:** Offline-first — generation and playback require zero network
**Storage:** App sandbox (`Documents/` or `Library/Application Support/`)

### What We're Building

An 8-pad MPC-style iOS app (2 rows × 4 pads). Phase 1 delivers two ways to attach a sound to a pad:
1. **Generate** — on-device text-to-audio via Stable Audio Open Small (up to ~11s stereo 44.1kHz WAV)
2. **Load** — import a local `.wav` via UIDocumentPicker

Playback is one-shot per tap. Long-press (5 seconds) opens the assign/replace flow.

**Phase 2 scope (do not implement now):** hold/one-shot modes, recording, sequencing, pad MIDI out, sample trimming + basic ADSR, save/load projects.

Full spec: `prompt.md`

---

## Repo Status

> **NOT YET INITIALIZED.** The SWE agent must run the repo init sequence below before any feature work begins.

### One-time Repo Init (SWE IMPLEMENTER — run once)

```bash
# 1. Initialize git
git init

# 2. Create .gitignore (Swift/Xcode template)
# Use: https://gitignore.io — select Swift, Xcode, macOS, CocoaPods (if used)

# 3. Create README.md with project name + one-line description

# 4. Initial commit
git add .gitignore README.md
git commit -m "chore: initialize repository"

# 5. Create GitHub repo (private)
gh repo create <org-or-username>/mpc --private --source=. --push

# 6. Ensure main is default
git branch -M main
git push -u origin main

# 7. Set branch protection (require 1 PR approval, no direct push to main)
# Configure via GitHub UI → Settings → Branches → main

# 8. Create CI stub
mkdir -p .github/workflows
# Add a placeholder workflow file
```

Init checklist:
- [ ] Repo created on GitHub
- [ ] `main` branch protected
- [ ] `.gitignore` (Swift/Xcode) committed
- [ ] `README.md` committed
- [ ] `.github/workflows/` stub committed

---

## Agent Configuration

### Active Agents

| Agent | File | Activation |
|-------|------|------------|
| Orchestrator | `CLAUDE-ORCHESTRATOR.md` | `ACTIVATE: ORCHESTRATOR` |
| Product Manager | `CLAUDE-PM.md` | `ROUTE: PM` |
| Program Manager | `CLAUDE-PROG.md` | `ROUTE: TPM` |
| UI/UX Designer | `CLAUDE-UIUX.md` | `ROUTE: UIUX` |
| Software Engineer | `CLAUDE-SWE.md` | `ROUTE: SWE` |

### Shared Standards

| File | Purpose |
|------|---------|
| `GITHUB-STANDARDS.md` | Git, branching, commits, PRs — SWE executes, others consume |

> **No Jira on this project.** All work tracking uses **GitHub Issues**.
> Every reference to "Jira" in agent files maps to GitHub Issues.
> Every reference to "Jira key" maps to a GitHub Issue number (e.g., `#42`).

---

## Tracking: GitHub Issues (replaces Jira)

- GitHub Issues = source of truth for all work items
- Use labels: `epic`, `feat`, `fix`, `chore`, `docs`, `bug`, `blocked`, `needs-review`, `phase-2`
- Every branch must reference an issue number: `feat/42-pad-grid-ui`
- Every PR must close or reference an issue: `Closes #42`
- Create an issue before starting any work — no untracked branches

### Issue Hierarchy (replaces Jira Epic → Story → Task)

```
Epic issue (label: epic)
  → Feature issue (label: feat) — references parent epic in body
    → Sub-task issues (label: chore/task) — references parent feature
```

Link child issues to parent in the issue body:
```
Part of #<epic-issue-number>
```

---

## Tech Stack Reference

| Concern | Choice |
|---------|--------|
| UI framework | SwiftUI |
| Audio playback | AVAudioEngine + AVAudioPlayerNode |
| Audio conversion | AVAudioConverter |
| File import | UIDocumentPicker |
| On-device ML | Stable Audio Open Small via Arm/LiteRT or Core ML |
| Persistence | App sandbox — `Documents/{padID}_{uuid}.wav` + `index.json` |
| Testing | XCTest (unit + integration) |
| Package manager | Swift Package Manager (default; CocoaPods only if forced by a dependency) |
| Min iOS target | iOS 17 (A14 chip or later recommended for ML inference) |
| Deployment | App Store (Phase 1 target) |

### Model Constraints (encode in app)

- Max generated length: ~11 seconds
- Output format: stereo WAV, 44.1kHz
- Inference: CPU-bound (seconds, not minutes on A14+)
- Fallback: show "device not supported" if below memory/CPU threshold

### Audio File Rules

- Internal format: stereo WAV 44.1kHz (normalize all inputs)
- Max imported file duration: 15 seconds (warn + offer truncation)
- Generated file max: ~11 seconds (model limit, enforced programmatically)
- Resample using `AVAudioConverter` when needed

### Storage Layout

```
Documents/
  samples/
    {padID}_{uuid}.wav
  index.json          ← pad assignments, metadata (prompt, duration, date)
```

---

## Current Session State

```
ORCHESTRATOR SESSION STATE:
  Active Program: MPC iOS App
  Phase: Engineer (repo init + Phase 1 implementation)
  Sprint: 1

  PM:
    Mode: idle
    Active PRD: prompt.md (v1 — approved)
    Pending Handoffs: Engineering: in progress

  TPM:
    Mode: idle

  UI/UX:
    Mode: idle

  SWE:
    Mode: idle
    Active Story: —
    Active Branch: —
    Repo: NOT YET INITIALIZED

  Shared:
    GitHub Repo: TBD (pending init)
    Gate Status: Awaiting repo init (Step 0)
    Blockers: repo not initialized
```

---

## Phase 1 — Sprint 1 Scope

Once the repo is initialized, the first sprint delivers:

1. **Repo + project setup** — Xcode project, folder structure, SwiftLint config, CI stub
2. **Pad grid UI** — 8 pads (2×4), waveform thumbnail when sample present, "+" for empty
3. **Long-press detection** — exactly 5 seconds, opens action sheet (Generate / Load)
4. **File import** — UIDocumentPicker → WAV validation → resample → save → assign to pad
5. **Playback** — AVAudioEngine one-shot, preloaded buffers, ≤ 200ms tap-to-sound latency
6. **Model integration spike** — prototype Stable Audio Open Small on device, measure CPU/memory/latency
7. **Generation flow** — text prompt modal → progress UI + cancel → on-device generation → assign to pad
8. **Error handling** — model failure, low memory, low storage, file format errors

---

## Operating Rules (All Agents)

1. Read this file (`CLAUDE.md`) first, every session.
2. Follow `GITHUB-STANDARDS.md` for all Git operations — no exceptions.
3. No Jira. Use GitHub Issues. Map all Jira references to issue numbers.
4. No direct pushes to `main`. Always PR.
5. No feature work without a GitHub Issue open first.
6. SWE must run the repo init checklist before any code lands.
7. Phase 2 items are explicitly out of scope — do not implement, do not design for them speculatively.
8. Model licensing: verify Stability AI license terms before any distribution. Include required attribution.
9. No secrets or credentials in code — use `.env` or Xcode `xcconfig` for any keys.
10. Every TODO in code must reference a GitHub issue: `// TODO(#42): description`
