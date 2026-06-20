# SiteScribe

[![CI](https://github.com/asmuelle/sitescribe/actions/workflows/ci.yml/badge.svg)](https://github.com/asmuelle/sitescribe/actions/workflows/ci.yml)

> Offline AI field-documentation copilot: photograph, dictate, and auto-generate structured inspection reports, receipts, and job records at zero signal, syncing when coverage returns.

**Category:** Edge AI / on-device inference (iOS + Android) ·
## Concept

Offline AI field-documentation copilot: photograph, dictate, and auto-generate structured inspection reports, receipts, and job records at zero signal, syncing when coverage returns.

## Target User

Home/building inspectors, insurance adjusters, utility and telecom field techs, and solo trade contractors — workers whose sites (basements, rural routes, industrial buildings) are dark zones for entire shifts and who bill by the completed report. Solo-contractor receipt/invoice capture is the bottom-up wedge into firms.

## Why Edge AI Is Structural (not decoration)

AFM 3 image input + OCRTool + BarcodeReaderTool read equipment tags, serial plates, meter values, and receipts from photos; @Generable fills the user's report schema (defect, location, severity, recommended action) deterministically; whisper.cpp transcribes walk-through voice notes offline; Spotlight local RAG answers 'what did I flag at this property last visit?' across past reports and scanned documents. Android parity via Gemma 4 E2B structured output in the AICore Developer Preview. Essential: 30% of frontline workers explicitly expect offline-capable apps — every cloud copilot returns a spinner exactly when the work happens, and unlimited daily extraction is free on-device where cloud-vision rivals bleed margin.

## Why Now (2026 timing)

Mobile document scanning + local LLM structured extraction has 'no polished commercial player' (only OSS hobby apps), and field ops/OCR is cited as the strongest near-term on-device use case; @Generable, OCRTool, and local RAG all shipped as free system primitives at WWDC26 — assembly cost just collapsed for whoever moves first.


## Tech Stack

iOS (Swift/SwiftUI, iOS 26 floor with iOS 27 fast-follow): VisionKit DataScannerViewController + Vision RecognizeDocumentsRequest as the universal OCR/barcode path (works on all recent iPhones); FoundationModels @Generable guided generation against the user's report schema, using AFM 3 Core (text) everywhere and AFM 3 Core Advanced + OCRTool/BarcodeReaderTool only on capable devices; SpeechAnalyzer/SpeechTranscriber for offline dictation with whisper.cpp (large-v3-turbo, Metal) as fallback on older devices; NLContextualEmbedding + GRDB/SQLite with sqlite-vec for local RAG over past reports; BGTaskScheduler sync queue with an optional cloud polish pass (Claude Haiku-class or Gemini Flash via Foundation Models' new third-party adapter) on reconnect; PDFKit for report output. Android (Kotlin/Jetpack Compose): ML Kit Document Scanner + Text Recognition v2 for OCR (runs on ALL devices, no AICore dependency — this is the load-bearing choice); ML Kit GenAI Prompt API with structured output on Gemini Nano-capable flagships; MediaPipe LLM Inference API (LiteRT) with bundled Gemma 3n E2B + constrained decoding as the mid-tier fallback, accepting the ~2-3GB model footprint, and cloud-deferred extraction on low-end devices; whisper.cpp (or ONNX Runtime Mobile Whisper) for ASR; Room + sqlite-vec for local RAG; WorkManager sync queue. Shared: schema-first report templates (JSON Schema source of truth compiled to @Generable structs and Kotlin data classes), offline-first store with CRDT-ish merge on sync, and CSV/PDF/Spectora-importable export formats.

