import Foundation
import Testing
@testable import RecognitionKit

@Suite("Deterministic parsers (invariant 4: identifiers never come from a model)")
struct DeterministicParserTests {
    private func block(_ text: String) -> OCRBlock {
        OCRBlock(text: text, confidence: 0.9, region: nil)
    }

    @Test("Serial parser reads labeled serial numbers verbatim")
    func serialParserReadsLabeledSerials() {
        let parser = SerialNumberParser()

        let artifacts = parser.parse(block: block("SERIAL NO: 4517A23456"))

        #expect(artifacts.count == 1)
        #expect(artifacts.first?.rawValue == "4517A23456")
        #expect(artifacts.first?.normalizedValue == "4517A23456")
        #expect(artifacts.first?.kind == .serialNumber)
    }

    @Test(
        "Serial parser accepts the common label variants",
        arguments: [
            ("S/N Q341812345", "Q341812345"),
            ("SN 19-002211", "19-002211"),
            ("SERIAL # LC2201456789", "LC2201456789"),
            ("METER ID GM-558812", "GM-558812"),
        ]
    )
    func serialParserAcceptsLabelVariants(text: String, expected: String) {
        let artifacts = SerialNumberParser().parse(block: block(text))

        #expect(artifacts.map(\.normalizedValue) == [expected])
    }

    @Test("Serial parser ignores unlabeled alphanumeric noise")
    func serialParserIgnoresUnlabeledText() {
        let artifacts = SerialNumberParser().parse(block: block("FACTORY CHARGE R410A 6LB"))

        #expect(artifacts.isEmpty)
    }

    @Test("Model parser uppercases but never rewrites the value")
    func modelParserNormalizesCaseOnly() {
        let artifacts = ModelNumberParser().parse(block: block("model: 58sta070-12"))

        #expect(artifacts.map(\.rawValue) == ["58sta070-12"])
        #expect(artifacts.map(\.normalizedValue) == ["58STA070-12"])
    }

    @Test(
        "Meter parser canonicalizes units without touching digits",
        arguments: [
            ("READING 032451 CCF", "032451 CCF"),
            ("00482 m3", "00482 m³"),
            ("045210 kWh", "045210 kWh"),
            ("CAPACITY 40 GAL", "40 gal"),
        ]
    )
    func meterParserCanonicalizesUnits(text: String, expected: String) {
        let artifacts = MeterReadingParser().parse(block: block(text))

        #expect(artifacts.map(\.normalizedValue) == [expected])
    }

    @Test("Meter parser does not match bare numbers or unknown units")
    func meterParserRejectsUnknownUnits() {
        let artifacts = MeterReadingParser().parse(block: block("INPUT 70000 BTU"))

        #expect(artifacts.isEmpty)
    }

    @Test("Price parser requires an explicit dollar sign")
    func priceParserRequiresDollarSign() {
        let withSign = PriceParser().parse(block: block("TOTAL $1,249.50"))
        let withoutSign = PriceParser().parse(block: block("PVC CEMENT 8.99"))

        #expect(withSign.map(\.normalizedValue) == ["1249.50 USD"])
        #expect(withoutSign.isEmpty)
    }

    @Test(
        "Date parser normalizes ISO and US formats to ISO-8601",
        arguments: [
            ("DATE OF MFG 2014-03-18", "2014-03-18"),
            ("NEXT READ 12/31/2025", "2025-12-31"),
            ("04/02/2026", "2026-04-02"),
        ]
    )
    func dateParserNormalizesToISO(text: String, expected: String) {
        let artifacts = DateParser().parse(block: block(text))

        #expect(artifacts.map(\.normalizedValue) == [expected])
    }

    @Test("Date parser rejects impossible dates instead of guessing")
    func dateParserRejectsImpossibleDates() {
        let artifacts = DateParser().parse(block: block("13/45/2025 and 2025-19-99"))

        #expect(artifacts.isEmpty)
    }

    @Test("Voltage markings are not misread as dates")
    func voltageIsNotADate() {
        let artifacts = DateParser().parse(block: block("100A 120/240V 1PH 3W"))

        #expect(artifacts.isEmpty)
    }

    @Test("Artifacts inherit the block's confidence and region")
    func artifactsInheritBlockProvenance() {
        let region = TextRegion(x: 0, y: 0.5, width: 1, height: 0.1)
        let source = OCRBlock(text: "SN AB-12345", confidence: 0.42, region: region)

        let artifacts = SerialNumberParser().parse(block: source)

        #expect(artifacts.first?.confidence == 0.42)
        #expect(artifacts.first?.region == region)
    }
}
