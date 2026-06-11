# AGENTS.md — Operating Manual for SiteScribe

## Project Snapshot

**SiteScribe** is an offline-first AI field-documentation copilot for iOS: photograph,
dictate, and auto-generate structured inspection reports, receipts, and job records at
zero signal, syncing when coverage returns. All AI inference runs on-device
(FoundationModels + Vision); the cloud is an opt-in polish pass, never a dependency.

- **Who pays:** home/building inspectors (beachhead vertical), insurance adjusters,
  utility/telecom field techs, solo trade contractors. B2B per-seat: Solo ~$16.99/mo,
  Teams ~$34.99/user/mo, free tier capped at ~10 AI-extracted documents/mo.
- **Status:** Recommended (#3 of 9 finalists in the edge-AI research run). Skeptic
  verdict "weakened" — read the adversarial review in README.md before making product calls.
- **Sibling:** Android app comes later (ML Kit Document Scanner path). This repo is iOS only.

## Read First

1. `README.md` — research dossier: concept, market evidence, adversarial review, tech stack. Do not edit it.
2. `DESIGN.md` — architecture, data model, key flows, milestones (M0–M3), risks.
3. `TOOLS.md` — every command, env var, and harness detail.

## Commands

`just` is the single source of truth. Never run raw `xcodebuild`/`swiftlint` directly.

| Recipe | Purpose |
|---|---|
| `just` | List all recipes |
| `just bootstrap` | Generate `SiteScribe.xcodeproj` via XcodeGen + resolve SPM packages |
| `just build` | Build the `SiteScribe` scheme for the iOS Simulator |
| `just test` | Run tests on the iPhone 16 simulator |
| `just lint` | SwiftLint over all Swift sources |
| `just format` | swiftformat the whole repo |
| `just ci` | lint + build + test — must be green before any commit |

Pre-bootstrap (no `project.yml` / `.xcodeproj` yet) the build/test recipes fail with
guidance instead of cryptic errors; that is expected until milestone M0 lands.

## Architecture Summary

Capture-first pipeline, entirely on-device: CaptureKit persists photos/audio to GRDB
before anything else touches them; RecognitionKit runs the universal deterministic layer
(Vision `RecognizeDocumentsRequest` OCR, barcode, regex parsers for serials/meter values —
works on every supported iPhone); ExtractionKit runs FoundationModels `@Generable` guided
generation against the report's JSON-Schema-derived structs, with AFM 3 image input used
only as a progressive enhancement on capable devices; ReportKit assembles the reviewed
fields into a template and renders PDF via PDFKit; StorageKit owns the offline store and
sqlite-vec local RAG; SyncKit is the sole module with network access, draining a
BGTaskScheduler queue on reconnect. Module map (must match DESIGN.md):

```
SiteScribeApp (shell, composition root)  ←  XcodeGen project.yml
Packages/
  CaptureKit      camera, VisionKit scanner, audio recording, dictation sessions
  RecognitionKit  Vision OCR/barcode, deterministic parsers, device-capability probe
  ExtractionKit   FoundationModels @Generable extraction, chunking, test fakes
  ReportKit       templates (JSON Schema source of truth), review states, PDFKit export
  StorageKit      GRDB/SQLite, sqlite-vec + NLContextualEmbedding local RAG
  SyncKit         BGTaskScheduler queue, merge, opt-in cloud polish (only networked module)
  DesignSystem    "Jobsite Instrument" tokens + components
  Features/       JobsFeature, CaptureFeature, ReviewFeature, ReportFeature (SwiftUI)
```

## Coding Standards

- Swift 6, strict concurrency (`StrictConcurrency` enabled in every package); actors or
  `Sendable` value types at module boundaries.
- Files < 800 lines, functions < 50 lines; split by feature, not by type.
- Immutability by default: value types, `let`, reducers that return new state. No shared
  mutable state outside actors.
- Explicit error handling at every boundary: typed `throws`, no `try?` that swallows
  errors, user-facing failures get a recovery path (re-shoot, retry, edit manually).
- No hardcoded secrets. API keys (cloud polish only) come from env vars / Keychain — see TOOLS.md.
- Conventional commits: `feat:` `fix:` `refactor:` `docs:` `test:` `chore:`.
- Dependency injection via protocols so FoundationModels/Vision/network can be faked in tests.

## Testing Policy

- TDD: write the failing test first, then implement. Target 80%+ coverage on logic
  modules (RecognitionKit parsers, ExtractionKit, ReportKit, StorageKit, SyncKit).
- Swift Testing for new unit tests; XCTest where UI testing requires it. AAA pattern,
  behavior-describing test names.
- Tests that matter most for THIS product, in order:
  1. **Extraction golden tests** — fixture images/transcripts → expected structured fields,
     run against a deterministic `ExtractionEngine` fake (FoundationModels is unavailable on CI).
  2. **Offline tests** — every core flow must pass with a network-denying URLProtocol stub installed.
  3. **Durability tests** — simulated crash between capture and processing loses nothing.
  4. **Schema round-trips** — JSON Schema template → @Generable struct → report → PDF/CSV and back.
  5. **Sync-queue tests** — ordering, retry, merge of edits made on-device while queued.
- PDF output gets snapshot tests once ReportKit renders.

## PRODUCT INVARIANTS (non-negotiable)

Each invariant is enforceable by a test or static check. Breaking one is a blocking bug.

1. **Offline-complete:** capture → recognition → extraction → review → PDF export must
   succeed in airplane mode. No core code path may await a network call.
2. **No silent egress:** photos, audio, transcripts, and extracted data leave the device
   only through SyncKit, and only after explicit user opt-in. Cloud polish is opt-in
   per report and visibly labeled. Only SyncKit may import a networking client.
3. **Universal OCR path:** Vision `RecognizeDocumentsRequest` + barcode works on every
   supported device. AFM 3 image input is progressive enhancement behind a runtime
   capability check — no feature may hard-require AFM Core Advanced.
4. **Deterministic before LLM:** serial numbers, model numbers, meter values, dates,
   units, and prices are produced by OCR/barcode/regex parsers and copied verbatim. The
   LLM classifies and narrates; it never invents or "corrects" an identifier or number.
5. **Schema conformance is not correctness:** every AI-extracted field carries provenance
   (source capture + region/timespan) and confidence. No AI-derived value enters a
   finalized PDF without an explicit user confirm/edit (`reviewState != unreviewed`).
   These are E&O-liability-bearing documents; the inspector signs, the app never auto-sends.
6. **Capture is never lost:** every photo/voice note is durably persisted via StorageKit
   before any processing starts; crash/kill mid-job must not drop a capture.
7. **Long dictation is chunked, never truncated:** AFM Core's small context window means
   walkthrough transcripts are extracted in chunks and merged; dropping content silently
   is forbidden.
8. **No data lock-in:** every finalized report exports to PDF and CSV (Spectora-importable
   format on the roadmap). User data is always exportable.

## Definition of Done

- [ ] `just ci` green (lint + build + test)
- [ ] New logic covered by tests written first; coverage ≥ 80% on touched modules
- [ ] No product invariant violated (check the list above explicitly)
- [ ] Errors handled at every boundary; no `try?` swallows, no force-unwraps in shipped code
- [ ] No secrets, no network calls outside SyncKit, no API gated solely on AFM Core Advanced
- [ ] Files < 800 lines, functions < 50 lines, Swift 6 strict-concurrency clean
- [ ] Conventional commit message; DESIGN.md updated if architecture or data model changed
