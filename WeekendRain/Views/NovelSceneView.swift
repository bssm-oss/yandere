import AppKit

private final class SceneImageView: NSImageView {
    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }
}

open class NovelSceneView: NSView {
    public var onChoiceSelected: ((String) -> Void)?
    public var onAdvanceRequested: (() -> Void)?
    public var onLineFinished: (() -> Void)?
    public var onBacklogRequested: (() -> Void)?
    public var onGalleryRequested: (() -> Void)?
    public var onSaveRequested: (() -> Void)?
    public var onLoadRequested: (() -> Void)?

    public let rainView = SakuraRainView()

    private let titleLabel = NSTextField(labelWithString: "주말의 비")
    private let statLabel = NSTextField(labelWithString: "")
    private let speakerAccentBar = NSView()
    private let speakerLabel = NSTextField(labelWithString: "")
    private let dialogueLabel = NSTextField(wrappingLabelWithString: "")
    private let choiceStack = NSStackView()
    private let dialoguePanel = NSView()
    private let dialogueScrollView = NSScrollView()
    private let dialogueContentStack = NSStackView()
    private let controlStack = NSStackView()
    private let backgroundLayerView = NSView()
    private let backgroundImageView = SceneImageView()
    private let cgImageView = SceneImageView()
    private let characterImageView = SceneImageView()
    private let conversationEngine = ConversationEngine()

    private var currentScene: SceneNode?
    private var currentPhase: GameStatePhase = .loading
    private var isTyping = false

    open override var acceptsFirstResponder: Bool { true }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    public func render(
        scene: SceneNode,
        phase: GameStatePhase,
        stats: GameStats,
        choices: [ChoiceNode],
        assets: AssetManifest? = nil,
        contentBaseURL: URL? = nil
    ) {
        currentScene = scene
        currentPhase = phase
        speakerLabel.stringValue = scene.speaker
        statLabel.stringValue = "♥ \(stats.love)   ⚠ \(stats.yandere)   ◆ \(stats.sanity)"
        applyVisuals(for: scene, stats: stats, assets: assets, contentBaseURL: contentBaseURL)
        YandereLevelController.shared.update(stats: stats, sceneView: self, rainView: rainView)

        switch phase {
        case .presentingLine:
            isTyping = true
            renderChoices([], includeContinue: false)
            conversationEngine.start(text: scene.text)
        case .awaitingChoice:
            isTyping = false
            conversationEngine.stop()
            dialogueLabel.stringValue = scene.text
            renderChoices(choices, includeContinue: false)
        case .transitioning:
            isTyping = false
            conversationEngine.stop()
            dialogueLabel.stringValue = scene.text
            renderChoices([], includeContinue: scene.nextScene != nil)
        case .ending:
            isTyping = false
            conversationEngine.stop()
            dialogueLabel.stringValue = scene.text
            renderChoices([], includeContinue: false)
        case .loading, .backlog, .gallery:
            break
        }
    }

    private func configure() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        // Background layer
        backgroundLayerView.wantsLayer = true
        backgroundLayerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundLayerView)

        for iv in [backgroundImageView, cgImageView] as [SceneImageView] {
            iv.imageScaling = .scaleAxesIndependently
            iv.animates = true
            iv.setContentHuggingPriority(.defaultLow, for: .horizontal)
            iv.setContentHuggingPriority(.defaultLow, for: .vertical)
            iv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            iv.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            iv.translatesAutoresizingMaskIntoConstraints = false
        }
        backgroundLayerView.addSubview(backgroundImageView)
        cgImageView.alphaValue = 0
        addSubview(cgImageView)

        characterImageView.imageScaling = .scaleProportionallyUpOrDown
        characterImageView.animates = true
        characterImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        characterImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        characterImageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        characterImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        characterImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(characterImageView)

        rainView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rainView)

        // HUD — title + stats (top-left)
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.65)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        statLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        statLabel.textColor = NSColor.white.withAlphaComponent(0.42)
        statLabel.lineBreakMode = .byTruncatingTail
        statLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statLabel)

        // Control buttons (top-right)
        controlStack.orientation = .horizontal
        controlStack.spacing = 5
        controlStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        controlStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(controlStack)
        for (label, sel) in [
            ("백로그", #selector(backlogPressed)),
            ("CG", #selector(galleryPressed)),
            ("저장", #selector(savePressed)),
            ("불러오기", #selector(loadPressed)),
        ] as [(String, Selector)] {
            addControlButton(label, action: sel)
        }

        // Dialogue panel
        dialoguePanel.wantsLayer = true
        dialoguePanel.layer?.backgroundColor = NSColor(
            calibratedRed: 0.04, green: 0.04, blue: 0.06, alpha: 0.88
        ).cgColor
        dialoguePanel.layer?.cornerRadius = 14
        dialoguePanel.layer?.borderWidth = 1
        dialoguePanel.layer?.borderColor = NSColor.white.withAlphaComponent(0.10).cgColor
        dialoguePanel.layer?.shadowColor = NSColor.black.cgColor
        dialoguePanel.layer?.shadowOpacity = 0.55
        dialoguePanel.layer?.shadowRadius = 36
        dialoguePanel.layer?.shadowOffset = CGSize(width: 0, height: 18)
        dialoguePanel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dialoguePanel)
        dialoguePanel.addGestureRecognizer(
            NSClickGestureRecognizer(target: self, action: #selector(dialoguePanelClicked))
        )

        // Speaker name — left red accent bar + label
        speakerAccentBar.wantsLayer = true
        speakerAccentBar.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.80).cgColor
        speakerAccentBar.layer?.cornerRadius = 1.5
        speakerAccentBar.translatesAutoresizingMaskIntoConstraints = false
        dialoguePanel.addSubview(speakerAccentBar)

        speakerLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        speakerLabel.textColor = .white
        speakerLabel.lineBreakMode = .byTruncatingTail
        speakerLabel.translatesAutoresizingMaskIntoConstraints = false
        dialoguePanel.addSubview(speakerLabel)

        // Dialogue text scroll area
        dialogueLabel.font = NSFont.systemFont(ofSize: 15, weight: .regular)
        dialogueLabel.textColor = NSColor.white.withAlphaComponent(0.92)
        dialogueLabel.lineBreakMode = .byWordWrapping
        dialogueLabel.maximumNumberOfLines = 0
        dialogueLabel.translatesAutoresizingMaskIntoConstraints = false

        dialogueScrollView.translatesAutoresizingMaskIntoConstraints = false
        dialogueScrollView.drawsBackground = false
        dialogueScrollView.borderType = .noBorder
        dialogueScrollView.hasVerticalScroller = true
        dialogueScrollView.autohidesScrollers = true
        dialoguePanel.addSubview(dialogueScrollView)

        dialogueContentStack.orientation = .vertical
        dialogueContentStack.alignment = .leading
        dialogueContentStack.spacing = 6
        dialogueContentStack.edgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
        dialogueContentStack.translatesAutoresizingMaskIntoConstraints = false
        dialogueScrollView.documentView = dialogueContentStack
        dialogueContentStack.addArrangedSubview(dialogueLabel)

        // Choice buttons
        choiceStack.orientation = .vertical
        choiceStack.spacing = 4
        choiceStack.translatesAutoresizingMaskIntoConstraints = false
        dialoguePanel.addSubview(choiceStack)

        conversationEngine.onTextChanged = { [weak self] text in
            self?.dialogueLabel.stringValue = text
        }
        conversationEngine.onFinished = { [weak self] in
            self?.isTyping = false
            self?.onLineFinished?()
        }

        NSLayoutConstraint.activate([
            // Background fill
            backgroundLayerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundLayerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundLayerView.topAnchor.constraint(equalTo: topAnchor),
            backgroundLayerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            backgroundImageView.leadingAnchor.constraint(equalTo: backgroundLayerView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: backgroundLayerView.trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: backgroundLayerView.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: backgroundLayerView.bottomAnchor),

            cgImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cgImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cgImageView.topAnchor.constraint(equalTo: topAnchor),
            cgImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Character: centered with slight right bias, tall, small overlap into panel
            characterImageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 24),
            characterImageView.bottomAnchor.constraint(equalTo: dialoguePanel.topAnchor, constant: -8),
            characterImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.65),
            characterImageView.widthAnchor.constraint(equalTo: characterImageView.heightAnchor, multiplier: 0.52),

            // Rain overlay
            rainView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rainView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rainView.topAnchor.constraint(equalTo: topAnchor),
            rainView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // HUD top-left
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: controlStack.leadingAnchor, constant: -16),

            statLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            statLabel.trailingAnchor.constraint(lessThanOrEqualTo: controlStack.leadingAnchor, constant: -16),

            // Controls top-right
            controlStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            controlStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),

            // Dialogue panel — bottom, 28% of height
            dialoguePanel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dialoguePanel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            dialoguePanel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            dialoguePanel.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.28),

            // Speaker area
            speakerAccentBar.leadingAnchor.constraint(equalTo: dialoguePanel.leadingAnchor, constant: 18),
            speakerAccentBar.topAnchor.constraint(equalTo: dialoguePanel.topAnchor, constant: 14),
            speakerAccentBar.widthAnchor.constraint(equalToConstant: 3),
            speakerAccentBar.heightAnchor.constraint(equalToConstant: 18),

            speakerLabel.leadingAnchor.constraint(equalTo: speakerAccentBar.trailingAnchor, constant: 8),
            speakerLabel.centerYAnchor.constraint(equalTo: speakerAccentBar.centerYAnchor),
            speakerLabel.trailingAnchor.constraint(lessThanOrEqualTo: dialoguePanel.trailingAnchor, constant: -18),

            // Scroll area for dialogue text
            dialogueScrollView.leadingAnchor.constraint(equalTo: dialoguePanel.leadingAnchor, constant: 18),
            dialogueScrollView.trailingAnchor.constraint(equalTo: dialoguePanel.trailingAnchor, constant: -18),
            dialogueScrollView.topAnchor.constraint(equalTo: speakerAccentBar.bottomAnchor, constant: 8),
            dialogueScrollView.bottomAnchor.constraint(equalTo: choiceStack.topAnchor, constant: -6),

            dialogueContentStack.leadingAnchor.constraint(equalTo: dialogueScrollView.contentView.leadingAnchor),
            dialogueContentStack.trailingAnchor.constraint(equalTo: dialogueScrollView.contentView.trailingAnchor),
            dialogueContentStack.topAnchor.constraint(equalTo: dialogueScrollView.contentView.topAnchor),
            dialogueContentStack.bottomAnchor.constraint(equalTo: dialogueScrollView.contentView.bottomAnchor),
            dialogueContentStack.widthAnchor.constraint(equalTo: dialogueScrollView.contentView.widthAnchor),

            dialogueLabel.widthAnchor.constraint(equalTo: dialogueContentStack.widthAnchor),

            // Choices
            choiceStack.leadingAnchor.constraint(equalTo: dialogueScrollView.leadingAnchor),
            choiceStack.trailingAnchor.constraint(equalTo: dialogueScrollView.trailingAnchor),
            choiceStack.bottomAnchor.constraint(equalTo: dialoguePanel.bottomAnchor, constant: -12),
        ])
    }

    private func addControlButton(_ title: String, action: Selector) {
        let button = NovelControlButton(title: title)
        button.target = self
        button.action = action
        controlStack.addArrangedSubview(button)
    }

    private func renderChoices(_ choices: [ChoiceNode], includeContinue: Bool) {
        choiceStack.arrangedSubviews.forEach {
            choiceStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for choice in choices {
            let button = ChoiceButton(title: choice.text, choiceID: choice.id)
            button.target = self
            button.action = #selector(choicePressed(_:))
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
            choiceStack.addArrangedSubview(button)
        }

        if includeContinue {
            let button = ChoiceButton(title: "계속 ▶", choiceID: nil)
            button.target = self
            button.action = #selector(continuePressed)
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
            choiceStack.addArrangedSubview(button)
        }
    }

    private func applyVisuals(
        for scene: SceneNode,
        stats: GameStats,
        assets: AssetManifest?,
        contentBaseURL: URL?
    ) {
        let yandere = CGFloat(stats.yandere) / 100.0
        let showEventCG = scene.isEndingScene || scene.character == nil || scene.effects.contains("event_cg")

        let baseColor: NSColor
        switch scene.background {
        case "school_rooftop":      baseColor = NSColor(calibratedRed: 0.09, green: 0.13, blue: 0.18, alpha: 1)
        case "locked_room":         baseColor = NSColor(calibratedRed: 0.18, green: 0.12, blue: 0.12, alpha: 1)
        case "rain_street":         baseColor = NSColor(calibratedRed: 0.04, green: 0.05, blue: 0.09, alpha: 1)
        case "retro_arcade":        baseColor = NSColor(calibratedRed: 0.06, green: 0.04, blue: 0.08, alpha: 1)
        case "student_council_room":baseColor = NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.12, alpha: 1)
        case "underpass_rain":      baseColor = NSColor(calibratedRed: 0.03, green: 0.03, blue: 0.05, alpha: 1)
        case "locker_corridor":     baseColor = NSColor(calibratedRed: 0.13, green: 0.10, blue: 0.10, alpha: 1)
        case "abandoned_platform":  baseColor = NSColor(calibratedRed: 0.03, green: 0.06, blue: 0.10, alpha: 1)
        case "water_tower":         baseColor = NSColor(calibratedRed: 0.04, green: 0.09, blue: 0.12, alpha: 1)
        case "ai_kiosk":            baseColor = NSColor(calibratedRed: 0.02, green: 0.04, blue: 0.07, alpha: 1)
        case "mineral_aquarium":    baseColor = NSColor(calibratedRed: 0.00, green: 0.08, blue: 0.11, alpha: 1)
        case "old_library":         baseColor = NSColor(calibratedRed: 0.09, green: 0.07, blue: 0.05, alpha: 1)
        case "rain_shrine":         baseColor = NSColor(calibratedRed: 0.04, green: 0.06, blue: 0.05, alpha: 1)
        case "old_apartment":       baseColor = NSColor(calibratedRed: 0.10, green: 0.08, blue: 0.07, alpha: 1)
        case "water_lab":           baseColor = NSColor(calibratedRed: 0.02, green: 0.05, blue: 0.08, alpha: 1)
        default:                    baseColor = NSColor(calibratedRed: 0.06, green: 0.08, blue: 0.11, alpha: 1)
        }

        backgroundLayerView.layer?.backgroundColor = baseColor
            .blended(withFraction: yandere * 0.18, of: .systemRed)?.cgColor ?? baseColor.cgColor

        if let bgID = scene.background, let bgAsset = assets?.backgrounds[bgID] {
            backgroundImageView.image = VisualAssetRenderer.image(
                for: bgAsset, baseURL: contentBaseURL, role: .background
            )
            backgroundImageView.alphaValue = showEventCG ? 0.18 : 0.90
        } else {
            backgroundImageView.image = nil
        }

        if showEventCG, let cgID = scene.cg, let cgAsset = assets?.cg[cgID] {
            cgImageView.image = VisualAssetRenderer.image(for: cgAsset, baseURL: contentBaseURL, role: .cg)
            cgImageView.alphaValue = 0.92
            cgImageView.isHidden = false
        } else {
            cgImageView.image = nil
            cgImageView.alphaValue = 0
            cgImageView.isHidden = true
        }

        if !showEventCG, let charID = scene.character, let charAsset = assets?.characters[charID] {
            characterImageView.image = VisualAssetRenderer.image(
                for: charAsset, baseURL: contentBaseURL, role: .character
            )
            characterImageView.alphaValue = charID == "haru_reflection" ? 0.52 : 0.96
            characterImageView.isHidden = false
        } else {
            characterImageView.image = nil
            characterImageView.isHidden = true
        }
    }

    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    open override func mouseDown(with event: NSEvent) {
        requestAdvanceOrSkip()
    }

    open override func keyDown(with event: NSEvent) {
        switch event.charactersIgnoringModifiers {
        case " ", "\r", "\u{3}":
            requestAdvanceOrSkip()
        default:
            super.keyDown(with: event)
        }
    }

    private func requestAdvanceOrSkip() {
        if isTyping {
            conversationEngine.skip()
        } else if currentPhase == .transitioning {
            onAdvanceRequested?()
        }
    }

    @objc private func choicePressed(_ sender: ChoiceButton) {
        guard let id = sender.representedChoiceID else { return }
        onChoiceSelected?(id)
    }

    @objc private func continuePressed() {
        onAdvanceRequested?()
    }

    @objc private func dialoguePanelClicked() {
        requestAdvanceOrSkip()
    }

    @objc private func backlogPressed() { onBacklogRequested?() }
    @objc private func galleryPressed() { onGalleryRequested?() }
    @objc private func savePressed() { onSaveRequested?() }
    @objc private func loadPressed() { onLoadRequested?() }
}

// MARK: - NovelControlButton

private final class NovelControlButton: NSButton {
    private var tracking: NSTrackingArea?
    private var hovering = false

    init(title: String) {
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
        para.alignment = .center
        attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: NSColor.white.withAlphaComponent(0.65),
                .paragraphStyle: para,
            ]
        )

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 26),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 48),
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
        layer?.cornerRadius = 13
        layer?.backgroundColor = hovering
            ? NSColor.white.withAlphaComponent(0.14).cgColor
            : NSColor.white.withAlphaComponent(0.07).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(hovering ? 0.24 : 0.12).cgColor
    }
}
