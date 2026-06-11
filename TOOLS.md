# TOOLS.md — Command Surface & External Dependencies

## just Recipes

| Recipe | What it does | When to run |
|---|---|---|
| `just` | Lists all recipes | Orientation |
| `just bootstrap` | `xcodegen generate` from `project.yml`, then resolves SPM dependencies | After cloning, and after any `project.yml` or package-manifest change |
| `just build` | `xcodebuild build`, scheme `SiteScribe`, iOS Simulator destination | Sanity check during development |
| `just test` | `xcodebuild test` on the iPhone 16 simulator | After every change; part of TDD loop |
| `just lint` | `swiftlint lint` over all Swift sources | Before committing |
| `just format` | `swiftformat .` (whole repo) | Before committing; also runs via harness hook on edit |
| `just ci` | `lint` + `build` + `test` in sequence | The local merge gate — must be green before any commit |

Pre-bootstrap behavior: `bootstrap`/`build`/`test`/`lint` detect the missing
`project.yml` / `.xcodeproj` / Swift sources and exit 1 with guidance pointing at
DESIGN.md milestone M0. This is intentional so the docs-only scaffold fails loudly
instead of confusingly.

Required local tooling: Xcode 26+ (iOS 26 SDK, iPhone 16 simulator), `just`,
`xcodegen`, `swiftformat`, `swiftlint` (all via Homebrew).

## External Data Sources / APIs

Core inference is on-device Apple system frameworks — no auth, no rate limits, zero COGS:

| Dependency | Role | Auth | Cost / limits |
|---|---|---|---|
| FoundationModels (`@Generable`, AFM 3 Core) | Structured report-field extraction, on-device | none | Free; ~4k context → chunked extraction required |
| FoundationModels AFM 3 Core Advanced + OCRTool/BarcodeReaderTool | Image-input extraction, progressive enhancement only (iPhone 15 Pro+ class) | none | Free; gated by runtime capability check |
| Vision `RecognizeDocumentsRequest` + VisionKit `DataScannerViewController` | Universal OCR/barcode path, all supported devices | none | Free, on-device |
| SpeechAnalyzer / SpeechTranscriber | Offline dictation | none | Free, on-device |
| whisper.cpp (large-v3-turbo, Metal) | ASR fallback on older devices | none | Model file bundled/downloaded once (~1.6 GB); ship as on-demand resource |
| NLContextualEmbedding + sqlite-vec (via GRDB) | Local RAG over past reports | none | Free, on-device |
| Anthropic Claude (Haiku-class) — optional cloud polish | Opt-in narrative polish on sync, via FoundationModels third-party adapter or direct API | `ANTHROPIC_API_KEY` | ~$0.01/report order of magnitude; never on the critical path |
| Gemini Flash — alternative polish provider | Same opt-in role | `GEMINI_API_KEY` | Comparable cost; pick one provider per build |

There is no scraping and no third-party data feed. Per AGENTS.md invariant 2, only
SyncKit may call any of the networked services.

## Environment Variables

No env var is required to build, test, or run the core offline product.

| Variable | Purpose | Required |
|---|---|---|
| `ANTHROPIC_API_KEY` | Opt-in cloud polish pass (Claude Haiku-class) in SyncKit | No — feature disabled when absent |
| `GEMINI_API_KEY` | Alternative polish provider | No |
| `SITESCRIBE_DISABLE_NETWORK` | Test/dev flag: hard-fails any URLSession use, used by offline test suite | No (tests set it) |

Keys live in the developer's shell env / CI secrets and at runtime in the Keychain.
Never commit them; never embed them in source or Info.plist.

## Local Services

None. There is no docker compose, no Postgres, no backend in this repo. The sync
backend (CloudKit vs. custom) is an M3+ decision tracked in DESIGN.md; until then
SyncKit drains its queue against a protocol-typed transport that tests fake.

## CI Overview (`.github/workflows/ci.yml`)

- Runs on `macos-15`, triggered by every push and pull request.
- Steps: checkout → setup `just` → `brew install swiftformat swiftlint` → bootstrap guard → `just ci`.
- **Bootstrap guard:** if `project.yml` does not exist, CI prints a notice and skips
  bootstrap/build/test, keeping the docs-only scaffold green. Once M0 lands
  (`project.yml` committed), CI installs `xcodegen`, runs `just bootstrap`, then `just ci`.
- Note: FoundationModels is not exercisable on CI runners — extraction tests must run
  against the deterministic `ExtractionEngine` fake (see AGENTS.md testing policy).

## AI Harness Notes (`.claude/settings.json`)

Active hooks (copied verbatim from the iOS scaffold template — do not edit):

- **PostToolUse on Write|Edit of `*.swift`:** runs `swiftformat` on the edited file, then
  `swiftlint lint --quiet` and surfaces the first 10 findings. Fix lint output immediately
  rather than letting it pile up for `just ci`.
- Permission allowlist covers `just`, `xcodebuild`, `xcrun`, `swift`, `swiftformat`,
  `swiftlint`, `xcodegen`, and read-only `git status/diff/log`.

Most useful subagents/skills for this repo:

- **tdd-guide** — start every new feature here; extraction and parser work is golden-test driven.
- **code-reviewer** — immediately after writing or modifying code.
- **security-reviewer** — mandatory for anything touching SyncKit, export, capture
  storage, or Keychain (user data + the no-egress invariant).
- Skills: `foundation-models-on-device` (@Generable patterns), `swiftui-patterns`,
  `swift-concurrency-6-2` (strict concurrency), `swift-protocol-di-testing` (faking
  FoundationModels/Vision in tests), `liquid-glass-design` (iOS 26 system material, used
  sparingly within the Jobsite Instrument direction).
