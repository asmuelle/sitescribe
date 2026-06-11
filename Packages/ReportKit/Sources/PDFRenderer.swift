#if canImport(CoreGraphics) && canImport(CoreText)
    import CoreGraphics
    import CoreText
    import Foundation

    public enum PDFRenderError: Error, Equatable, Sendable {
        case contextCreationFailed
        case emptyReport
    }

    /// Renders a report to PDF using CoreGraphics + CoreText directly so the
    /// same code path runs on iOS and in `swift test` on macOS. Pure function:
    /// report in, PDF data out. Layout is the paper-white editorial direction
    /// from DESIGN.md — captured values render in monospace.
    public struct PDFRenderer: Sendable {
        private enum Layout {
            static let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
            static let margin: CGFloat = 48
            static let titleSize: CGFloat = 24
            static let sectionSize: CGFloat = 15
            static let bodySize: CGFloat = 11
            static let lineGap: CGFloat = 6
        }

        public init() {}

        public func render(report: Report, template: ReportTemplate) throws -> Data {
            guard !report.fields.isEmpty else { throw PDFRenderError.emptyReport }
            let data = NSMutableData()
            guard let consumer = CGDataConsumer(data: data as CFMutableData),
                  let context = CGContext(consumer: consumer, mediaBox: nil, nil)
            else {
                throw PDFRenderError.contextCreationFailed
            }
            var cursor = Cursor(context: context, pageRect: Layout.pageSize, margin: Layout.margin)
            cursor.beginPage()
            cursor.draw(line: template.name, fontSize: Layout.titleSize, bold: true)
            cursor.draw(
                line: "Status: \(report.status.rawValue)  ·  Template v\(report.templateVersion)",
                fontSize: Layout.bodySize,
                bold: false
            )
            cursor.advance(by: Layout.lineGap * 2)
            for section in template.sections {
                drawSection(section, of: report, into: &cursor)
            }
            cursor.endPage()
            context.closePDF()
            return data as Data
        }

        private func drawSection(_ section: TemplateSection, of report: Report, into cursor: inout Cursor) {
            let fields = report.fields(inSection: section.id)
            guard !fields.isEmpty else { return }
            cursor.advance(by: Layout.lineGap)
            cursor.draw(line: section.title, fontSize: Layout.sectionSize, bold: true)
            for field in fields {
                let label = "\(field.schemaKeyPath)  [\(field.source.rawValue), \(field.reviewState.rawValue)]"
                cursor.draw(line: label, fontSize: Layout.bodySize - 2, bold: false)
                cursor.draw(line: field.value, fontSize: Layout.bodySize, bold: false, monospaced: true)
                cursor.advance(by: Layout.lineGap)
            }
        }
    }

    /// Tracks the drawing position and paginates. CoreText draws bottom-up, so
    /// the cursor converts from a top-down y offset.
    private struct Cursor {
        let context: CGContext
        let pageRect: CGRect
        let margin: CGFloat
        private var y: CGFloat = 0
        private var pageOpen = false

        init(context: CGContext, pageRect: CGRect, margin: CGFloat) {
            self.context = context
            self.pageRect = pageRect
            self.margin = margin
        }

        mutating func beginPage() {
            context.beginPDFPage(nil)
            pageOpen = true
            y = margin
        }

        mutating func endPage() {
            guard pageOpen else { return }
            context.endPDFPage()
            pageOpen = false
        }

        mutating func advance(by amount: CGFloat) {
            y += amount
        }

        mutating func draw(line: String, fontSize: CGFloat, bold: Bool, monospaced: Bool = false) {
            let lineHeight = fontSize * 1.4
            if y + lineHeight > pageRect.height - margin {
                endPage()
                beginPage()
            }
            let font = makeFont(size: fontSize, bold: bold, monospaced: monospaced)
            let attributes: [CFString: Any] = [kCTFontAttributeName: font]
            let attributed = CFAttributedStringCreate(nil, line as CFString, attributes as CFDictionary)!
            let ctLine = CTLineCreateWithAttributedString(attributed)
            context.textPosition = CGPoint(x: margin, y: pageRect.height - y - fontSize)
            CTLineDraw(ctLine, context)
            y += lineHeight
        }

        private func makeFont(size: CGFloat, bold: Bool, monospaced: Bool) -> CTFont {
            if monospaced {
                return CTFontCreateUIFontForLanguage(.userFixedPitch, size, nil)
                    ?? CTFontCreateWithName("Menlo" as CFString, size, nil)
            }
            let base = CTFontCreateUIFontForLanguage(.system, size, nil)
                ?? CTFontCreateWithName("Helvetica" as CFString, size, nil)
            guard bold else { return base }
            return CTFontCreateCopyWithSymbolicTraits(base, size, nil, .traitBold, .traitBold) ?? base
        }
    }
#endif
