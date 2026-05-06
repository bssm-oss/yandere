import AppKit
import QuartzCore

public final class TitleView: NSView {
    public var onNewGame: (() -> Void)?
    public var onLoadGame: (() -> Void)?
    public var onGallery: (() -> Void)?
    public var onQuit: (() -> Void)?

    public let rainView = SakuraRainView()

    private let dimView = NSView()
    private let titleLabel = NSTextField(labelWithString: "주말의 비")
    private let subtitleLabel = NSTextField(labelWithString: "Weekend Rain")
    private let accentLine = NSView()
    private let buttonStack = NSStackView()
    private let creditLabel = NSTextField(labelWithString: "BSSM Open Source Project  ·  2025")
    private var gradientInstalled = false

    public override init(frame: NSRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(calibratedRed: 0.03, green: 0.04, blue: 0.08, alpha: 1).cgColor

        dimView.wantsLayer = true
        dimView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dimView)

        rainView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rainView)

        titleLabel.font = NSFont.systemFont(ofSize: 68, weight: .ultraLight)
        titleLabel.textColor = .white
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        accentLine.wantsLayer = true
        accentLine.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.70).cgColor
        accentLine.layer?.cornerRadius = 1
        accentLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(accentLine)

        subtitleLabel.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = NSColor.white.withAlphaComponent(0.38)
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

        buttonStack.orientation = .vertical
        buttonStack.spacing = 4
        buttonStack.alignment = .leading
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(buttonStack)

        addMenuButton("새 게임 시작", isPrimary: true, action: #selector(newGamePressed))
        addMenuButton("게임 불러오기", isPrimary: false, action: #selector(loadPressed))
        addMenuButton("CG 갤러리", isPrimary: false, action: #selector(galleryPressed))
        addMenuButton("종료", isPrimary: false, action: #selector(quitPressed))

        creditLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        creditLabel.textColor = NSColor.white.withAlphaComponent(0.20)
        creditLabel.lineBreakMode = .byTruncatingTail
        creditLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(creditLabel)

        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            rainView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rainView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rainView.topAnchor.constraint(equalTo: topAnchor),
            rainView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 88),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -90),

            accentLine.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            accentLine.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            accentLine.widthAnchor.constraint(equalToConstant: 48),
            accentLine.heightAnchor.constraint(equalToConstant: 1.5),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: accentLine.bottomAnchor, constant: 14),

            buttonStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            buttonStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 48),

            creditLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            creditLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
        ])
    }

    public override func layout() {
        super.layout()
        installOrUpdateGradient()
    }

    private func installOrUpdateGradient() {
        if let existing = dimView.layer?.sublayers?.first as? CAGradientLayer {
            existing.frame = dimView.bounds
            return
        }
        let grad = CAGradientLayer()
        grad.frame = dimView.bounds
        grad.startPoint = CGPoint(x: 0, y: 0.5)
        grad.endPoint = CGPoint(x: 0.70, y: 0.5)
        grad.colors = [
            NSColor.black.withAlphaComponent(0.62).cgColor,
            NSColor.clear.cgColor,
        ]
        dimView.layer?.addSublayer(grad)
    }

    private func addMenuButton(_ title: String, isPrimary: Bool, action: Selector) {
        let btn = TitleMenuButton(title: title, isPrimary: isPrimary)
        btn.target = self
        btn.action = action
        buttonStack.addArrangedSubview(btn)
    }

    @objc private func newGamePressed() { onNewGame?() }
    @objc private func loadPressed() { onLoadGame?() }
    @objc private func galleryPressed() { onGallery?() }
    @objc private func quitPressed() { onQuit?() }
}

private final class TitleMenuButton: NSButton {
    private let isPrimary: Bool
    private var tracking: NSTrackingArea?
    private var hovering = false

    init(title: String, isPrimary: Bool) {
        self.isPrimary = isPrimary
        super.init(frame: .zero)
        configure(title: title)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configure(title: String) {
        isBordered = false
        bezelStyle = .regularSquare
        wantsLayer = true
        focusRingType = .none
        setButtonType(.momentaryPushIn)
        translatesAutoresizingMaskIntoConstraints = false

        let para = NSMutableParagraphStyle()
        para.alignment = .left
        attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.systemFont(
                    ofSize: isPrimary ? 16 : 14,
                    weight: isPrimary ? .regular : .light
                ),
                .foregroundColor: isPrimary
                    ? NSColor.white
                    : NSColor.white.withAlphaComponent(0.62),
                .paragraphStyle: para,
            ]
        )

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: isPrimary ? 50 : 44),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 216),
        ])
        updateAppearance()
    }

    override func updateTrackingAreas() {
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

    override func mouseEntered(with event: NSEvent) { hovering = true; updateAppearance() }
    override func mouseExited(with event: NSEvent) { hovering = false; updateAppearance() }

    private func updateAppearance() {
        layer?.cornerRadius = 5
        if isPrimary {
            layer?.backgroundColor = hovering
                ? NSColor.systemRed.withAlphaComponent(0.18).cgColor
                : NSColor.white.withAlphaComponent(0.04).cgColor
            layer?.borderWidth = 1
            layer?.borderColor = hovering
                ? NSColor.systemRed.withAlphaComponent(0.55).cgColor
                : NSColor.white.withAlphaComponent(0.20).cgColor
        } else {
            layer?.backgroundColor = hovering
                ? NSColor.white.withAlphaComponent(0.07).cgColor
                : NSColor.clear.cgColor
            layer?.borderWidth = 0
        }
    }
}
