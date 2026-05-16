import AppKit
import QuartzCore

open class ChoiceButton: NSButton {
    public var representedChoiceID: String?

    private var tracking: NSTrackingArea?
    private var hovering = false
    private let accentBar = CALayer()
    private let glowLayer = CALayer()

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
        let leftPad: CGFloat = 52
        let rightPad: CGFloat = 24
        let availableWidth = max(bounds.width - leftPad - rightPad, 200)
        let rect = attributedTitle.boundingRect(
            with: NSSize(width: availableWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        return NSSize(width: NSView.noIntrinsicMetric, height: max(46, ceil(rect.height) + 18))
    }

    open override func layout() {
        super.layout()
        invalidateIntrinsicContentSize()
        updateLayerFrames()
    }

    open override func updateTrackingAreas() {
        super.updateTrackingAreas()
        tracking.map { removeTrackingArea($0) }
        let t = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self
        )
        addTrackingArea(t)
        tracking = t
    }

    open override func mouseEntered(with event: NSEvent) {
        hovering = true
        updateAppearance(animated: true)
    }

    open override func mouseExited(with event: NSEvent) {
        hovering = false
        updateAppearance(animated: true)
    }

    open override func becomeFirstResponder() -> Bool {
        let became = super.becomeFirstResponder()
        updateAppearance(animated: false)
        return became
    }

    open override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        updateAppearance(animated: false)
        return resigned
    }

    public func setDisplayTitle(_ title: String) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.firstLineHeadIndent = 50
        paragraph.headIndent = 50
        paragraph.tailIndent = -22

        attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: NSColor.white.withAlphaComponent(hovering ? 1.0 : 0.88),
                .paragraphStyle: paragraph,
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

        guard let layer else { return }

        glowLayer.cornerRadius = 8
        glowLayer.shadowColor = NSColor.systemRed.cgColor
        glowLayer.shadowOpacity = 0
        glowLayer.shadowRadius = 18
        glowLayer.shadowOffset = .zero
        glowLayer.backgroundColor = NSColor.clear.cgColor
        layer.addSublayer(glowLayer)

        accentBar.cornerRadius = 2
        accentBar.backgroundColor = NSColor.systemRed.withAlphaComponent(0.90).cgColor
        layer.addSublayer(accentBar)

        updateAppearance(animated: false)
    }

    private func updateLayerFrames() {
        guard let layer else { return }
        let h = bounds.height
        let w = bounds.width
        let barW: CGFloat = 4
        let barH: CGFloat = min(32, h - 20)
        let barY = (h - barH) / 2

        glowLayer.frame = layer.bounds
        accentBar.frame = CGRect(x: 18, y: barY, width: barW, height: barH)
        accentBar.position = CGPoint(x: 18 + barW / 2, y: h - barY - barH / 2)
        _ = w
    }

    private func updateAppearance(animated: Bool) {
        guard let layer else { return }

        let isActive = hovering || (window?.firstResponder === self)

        let bgColor: CGColor = isActive
            ? NSColor(calibratedRed: 0.52, green: 0.05, blue: 0.08, alpha: 0.78).cgColor
            : NSColor(calibratedRed: 0.03, green: 0.03, blue: 0.045, alpha: 0.82).cgColor

        let borderColor: CGColor = isActive
            ? NSColor.systemRed.withAlphaComponent(0.75).cgColor
            : NSColor.white.withAlphaComponent(0.18).cgColor

        let accentAlpha: CGFloat = isActive ? 1.0 : 0.55
        let glowOpacity: Float = isActive ? 0.40 : 0

        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.18)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
            layer.backgroundColor = bgColor
            layer.borderColor = borderColor
            accentBar.backgroundColor = NSColor.systemRed.withAlphaComponent(accentAlpha).cgColor
            glowLayer.shadowOpacity = glowOpacity
            CATransaction.commit()
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.backgroundColor = bgColor
            layer.borderColor = borderColor
            accentBar.backgroundColor = NSColor.systemRed.withAlphaComponent(accentAlpha).cgColor
            glowLayer.shadowOpacity = glowOpacity
            CATransaction.commit()
        }

        layer.cornerRadius = 8
        layer.masksToBounds = false
        layer.borderWidth = 1
        layer.shadowColor = NSColor.black.cgColor
        layer.shadowOpacity = 0.34
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 4)

        updateLayerFrames()

        // Update text color
        if let existing = attributedTitle.string as String?, !existing.isEmpty {
            setDisplayTitle(existing)
        }
    }

    // NSButton draws its cell inside contentRect - we need to inset for the accent bar
    open override var alignmentRectInsets: NSEdgeInsets {
        NSEdgeInsets(top: 0, left: 40, bottom: 0, right: 0)
    }
}
