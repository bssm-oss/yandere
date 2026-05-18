import AppKit
import QuartzCore

private final class SceneImageView: NSImageView {
    var usesAspectFill = false { didSet { needsDisplay = true } }
    var usesSpritePlacement = false { didSet { needsDisplay = true } }
    var spriteHeightMultiplier: CGFloat = 0.72 { didSet { needsDisplay = true } }
    var spriteCenterXMultiplier: CGFloat = 0.60 { didSet { needsDisplay = true } }
    var spriteBottomMultiplier: CGFloat = 0.03 { didSet { needsDisplay = true } }
    var spriteMaxWidthMultiplier: CGFloat = 0.58 { didSet { needsDisplay = true } }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }

    override func draw(_ dirtyRect: NSRect) {
        if usesSpritePlacement, let image, image.size.width > 0, image.size.height > 0 {
            drawSprite(image)
            return
        }

        guard usesAspectFill, let image, image.size.width > 0, image.size.height > 0 else {
            super.draw(dirtyRect)
            return
        }

        NSGraphicsContext.current?.imageInterpolation = .high
        let scale = max(bounds.width / image.size.width, bounds.height / image.size.height)
        let drawSize = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        let drawRect = NSRect(
            x: bounds.midX - drawSize.width / 2,
            y: bounds.midY - drawSize.height / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        image.draw(
            in: drawRect,
            from: NSRect(origin: .zero, size: image.size),
            operation: .sourceOver,
            fraction: 1.0,
            respectFlipped: true,
            hints: [.interpolation: NSImageInterpolation.high]
        )
    }

    private func drawSprite(_ image: NSImage) {
        NSGraphicsContext.current?.imageInterpolation = .high
        let targetHeight = bounds.height * spriteHeightMultiplier
        let maxWidth = bounds.width * spriteMaxWidthMultiplier
        var scale = targetHeight / image.size.height
        if image.size.width * scale > maxWidth {
            scale = maxWidth / image.size.width
        }

        let drawSize = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        let requestedX = bounds.width * spriteCenterXMultiplier - drawSize.width / 2
        let horizontalInset = bounds.width * 0.03
        let minX = horizontalInset
        let maxX = bounds.width - drawSize.width - horizontalInset
        let clampedX = maxX > minX ? min(max(requestedX, minX), maxX) : requestedX

        let drawRect = NSRect(
            x: clampedX,
            y: bounds.height * spriteBottomMultiplier,
            width: drawSize.width,
            height: drawSize.height
        )
        image.draw(
            in: drawRect,
            from: NSRect(origin: .zero, size: image.size),
            operation: .sourceOver,
            fraction: 1.0,
            respectFlipped: true,
            hints: [.interpolation: NSImageInterpolation.high]
        )
    }
}

private struct SpritePlacement {
    let height: CGFloat
    let centerX: CGFloat
    let bottom: CGFloat
    let maxWidth: CGFloat
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

    // Background
    private let backgroundLayerView = NSView()
    private let backgroundImageView = SceneImageView()
    private let cgImageView = SceneImageView()
    private let characterStageView = NSView()
    private var characterImageViews: [SceneVisualPosition: SceneImageView] = [:]
    private let characterPositions: [SceneVisualPosition] = [.left, .center, .right]

    // HUD (top)
    private let titleLabel = NSTextField(labelWithString: "주말의 비")
    private let statLabel = NSTextField(labelWithString: "")
    private let controlStack = NSStackView()

    // Dialogue panel — frosted glass (NSVisualEffectView)
    private let dialogueEffect = NSVisualEffectView()
    private let speakerAccentBar = NSView()
    private let speakerLabel = NSTextField(labelWithString: "")
    private let dialogueLabel = NSTextField(wrappingLabelWithString: "")
    private let dialogueScrollView = NSScrollView()
    private let dialogueContentStack = NSStackView()
    private let advanceIndicator = NSTextField(labelWithString: "▼")

    // Choice overlay — full-screen, shown over scene when choices available
    private let choiceOverlay = NSView()
    private let choicePanel = NSVisualEffectView()
    private let choiceHeaderLabel = NSTextField(labelWithString: "")
    private let choiceMoodLabel = NSTextField(labelWithString: "")
    private let choiceContentStack = NSStackView()
    private let choiceStack = NSStackView()

    private let conversationEngine = ConversationEngine()
    private var currentScene: SceneNode?
    private var currentPhase: GameStatePhase = .loading
    private var currentChoiceCount = 0
    private var dialoguePages: [String] = []
    private var dialoguePageIndex = 0
    private var isTyping = false
    private var blinkTimer: Timer?
    private var visibleChoiceButtons: [ChoiceButton] = []
    private var baseSpritePlacements: [SceneVisualPosition: SpritePlacement] = [:]
    private var currentCharacterIDs: [SceneVisualPosition: String] = [:]
    private var lastBackgroundID: String?

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
        currentChoiceCount = choices.count
        speakerLabel.stringValue = scene.speaker
        statLabel.stringValue = ""
        applyVisuals(for: scene, stats: stats, assets: assets, contentBaseURL: contentBaseURL)
        YandereLevelController.shared.update(stats: stats, sceneView: self, rainView: rainView)

        switch phase {
        case .presentingLine:
            dialoguePages = Self.paginateDialogue(scene.text)
            dialoguePageIndex = 0
            stopAdvancePulse()
            showChoiceOverlay(false, animated: false)
            startCurrentDialoguePage()

        case .awaitingChoice:
            isTyping = false
            conversationEngine.stop()
            dialogueLabel.stringValue = dialoguePages.last ?? scene.text
            stopAdvancePulse()
            choiceHeaderLabel.stringValue = scene.decisionTitle ?? "결정의 순간"
            choiceMoodLabel.stringValue = choiceMoodText(for: stats)
            populateChoices(choices)
            showChoiceOverlay(true, animated: true)

        case .transitioning:
            isTyping = false
            conversationEngine.stop()
            dialogueLabel.stringValue = scene.text
            showChoiceOverlay(false, animated: false)
            if scene.nextScene != nil { startAdvancePulse() } else { stopAdvancePulse() }

        case .ending:
            isTyping = false
            conversationEngine.stop()
            dialogueLabel.stringValue = scene.text
            showChoiceOverlay(false, animated: false)
            stopAdvancePulse()

        case .loading, .backlog, .gallery:
            break
        }
    }

    // MARK: - Configure

    private func configure() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        // ── Background ───────────────────────────────────────────────
        backgroundLayerView.wantsLayer = true
        backgroundLayerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundLayerView)

        backgroundImageView.usesAspectFill = true
        cgImageView.usesAspectFill = true

        for iv in [backgroundImageView, cgImageView] as [SceneImageView] {
            iv.imageScaling = .scaleNone
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

        characterStageView.wantsLayer = true
        characterStageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(characterStageView)
        configureCharacterStage()

        rainView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rainView)

        // ── HUD (top) ────────────────────────────────────────────────
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.55)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        statLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        statLabel.textColor = NSColor.white.withAlphaComponent(0.38)
        statLabel.lineBreakMode = .byTruncatingTail
        statLabel.isHidden = true
        statLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statLabel)

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
            let btn = NovelControlButton(title: label)
            btn.target = self
            btn.action = sel
            controlStack.addArrangedSubview(btn)
        }

        // ── Dialogue panel (NSVisualEffectView) ──────────────────────
        dialogueEffect.blendingMode = .withinWindow
        dialogueEffect.state = .active
        dialogueEffect.material = .hudWindow
        dialogueEffect.wantsLayer = true
        dialogueEffect.layer?.cornerRadius = 14
        dialogueEffect.layer?.masksToBounds = true
        dialogueEffect.layer?.borderWidth = 1
        dialogueEffect.layer?.borderColor = NSColor.white.withAlphaComponent(0.10).cgColor
        dialogueEffect.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dialogueEffect)

        speakerAccentBar.wantsLayer = true
        speakerAccentBar.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.85).cgColor
        speakerAccentBar.layer?.cornerRadius = 1.5
        speakerAccentBar.translatesAutoresizingMaskIntoConstraints = false
        dialogueEffect.addSubview(speakerAccentBar)

        speakerLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        speakerLabel.textColor = .white
        speakerLabel.lineBreakMode = .byTruncatingTail
        speakerLabel.translatesAutoresizingMaskIntoConstraints = false
        dialogueEffect.addSubview(speakerLabel)

        dialogueLabel.font = NSFont.systemFont(ofSize: 17, weight: .light)
        dialogueLabel.textColor = NSColor.white.withAlphaComponent(0.94)
        dialogueLabel.lineBreakMode = .byWordWrapping
        dialogueLabel.maximumNumberOfLines = 3
        dialogueLabel.translatesAutoresizingMaskIntoConstraints = false

        dialogueScrollView.translatesAutoresizingMaskIntoConstraints = false
        dialogueScrollView.drawsBackground = false
        dialogueScrollView.borderType = .noBorder
        dialogueScrollView.hasVerticalScroller = false
        dialogueScrollView.autohidesScrollers = true
        dialogueEffect.addSubview(dialogueScrollView)

        dialogueContentStack.orientation = .vertical
        dialogueContentStack.alignment = .leading
        dialogueContentStack.spacing = 0
        dialogueContentStack.translatesAutoresizingMaskIntoConstraints = false
        dialogueScrollView.documentView = dialogueContentStack
        dialogueContentStack.addArrangedSubview(dialogueLabel)

        advanceIndicator.font = NSFont.systemFont(ofSize: 11, weight: .light)
        advanceIndicator.textColor = NSColor.white.withAlphaComponent(0.70)
        advanceIndicator.isHidden = true
        advanceIndicator.translatesAutoresizingMaskIntoConstraints = false
        dialogueEffect.addSubview(advanceIndicator)

        conversationEngine.onTextChanged = { [weak self] text in
            self?.dialogueLabel.stringValue = text
        }
        conversationEngine.onFinished = { [weak self] in
            guard let self else { return }
            self.isTyping = false
            if self.currentPhase == .presentingLine {
                self.startAdvancePulse()
            }
        }

        // ── Choice overlay ───────────────────────────────────────────
        choiceOverlay.wantsLayer = true
        choiceOverlay.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.22).cgColor
        choiceOverlay.alphaValue = 0
        choiceOverlay.isHidden = true
        choiceOverlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(choiceOverlay)

        choicePanel.blendingMode = .withinWindow
        choicePanel.state = .active
        choicePanel.material = .hudWindow
        choicePanel.wantsLayer = true
        choicePanel.layer?.cornerRadius = 12
        choicePanel.layer?.masksToBounds = true
        choicePanel.layer?.borderWidth = 1
        choicePanel.layer?.borderColor = NSColor.white.withAlphaComponent(0.14).cgColor
        choicePanel.translatesAutoresizingMaskIntoConstraints = false
        choiceOverlay.addSubview(choicePanel)

        choiceHeaderLabel.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        choiceHeaderLabel.textColor = NSColor.white.withAlphaComponent(0.92)
        choiceHeaderLabel.alignment = .center
        choiceHeaderLabel.lineBreakMode = .byWordWrapping
        choiceHeaderLabel.maximumNumberOfLines = 2
        choiceHeaderLabel.translatesAutoresizingMaskIntoConstraints = false

        choiceMoodLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        choiceMoodLabel.textColor = NSColor.white.withAlphaComponent(0.50)
        choiceMoodLabel.alignment = .center
        choiceMoodLabel.lineBreakMode = .byWordWrapping
        choiceMoodLabel.maximumNumberOfLines = 2
        choiceMoodLabel.translatesAutoresizingMaskIntoConstraints = false

        choiceContentStack.orientation = .vertical
        choiceContentStack.spacing = 10
        choiceContentStack.alignment = .centerX
        choiceContentStack.translatesAutoresizingMaskIntoConstraints = false
        choicePanel.addSubview(choiceContentStack)
        choiceContentStack.addArrangedSubview(choiceHeaderLabel)
        choiceContentStack.addArrangedSubview(choiceMoodLabel)

        choiceStack.orientation = .vertical
        choiceStack.spacing = 8
        choiceStack.alignment = .centerX
        choiceStack.translatesAutoresizingMaskIntoConstraints = false
        choiceContentStack.addArrangedSubview(choiceStack)

        setupConstraints()
    }

    private func configureCharacterStage() {
        for position in characterPositions {
            let imageView = SceneImageView()
            imageView.usesSpritePlacement = true
            imageView.imageScaling = .scaleNone
            imageView.animates = true
            imageView.alphaValue = 0
            imageView.isHidden = true
            imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
            imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            characterStageView.addSubview(imageView)
            characterImageViews[position] = imageView
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: characterStageView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: characterStageView.trailingAnchor),
                imageView.topAnchor.constraint(equalTo: characterStageView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: characterStageView.bottomAnchor),
            ])
        }
    }

    private func setupConstraints() {
        let choicePanelWidth = choicePanel.widthAnchor.constraint(equalTo: choiceOverlay.widthAnchor, multiplier: 0.46)
        choicePanelWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            // Background
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

            // Character stage: full-scene canvas so sprites keep natural visual scale.
            characterStageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            characterStageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            characterStageView.topAnchor.constraint(equalTo: topAnchor),
            characterStageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            rainView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rainView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rainView.topAnchor.constraint(equalTo: topAnchor),
            rainView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // HUD
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: controlStack.leadingAnchor, constant: -16),

            statLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),

            controlStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            controlStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),

            // Dialogue panel: compact VN box, not a document reader.
            dialogueEffect.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dialogueEffect.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            dialogueEffect.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            dialogueEffect.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.25),

            speakerAccentBar.leadingAnchor.constraint(equalTo: dialogueEffect.leadingAnchor, constant: 20),
            speakerAccentBar.topAnchor.constraint(equalTo: dialogueEffect.topAnchor, constant: 16),
            speakerAccentBar.widthAnchor.constraint(equalToConstant: 3),
            speakerAccentBar.heightAnchor.constraint(equalToConstant: 18),

            speakerLabel.leadingAnchor.constraint(equalTo: speakerAccentBar.trailingAnchor, constant: 8),
            speakerLabel.centerYAnchor.constraint(equalTo: speakerAccentBar.centerYAnchor),
            speakerLabel.trailingAnchor.constraint(lessThanOrEqualTo: dialogueEffect.trailingAnchor, constant: -20),

            dialogueScrollView.leadingAnchor.constraint(equalTo: dialogueEffect.leadingAnchor, constant: 20),
            dialogueScrollView.trailingAnchor.constraint(equalTo: dialogueEffect.trailingAnchor, constant: -20),
            dialogueScrollView.topAnchor.constraint(equalTo: speakerAccentBar.bottomAnchor, constant: 10),
            dialogueScrollView.bottomAnchor.constraint(equalTo: dialogueEffect.bottomAnchor, constant: -16),

            dialogueContentStack.leadingAnchor.constraint(equalTo: dialogueScrollView.contentView.leadingAnchor),
            dialogueContentStack.trailingAnchor.constraint(equalTo: dialogueScrollView.contentView.trailingAnchor),
            dialogueContentStack.topAnchor.constraint(equalTo: dialogueScrollView.contentView.topAnchor),
            dialogueContentStack.bottomAnchor.constraint(equalTo: dialogueScrollView.contentView.bottomAnchor),
            dialogueContentStack.widthAnchor.constraint(equalTo: dialogueScrollView.contentView.widthAnchor),
            dialogueLabel.widthAnchor.constraint(equalTo: dialogueContentStack.widthAnchor),

            advanceIndicator.trailingAnchor.constraint(equalTo: dialogueEffect.trailingAnchor, constant: -20),
            advanceIndicator.bottomAnchor.constraint(equalTo: dialogueEffect.bottomAnchor, constant: -14),

            // Choice overlay: fills full scene
            choiceOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            choiceOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            choiceOverlay.topAnchor.constraint(equalTo: topAnchor),
            choiceOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),

            choicePanel.centerYAnchor.constraint(equalTo: choiceOverlay.centerYAnchor, constant: 24),
            choicePanel.leadingAnchor.constraint(greaterThanOrEqualTo: choiceOverlay.leadingAnchor, constant: 20),
            choicePanel.trailingAnchor.constraint(equalTo: choiceOverlay.trailingAnchor, constant: -34),
            choicePanel.widthAnchor.constraint(lessThanOrEqualToConstant: 520),
            choicePanelWidth,

            choiceContentStack.leadingAnchor.constraint(equalTo: choicePanel.leadingAnchor, constant: 18),
            choiceContentStack.trailingAnchor.constraint(equalTo: choicePanel.trailingAnchor, constant: -18),
            choiceContentStack.topAnchor.constraint(equalTo: choicePanel.topAnchor, constant: 16),
            choiceContentStack.bottomAnchor.constraint(equalTo: choicePanel.bottomAnchor, constant: -16),

            choiceHeaderLabel.widthAnchor.constraint(equalTo: choiceContentStack.widthAnchor),
            choiceMoodLabel.widthAnchor.constraint(equalTo: choiceContentStack.widthAnchor),
            choiceStack.widthAnchor.constraint(equalTo: choiceContentStack.widthAnchor),
        ])
    }

    // MARK: - Choice management

    private func populateChoices(_ choices: [ChoiceNode]) {
        choiceStack.arrangedSubviews.forEach {
            choiceStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        visibleChoiceButtons = []
        for (index, choice) in choices.enumerated() {
            let btn = ChoiceButton(title: String(format: "%02d  %@", index + 1, choice.text), choiceID: choice.id)
            btn.target = self
            btn.action = #selector(choicePressed(_:))
            choiceStack.addArrangedSubview(btn)
            visibleChoiceButtons.append(btn)
            btn.widthAnchor.constraint(equalTo: choiceStack.widthAnchor).isActive = true
        }
    }

    private func showChoiceOverlay(_ show: Bool, animated: Bool) {
        updateCharacterPlacement(forChoiceOverlay: show)
        if show {
            choiceOverlay.isHidden = false
            if animated {
                layoutSubtreeIfNeeded()
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.28
                    choiceOverlay.animator().alphaValue = 1.0
                    dialogueEffect.animator().alphaValue = 0.0
                    animator().layoutSubtreeIfNeeded()
                }
            } else {
                choiceOverlay.alphaValue = 1.0
                dialogueEffect.alphaValue = 0.0
                layoutSubtreeIfNeeded()
            }
        } else {
            if animated {
                layoutSubtreeIfNeeded()
                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration = 0.20
                    choiceOverlay.animator().alphaValue = 0
                    dialogueEffect.animator().alphaValue = 1.0
                    animator().layoutSubtreeIfNeeded()
                }) { [weak self] in
                    self?.choiceOverlay.isHidden = true
                }
            } else {
                choiceOverlay.alphaValue = 0
                choiceOverlay.isHidden = true
                dialogueEffect.alphaValue = 1.0
                layoutSubtreeIfNeeded()
            }
        }
    }

    private func updateCharacterPlacement(forChoiceOverlay show: Bool) {
        for position in characterPositions {
            guard let imageView = characterImageViews[position] else { continue }
            let base = baseSpritePlacements[position] ?? SpritePlacement(
                height: 0.72,
                centerX: centerX(for: position),
                bottom: 0.03,
                maxWidth: 0.58
            )
            let placement = show ? choiceOverlayPlacement(for: base, position: position) : base
            imageView.spriteHeightMultiplier = placement.height
            imageView.spriteCenterXMultiplier = placement.centerX
            imageView.spriteBottomMultiplier = placement.bottom
            imageView.spriteMaxWidthMultiplier = placement.maxWidth
        }
    }

    private func choiceOverlayPlacement(for base: SpritePlacement, position: SceneVisualPosition) -> SpritePlacement {
        let shiftedCenterX: CGFloat
        switch position {
        case .left:
            shiftedCenterX = min(base.centerX, 0.20)
        case .center:
            shiftedCenterX = 0.29
        case .right:
            shiftedCenterX = 0.39
        }

        return SpritePlacement(
            height: min(base.height, 0.72),
            centerX: shiftedCenterX,
            bottom: max(base.bottom, -0.04),
            maxWidth: min(base.maxWidth, 0.42)
        )
    }

    // MARK: - Dialogue paging

    private static func paginateDialogue(_ text: String, softLimit: Int = 86) -> [String] {
        let normalized = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [""] }

        var units: [String] = []
        var current = ""
        for character in normalized {
            current.append(character)
            if ".!?。…".contains(character) {
                let unit = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !unit.isEmpty { units.append(unit) }
                current = ""
            }
        }
        let tail = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { units.append(tail) }

        var pages: [String] = []
        var page = ""
        for unit in units {
            let candidate = page.isEmpty ? unit : "\(page) \(unit)"
            if candidate.count <= softLimit {
                page = candidate
                continue
            }
            if !page.isEmpty {
                pages.append(page)
                page = ""
            }
            pages.append(contentsOf: wrapLongUnit(unit, limit: softLimit))
        }
        if !page.isEmpty { pages.append(page) }
        return pages.isEmpty ? [normalized] : pages
    }

    private static func wrapLongUnit(_ unit: String, limit: Int) -> [String] {
        var remaining = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        var pages: [String] = []

        while remaining.count > limit {
            let limitIndex = remaining.index(remaining.startIndex, offsetBy: limit)
            let prefix = remaining[..<limitIndex]
            let splitIndex = prefix.lastIndex(of: " ") ?? limitIndex
            let chunk = String(remaining[..<splitIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !chunk.isEmpty { pages.append(chunk) }
            remaining = String(remaining[splitIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if !remaining.isEmpty { pages.append(remaining) }
        return pages
    }

    private func startCurrentDialoguePage() {
        let page = dialoguePages.indices.contains(dialoguePageIndex) ? dialoguePages[dialoguePageIndex] : ""
        isTyping = true
        dialogueLabel.stringValue = ""
        conversationEngine.start(text: page)
    }

    private func advanceDialoguePageIfNeeded() -> Bool {
        guard dialoguePageIndex + 1 < dialoguePages.count else { return false }
        dialoguePageIndex += 1
        stopAdvancePulse()
        startCurrentDialoguePage()
        return true
    }

    // MARK: - Advance indicator

    private func startAdvancePulse() {
        advanceIndicator.isHidden = false
        advanceIndicator.alphaValue = 1.0
        blinkTimer?.invalidate()
        var bright = true
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { [weak self] _ in
            bright.toggle()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.25
                self?.advanceIndicator.animator().alphaValue = bright ? 1.0 : 0.25
            }
        }
    }

    private func stopAdvancePulse() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        advanceIndicator.isHidden = true
    }

    // MARK: - Visuals

    private func applyVisuals(
        for scene: SceneNode,
        stats: GameStats,
        assets: AssetManifest?,
        contentBaseURL: URL?
    ) {
        let yandere = CGFloat(stats.yandere) / 100.0
        let characterVisuals = scene.stageVisuals.filter { $0.type == .character }
        let showEventCG = scene.isEndingScene || scene.effects.contains("event_cg") || (characterVisuals.isEmpty && scene.cg != nil)

        let baseColor: NSColor
        switch scene.background {
        case "school_rooftop":       baseColor = NSColor(calibratedRed: 0.09, green: 0.13, blue: 0.18, alpha: 1)
        case "locked_room":          baseColor = NSColor(calibratedRed: 0.18, green: 0.12, blue: 0.12, alpha: 1)
        case "rain_street":          baseColor = NSColor(calibratedRed: 0.04, green: 0.05, blue: 0.09, alpha: 1)
        case "retro_arcade":         baseColor = NSColor(calibratedRed: 0.06, green: 0.04, blue: 0.08, alpha: 1)
        case "student_council_room": baseColor = NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.12, alpha: 1)
        case "underpass_rain":       baseColor = NSColor(calibratedRed: 0.03, green: 0.03, blue: 0.05, alpha: 1)
        case "locker_corridor":      baseColor = NSColor(calibratedRed: 0.13, green: 0.10, blue: 0.10, alpha: 1)
        case "abandoned_platform":   baseColor = NSColor(calibratedRed: 0.03, green: 0.06, blue: 0.10, alpha: 1)
        case "water_tower":          baseColor = NSColor(calibratedRed: 0.04, green: 0.09, blue: 0.12, alpha: 1)
        case "ai_kiosk":             baseColor = NSColor(calibratedRed: 0.02, green: 0.04, blue: 0.07, alpha: 1)
        case "mineral_aquarium":     baseColor = NSColor(calibratedRed: 0.00, green: 0.08, blue: 0.11, alpha: 1)
        case "old_library":          baseColor = NSColor(calibratedRed: 0.09, green: 0.07, blue: 0.05, alpha: 1)
        case "rain_shrine":          baseColor = NSColor(calibratedRed: 0.04, green: 0.06, blue: 0.05, alpha: 1)
        case "old_apartment":        baseColor = NSColor(calibratedRed: 0.10, green: 0.08, blue: 0.07, alpha: 1)
        case "water_lab":            baseColor = NSColor(calibratedRed: 0.02, green: 0.05, blue: 0.08, alpha: 1)
        default:                     baseColor = NSColor(calibratedRed: 0.06, green: 0.08, blue: 0.11, alpha: 1)
        }

        let sanityDrain = max(0, CGFloat(60 - stats.sanity)) / 60.0
        let sanityTint = NSColor(calibratedRed: 0.25, green: 0.08, blue: 0.35, alpha: 1)
        let tintedBase = baseColor
            .blended(withFraction: yandere * 0.18, of: .systemRed)?
            .blended(withFraction: sanityDrain * 0.14, of: sanityTint)
        backgroundLayerView.layer?.backgroundColor = (tintedBase ?? baseColor).cgColor

        if scene.background != lastBackgroundID {
            let fade = CATransition()
            fade.type = .fade
            fade.duration = 0.42
            fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            backgroundLayerView.layer?.add(fade, forKey: "bgTransition")
            lastBackgroundID = scene.background
        }

        if let bgID = scene.background, let bgAsset = assets?.backgrounds[bgID] {
            backgroundImageView.image = VisualAssetRenderer.image(for: bgAsset, baseURL: contentBaseURL, role: .background)
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

        if showEventCG {
            hideAllCharacterVisuals()
        } else {
            renderCharacterVisuals(characterVisuals, scene: scene, assets: assets, contentBaseURL: contentBaseURL)
        }
    }

    private func renderCharacterVisuals(
        _ visuals: [SceneVisual],
        scene: SceneNode,
        assets: AssetManifest?,
        contentBaseURL: URL?
    ) {
        let activePositions = Set(visuals.map(\.position))
        for position in characterPositions where !activePositions.contains(position) {
            hideCharacter(at: position)
        }

        for visual in visuals {
            guard let imageView = characterImageViews[visual.position], let charAsset = assets?.characters[visual.id] else {
                hideCharacter(at: visual.position)
                continue
            }

            let characterImage = VisualAssetRenderer.image(for: charAsset, baseURL: contentBaseURL, role: .character)
            baseSpritePlacements[visual.position] = spritePlacement(
                for: visual.id,
                position: visual.position,
                activeVisualCount: visuals.count,
                scene: scene,
                image: characterImage
            )
            updateCharacterPlacement(forChoiceOverlay: currentPhase == .awaitingChoice)
            showCharacter(imageView, id: visual.id, at: visual.position, image: characterImage)
        }
    }

    private func showCharacter(_ imageView: SceneImageView, id: String, at position: SceneVisualPosition, image: NSImage) {
        let targetAlpha = characterVisualAlpha(for: id)
        let shouldCrossfade = imageView.isHidden || currentCharacterIDs[position] != id
        currentCharacterIDs[position] = id
        imageView.image = image
        imageView.isHidden = false

        if shouldCrossfade {
            imageView.alphaValue = 0
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                imageView.animator().alphaValue = targetAlpha
            }
        } else {
            imageView.alphaValue = targetAlpha
        }
    }

    private func hideAllCharacterVisuals() {
        for position in characterPositions {
            hideCharacter(at: position)
        }
    }

    private func hideCharacter(at position: SceneVisualPosition) {
        guard let imageView = characterImageViews[position] else { return }
        currentCharacterIDs[position] = nil
        guard !imageView.isHidden || imageView.image != nil else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.16
            imageView.animator().alphaValue = 0
        }) { [weak self, weak imageView] in
            guard self?.currentCharacterIDs[position] == nil else { return }
            imageView?.isHidden = true
            imageView?.image = nil
        }
    }

    private func characterVisualAlpha(for characterID: String) -> CGFloat {
        characterID == "haru_reflection" || characterID == "haru_umbrella_reflection" ? 0.52 : 0.96
    }

    private func spritePlacement(
        for characterID: String,
        position: SceneVisualPosition,
        activeVisualCount: Int,
        scene: SceneNode,
        image: NSImage
    ) -> SpritePlacement {
        let aspect = image.size.height > 0 ? image.size.width / image.size.height : 0.66
        var height: CGFloat
        var bottom: CGFloat
        var maxWidth: CGFloat

        switch aspect {
        case 1.05...:
            height = 0.58
            bottom = 0.08
            maxWidth = 0.48
        case ..<0.56:
            height = 0.86
            bottom = -0.10
            maxWidth = 0.54
        case ..<0.70:
            height = 0.82
            bottom = -0.06
            maxWidth = 0.54
        default:
            height = 0.80
            bottom = -0.04
            maxWidth = 0.54
        }

        var centerX = centerX(for: position)
        if characterID.contains("shadow") {
            centerX += position == .center ? 0.04 : 0.01
            height -= 0.02
            bottom -= 0.01
        }
        if characterID.contains("yuka") {
            centerX -= position == .right ? 0.01 : 0.02
            height -= 0.02
        }
        if characterID.contains("airi") {
            centerX -= position == .left ? 0.01 : 0.03
            height -= 0.01
        }
        if characterID == "haru_reflection" {
            return SpritePlacement(height: min(height, 0.58), centerX: centerX, bottom: max(bottom, 0.08), maxWidth: min(maxWidth, 0.44))
        }
        if scene.effects.contains("decision_moment") {
            centerX += position == .center ? 0.02 : 0
            height += 0.03
            bottom -= 0.02
        }
        if characterID.contains("tender") || characterID.contains("close") {
            centerX += 0.02
            height += 0.03
            bottom -= 0.02
        }
        if characterID.contains("breakdown") || characterID.contains("childlike") {
            centerX += 0.02
            height += 0.04
            bottom -= 0.03
        }

        if activeVisualCount > 1 {
            height -= activeVisualCount >= 3 ? 0.08 : 0.04
            maxWidth = min(maxWidth, activeVisualCount >= 3 ? 0.34 : 0.40)
        }

        return SpritePlacement(
            height: max(0.46, min(height, 0.88)),
            centerX: max(0.18, min(centerX, 0.82)),
            bottom: max(-0.12, min(bottom, 0.16)),
            maxWidth: max(0.30, min(maxWidth, 0.58))
        )
    }

    private func centerX(for position: SceneVisualPosition) -> CGFloat {
        switch position {
        case .left:
            return 0.30
        case .center:
            return 0.50
        case .right:
            return 0.70
        }
    }

    // MARK: - Input

    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    // Clicking scene background advances dialogue
    open override func mouseDown(with event: NSEvent) {
        requestAdvanceOrSkip()
    }

    open override func keyDown(with event: NSEvent) {
        if currentPhase == .awaitingChoice,
           let key = event.charactersIgnoringModifiers,
           let choiceNumber = Int(key),
           (1...visibleChoiceButtons.count).contains(choiceNumber) {
            choicePressed(visibleChoiceButtons[choiceNumber - 1])
            return
        }

        switch event.charactersIgnoringModifiers {
        case " ", "\r", "\u{3}":
            requestAdvanceOrSkip()
        default:
            super.keyDown(with: event)
        }
    }

    private func choiceMoodText(for stats: GameStats) -> String {
        switch (stats.yandere, stats.sanity) {
        case (80..., _):  return "숨이 막힌다. 이 선택이 모든 걸 바꿀지도 모른다."
        case (_, ...20):  return "머릿속이 뿌옇다. 무엇이 맞는지 모르겠다."
        case (55..., _):  return "고를 때마다 무언가가 달라진다는 걸 안다."
        case (_, 70...):  return "빗소리가 멀어진다. 확신이 필요하다."
        default:          return "빗소리가 낮아진다. 지금 대답해야 한다."
        }
    }

    private func requestAdvanceOrSkip() {
        if isTyping {
            conversationEngine.skip()
        } else if currentPhase == .presentingLine {
            if advanceDialoguePageIfNeeded() { return }
            stopAdvancePulse()
            onLineFinished?()
        } else if currentPhase == .transitioning {
            onAdvanceRequested?()
        }
    }

    @objc private func choicePressed(_ sender: ChoiceButton) {
        guard let id = sender.representedChoiceID else { return }
        showChoiceOverlay(false, animated: true)
        onChoiceSelected?(id)
    }

    @objc private func backlogPressed() { onBacklogRequested?() }
    @objc private func galleryPressed() { onGalleryRequested?() }
    @objc private func savePressed() { onSaveRequested?() }
    @objc private func loadPressed() { onLoadRequested?() }

    // MARK: - Toast

    public func showToast(_ message: String) {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.70).cgColor
        container.layer?.cornerRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField(labelWithString: message)
        label.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = NSColor.white.withAlphaComponent(0.92)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 9),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -9),
        ])

        addSubview(container)
        NSLayoutConstraint.activate([
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            container.topAnchor.constraint(equalTo: topAnchor, constant: 52),
        ])

        container.alphaValue = 0
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.22
            container.animator().alphaValue = 1
        }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration = 0.30
                    container.animator().alphaValue = 0
                }) { container.removeFromSuperview() }
            }
        }
    }
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
                .foregroundColor: NSColor.white.withAlphaComponent(0.60),
                .paragraphStyle: para,
            ]
        )
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 26),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
        ])
        updateAppearance()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        tracking.map { removeTrackingArea($0) }
        let t = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self)
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
        layer?.borderColor = NSColor.white.withAlphaComponent(hovering ? 0.22 : 0.11).cgColor
    }
}
