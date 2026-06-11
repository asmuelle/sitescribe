# SiteScribe

> Offline AI field-documentation copilot: photograph, dictate, and auto-generate structured inspection reports, receipts, and job records at zero signal, syncing when coverage returns.

**Category:** Edge AI / on-device inference (iOS + Android) · **Status:** ✅ Recommended (Top 5 of the edge-AI run)

## Scorecard

| Metric | Score |
|---|---|
| Rank (of 9 finalists) | #3 |
| Combined score | 5.6 |
| Monetization potential (1-10) | 7 |
| Feasibility (1-10) | 6 |
| Edge AI structurally essential | Yes |
| Skeptic verdict | weakened |

## Concept

Offline AI field-documentation copilot: photograph, dictate, and auto-generate structured inspection reports, receipts, and job records at zero signal, syncing when coverage returns.

## Target User & Payer

Home/building inspectors, insurance adjusters, utility and telecom field techs, and solo trade contractors — workers whose sites (basements, rural routes, industrial buildings) are dark zones for entire shifts and who bill by the completed report. Solo-contractor receipt/invoice capture is the bottom-up wedge into firms.

## Why Edge AI Is Structural (not decoration)

AFM 3 image input + OCRTool + BarcodeReaderTool read equipment tags, serial plates, meter values, and receipts from photos; @Generable fills the user's report schema (defect, location, severity, recommended action) deterministically; whisper.cpp transcribes walk-through voice notes offline; Spotlight local RAG answers 'what did I flag at this property last visit?' across past reports and scanned documents. Android parity via Gemma 4 E2B structured output in the AICore Developer Preview. Essential: 30% of frontline workers explicitly expect offline-capable apps — every cloud copilot returns a spinner exactly when the work happens, and unlimited daily extraction is free on-device where cloud-vision rivals bleed margin.

## Why Now (2026 timing)

Mobile document scanning + local LLM structured extraction has 'no polished commercial player' (only OSS hobby apps), and field ops/OCR is cited as the strongest near-term on-device use case; @Generable, OCRTool, and local RAG all shipped as free system primitives at WWDC26 — assembly cost just collapsed for whoever moves first.

## Proposed Monetization

B2B per-seat: $24.99/user/mo ($20 annual) for teams, $16.99/mo solo — priced against the 30-60 minutes of report-writing eliminated per job for workers billing $75-150/hr. Zero inference COGS protects margin at heavy daily usage (the documented 55% vs 85% cloud gross-margin gap). Land-and-expand into inspection firms via shared report templates.

## Competition & Gap

Generic cloud copilots (ChatGPT, Notion AI) fail offline; vertical inspection SaaS (Spectora, HomeGauge) does forms but no on-device AI extraction and assumes connectivity; OSS scanners are hobbyist. The gap is the intersection: structured AI extraction that works at signal-zero.

---

# Evaluation (multi-agent adversarial review)

## Monetization Analysis — score 7/10

The payer is proven, not hypothetical: home inspectors already pay $89-109/user/mo (Spectora $109/mo base + $89/mo per additional inspector; HomeGauge $89/mo), and solo trade contractors pay for SaaS at scale (Jobber ~$150M revenue, 100k+ customers by May 2026). The closest behavioral comp, CompanyCam (photo documentation for field crews), grew $32M to $68M ARR in one year and raised a $415M Series C at a $2B valuation in Aug 2025 — direct proof that 'capture-at-the-jobsite documentation' is a large, fast-growing wedge category, not a niche. The offline premise also checks out: industry coverage pegs ~65% of frontline manufacturing/field workers as operating in intermittent- or zero-connectivity environments, and offline-first is described as a baseline requirement, which validates the structural weakness of cloud-vision copilots. The zero-COGS on-device inference margin advantage is real at heavy daily photo/voice volume. What keeps this at 7 rather than 8-9: (1) the lead vertical has consolidated — HomeGauge is now part of Spectora, so the named beachhead is owned by one incumbent that controls the full workflow (scheduling, agreements, payments, report delivery), and inspection apps already do offline form capture; SiteScribe's true differentiation is offline AI extraction, a feature incumbents can copy once on-device APIs mature. (2) Insurance adjusters are locked into Xactimate-class ecosystems. (3) The four-segment target (inspectors, adjusters, utility techs, contractors) risks unfocused GTM. (4) Android parity depends on a Developer Preview API. A point-tool that lands bottom-up with solo contractors (CompanyCam's own playbook) is plausible and valuable, but the ceiling depends on expanding into workflow before Spectora/CompanyCam ship competent offline AI.

## Recommended Revenue Model

Keep B2B per-seat but reprice upward against reference points and add a usage-tier floor: (1) Solo: $16.99/mo or $149/yr is correctly priced for the contractor wedge (Jobber's entry tiers and CompanyCam's per-user pricing normalize $15-30/user/mo for solo field pros); add a free tier capped at ~10 AI-extracted documents/mo — zero inference COGS makes a generous free tier sustainable where cloud rivals bleed, and it fuels bottom-up land-and-expand. (2) Teams: raise from $24.99 to $34.99/user/mo ($29 annual) — inspectors already pay $89-109/mo to Spectora/HomeGauge, so a $35 add-on that saves 30-60 min of report writing per job (worth $40-150 at field billing rates) clears the value bar with room to spare; underpricing at $24.99 signals point-tool status. (3) Firm tier: $49/user/mo with shared template libraries, report branding, and admin/audit controls — templates are the lock-in asset. (4) Optional per-report metering ($2-3/published report) as an alternative for low-volume firms, mirroring Spectora Advanced's $4/inspection add-on, which validates per-report willingness to pay. Path to $1M ARR: ~2,400 solo subs or ~280 ten-seat firms; CompanyCam's trajectory shows the category supports $50M+ ARR if expansion into workflow succeeds.

## Market Evidence (live web research, June 2026)

Field service management software market: $2.1B-$5.5B in 2025 depending on methodology (MarketsandMarkets, Global Growth Insights, Verified Market Research); home inspection software sub-niche forecast at roughly $350M-$1.8B (credible estimates; one $123B figure found is not credible). Pricing evidence: Spectora $109/mo base, $89/mo per additional inspector, $4/inspection for the Advanced add-on (spectora.com/pricing); HomeGauge $89/mo and now part of the Spectora family — i.e., the beachhead vertical has consolidated under one incumbent (homegauge.com). Revenue evidence: Spectora ~$5.9M tracked revenue Sept 2025 per Latka (likely understated post-consolidation); CompanyCam $68M ARR Nov 2024 per Latka, up from $32M Dec 2023, $415M Series C at $2B valuation Aug 2025 (companycam.com/press, Crunchbase); Jobber ~$150M revenue 2023 per Sacra, 100k+ customers by May 2026. Offline demand: 2026 industry analysis reports ~65% of frontline manufacturing workers operate with intermittent or no connectivity, with offline-first sync described as a baseline requirement, not a feature (mobile.wednesday.is).

## Comparables

- Spectora (home inspection SaaS): $109/mo base + $89/mo per extra inspector + $4/inspection Advanced add-on; ~$5.9M tracked revenue Sept 2025 (Latka, likely understated); acquired HomeGauge
- HomeGauge (home inspection SaaS): $89/mo; now part of the Spectora family — beachhead vertical consolidated
- CompanyCam (field photo documentation, closest behavioral comp): $68M ARR Nov 2024, up from $32M Dec 2023; $415M Series C at $2B valuation Aug 2025; expanding into AI estimating/payments via Beam acquisition
- Jobber (solo/small trade contractor FSM): ~$150M revenue 2023 (Sacra); 100k+ customers and $100B services processed by May 2026 — proves solo-contractor willingness to pay
- Home Inspector Pro / ReportHost / 3D Inspection (long-tail inspection report writers): sub-$100/mo or per-report pricing; legacy, no on-device AI

## Adversarial Review — strongest case AGAINST (verdict: weakened)

Four-front attack. (1) The pitch conflates 'offline AI' with 'offline capture': photos and dictation capture offline with zero AI, and structured extraction could simply run on sync — which is when the inspector finalizes the report in the truck anyway — at ~$0.01/job with a frontier cloud model that beats any on-device model on accuracy. Only a thin slice (on-site re-shoot validation of misread serial plates, same-visit offline RAG, zero-COGS bulk extraction) genuinely requires edge inference. (2) The hardware contradicts the target user. WWDC26's Foundation Models image input requires AFM 3 Core Advanced, the 20B sparse model shipped on high-end devices only (iPhone 15 Pro+, latest iPad Pro/Mac); iPhone 14-class devices are text-only. On Android, Gemini Nano 4 demands 12GB RAM + flagship SoC + an AI accelerator, and Gemma 4 structured output is an AICore *Developer Preview* whose CPU fallback Google itself says is non-representative of production performance. Field techs, adjusters, and trades carry rugged mid-tier Androids (XCover/CAT class) and 3-5-year-old iPhones — exactly the fleet excluded. Quality ceiling: 3B-class AFM Core has a ~4k context that a 45-minute walkthrough dictation blows past, forcing chunked extraction; @Generable guarantees schema conformance, not correctness — a hallucinated severity rating or transposed model-vs-serial number in a signed, E&O-liability-bearing inspection or insurance document is the worst possible failure mode; Vision OCR on corroded/embossed plates in dark basements is the actual hard problem and wrapping it in an LLM tool call doesn't fix misreads; whisper-class ASR degrades under HVAC/generator noise and trade jargon; sustained camera+ASR+LLM over an 8-hour shift in a hot attic hits thermal throttling. (3) Platform/incumbent risk: Apple and Google just commoditized every primitive (OCRTool, BarcodeReaderTool, Spotlight local RAG, structured output) as free system features, so any incumbent can bolt the same pipeline on in a quarter. Spectora acquired HomeGauge in April 2025 (consolidated under Radian Capital) and already ships AI Comment Assist; for insurance adjusters Xactimate/Verisk is carrier-mandated, so the end user cannot choose SiteScribe. (4) Distribution: 'field documentation copilot' is not a search query; this category is sold at InterNACHI conferences, through franchise and carrier deals, and via decade-old SEO that Spectora owns. $24.99/seat positions a feature against suites that bundle scheduling, payments, templates, and client portals; the solo-contractor receipt wedge collides with Expensify, banking-app capture, and the free default of camera roll + texting an admin. A two-person team has no affordable B2B field-services sales motion. Why not killed: the pain (30-60 min of unbilled report writing per job) and the payer are real, offline dead zones are genuinely structural in this vertical, incumbents demonstrably lack vision AI on photos, and the survivable path exists — single vertical (home inspectors first), hybrid on-device-draft/cloud-polish architecture, and export into incumbent report formats instead of replacing the suite.

## Recommended Tech Stack

iOS (Swift/SwiftUI, iOS 26 floor with iOS 27 fast-follow): VisionKit DataScannerViewController + Vision RecognizeDocumentsRequest as the universal OCR/barcode path (works on all recent iPhones); FoundationModels @Generable guided generation against the user's report schema, using AFM 3 Core (text) everywhere and AFM 3 Core Advanced + OCRTool/BarcodeReaderTool only on capable devices; SpeechAnalyzer/SpeechTranscriber for offline dictation with whisper.cpp (large-v3-turbo, Metal) as fallback on older devices; NLContextualEmbedding + GRDB/SQLite with sqlite-vec for local RAG over past reports; BGTaskScheduler sync queue with an optional cloud polish pass (Claude Haiku-class or Gemini Flash via Foundation Models' new third-party adapter) on reconnect; PDFKit for report output. Android (Kotlin/Jetpack Compose): ML Kit Document Scanner + Text Recognition v2 for OCR (runs on ALL devices, no AICore dependency — this is the load-bearing choice); ML Kit GenAI Prompt API with structured output on Gemini Nano-capable flagships; MediaPipe LLM Inference API (LiteRT) with bundled Gemma 3n E2B + constrained decoding as the mid-tier fallback, accepting the ~2-3GB model footprint, and cloud-deferred extraction on low-end devices; whisper.cpp (or ONNX Runtime Mobile Whisper) for ASR; Room + sqlite-vec for local RAG; WorkManager sync queue. Shared: schema-first report templates (JSON Schema source of truth compiled to @Generable structs and Kotlin data classes), offline-first store with CRDT-ish merge on sync, and CSV/PDF/Spectora-importable export formats.

---

*Generated 2026-06-10 from a multi-agent research pipeline: 5 live-web research agents (Apple/Android platform state, market data, consumer trends, competitive landscape), 3-lens ideation, ruthless shortlist, then per-candidate monetization analyst + adversarial skeptic. Market figures are agent-researched estimates — verify before committing capital.*
