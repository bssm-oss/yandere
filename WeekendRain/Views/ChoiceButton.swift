import AppKit

open class ChoiceButton: NSButton {
    public var representedChoiceID: String?

    private var tracking: NSTrackingArea?
    private var hovering = false

    public convenience init(title: String, choiceID: String?) {
        self.init(frame: .zero)
        self.representedChoiceID = choiceID
        setDisplayTitle(title)
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    open override var acceptsFirstResponder: Bool { true }

    open override var intrinsicContentSize: NSSize {
        let availableWidth = max(bounds.width - 10, 120)
        let rect = attributedTitle.boundingRect(
            with: NSSize(width: availableWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        return NSSize(width: NSView.noIntrinsicMetric, height: max(36, ceil(rect.height) + 8))
    }

    open override func layout() {
        super.layout()
        invalidateIntrinsicContentSize()
    }

    open override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking {
            removeTrackingArea(tracking)
        }

        tracking = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self
        )

        if let tracking {
            addTrackingArea(tracking)
        }
    }

    open override func mouseEntered(with event: NSEvent) {
        hovering = true
        updateAppearance()
    }

    open override func mouseExited(with event: NSEvent) {
        hovering = false
        updateAppearance()
    }

    open override func becomeFirstResponder() -> Bool {
        let became = super.becomeFirstResponder()
        updateAppearance()
        return became
    }

    open override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        updateAppearance()
        return resigned
    }

    public func setDisplayTitle(_ title: String) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byWordWrapping

        attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraph
            ]
        )
        cell?.lineBreakMode = .byWordWrapping
        (cell as? NSButtonCell)?.wraps = true
        invalidateIntrinsicContentSize()
    }

    private func configure() {
        isBordered = false
        bezelStyle = .regularSquare
        alignment = .left
        imagePosition = .noImage
        wantsLayer = true
        focusRingType = .none
        setButtonType(.momentaryPushIn)
        contentTintColor = .white
        updateAppearance()
    }

    private func updateAppearance() {
        wantsLayer = true
        layer?.cornerRadius = 5
        layer?.masksToBounds = false
        layer?.backgroundColor = hovering
            ? NSColor.white.withAlphaComponent(0.20).cgColor
            : NSColor.black.withAlphaComponent(0.36).cgColor
        layer?.borderWidth = window?.firstResponder === self ? 2 : 1
        layer?.borderColor = hovering
            ? NSColor.systemRed.withAlphaComponent(0.62).cgColor
            : NSColor.white.withAlphaComponent(0.18).cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = hovering ? 0.24 : 0.12
        layer?.shadowRadius = hovering ? 18 : 8
        layer?.shadowOffset = CGSize(width: 0, height: 8)
    }
}
