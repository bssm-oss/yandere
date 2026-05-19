import AppKit
import WeekendRainCore

final class MainWindowController: NSWindowController, GameStateManagerDelegate {
    private static let preferredContentSize = NSSize(width: 960, height: 540)
    private static let minimumContentSize = NSSize(width: 720, height: 405)

    private let titleView = TitleView()
    private let sceneView = NovelSceneView()
    private var titleAnimated = false
    private var didPlaceInitialWindow = false
    private let storyLoader = StoryLoader()
    private let saveManager = SaveManager()
    private let gameState = GameStateManager()
    private var storyPackage: StoryPackage?
    private var contentBaseURL: URL?

    init() {
        let window = NSWindow(
            contentRect: Self.initialWindowFrame(),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "주말의 비 (Weekend Rain)"
        window.minSize = Self.minimumContentSize
        window.contentMinSize = Self.minimumContentSize
        window.collectionBehavior = [.fullScreenPrimary, .managed]
        window.isRestorable = false
        super.init(window: window)
        installRootContentView(titleView)
        window.setContentSize(Self.preferredContentSize)
        gameState.delegate = self
        wireTitleActions()
        wireGameActions()
    }

    required init?(coder: NSCoder) { nil }

    func presentMainWindow() {
        guard let window else { return }
        if !didPlaceInitialWindow && !window.styleMask.contains(.fullScreen) {
            let frame = Self.initialWindowFrame()
            window.setFrame(frame, display: true, animate: false)
            window.setContentSize(Self.preferredContentSize)
            didPlaceInitialWindow = true
        }
        window.makeKeyAndOrderFront(nil)
        if !titleAnimated {
            titleAnimated = true
            titleView.alphaValue = 0
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.80
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                titleView.animator().alphaValue = 1.0
            }
        }
    }

    // MARK: - GameStateManagerDelegate

    func gameStateManager(_ manager: GameStateManager, didEnter scene: SceneNode, phase: GameStatePhase) {
        sceneView.render(
            scene: scene,
            phase: phase,
            stats: manager.stats,
            choices: manager.availableChoices(),
            assets: storyPackage?.assets,
            contentBaseURL: contentBaseURL
        )
    }

    func gameStateManager(_ manager: GameStateManager, didFail error: Error) {
        showAlert(title: "오류", message: String(describing: error))
    }

    // MARK: - Wiring

    private func wireTitleActions() {
        titleView.onNewGame = { [weak self] in self?.startNewGame() }
        titleView.onLoadGame = { [weak self] in self?.startFromSave() }
        titleView.onGallery = { [weak self] in self?.presentTitleGallery() }
        titleView.onQuit = { NSApp.terminate(nil) }
    }

    private func wireGameActions() {
        sceneView.onLineFinished = { [weak self] in self?.finishCurrentLine() }
        sceneView.onChoiceSelected = { [weak self] id in self?.gameState.choose(choiceID: id) }
        sceneView.onAdvanceRequested = { [weak self] in self?.gameState.advanceToNextScene() }
        sceneView.onBacklogRequested = { [weak self] in self?.presentBacklog() }
        sceneView.onGalleryRequested = { [weak self] in self?.presentGallery() }
        sceneView.onSaveRequested = { [weak self] in self?.saveGame() }
        sceneView.onLoadRequested = { [weak self] in self?.loadSave() }
    }

    private func finishCurrentLine() {
        let shouldAdvanceDirectly = gameState.availableChoices().isEmpty
            && gameState.currentScene?.isEndingScene == false
        gameState.finishPresentingLine()
        if shouldAdvanceDirectly, gameState.phase == .transitioning {
            gameState.advanceToNextScene()
        }
    }

    // MARK: - Game Start Flow

    private func startNewGame() {
        guard loadStoryPackage(), let package = storyPackage else { return }
        gameState.load(package: package)
        transitionToGame()
    }

    private func startFromSave() {
        guard loadStoryPackage(), let package = storyPackage else { return }
        do {
            let save = try saveManager.load()
            guard save.storyID == package.metadata.storyID else {
                showAlert(title: "불러오기 실패", message: "저장 파일이 현재 스토리와 맞지 않습니다.")
                return
            }
            gameState.restore(package: package, save: save)
            transitionToGame()
        } catch {
            showAlert(title: "불러오기 실패", message: "저장 파일을 찾을 수 없습니다.\n새 게임으로 시작해 주세요.")
        }
    }

    private func transitionToGame() {
        sceneView.alphaValue = 0
        installRootContentView(sceneView)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.45
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            sceneView.animator().alphaValue = 1.0
        }
    }

    // MARK: - In-Game Actions

    private func saveGame() {
        guard let save = gameState.makeSave() else { return }
        do {
            try saveManager.save(save)
            sceneView.showToast("저장 완료")
        } catch {
            showAlert(title: "저장 실패", message: String(describing: error))
        }
    }

    func autoSave() {
        guard let save = gameState.makeSave() else { return }
        try? saveManager.save(save)
    }

    private func loadSave() {
        guard let package = storyPackage else { return }
        do {
            let save = try saveManager.load()
            guard save.storyID == package.metadata.storyID else {
                showAlert(title: "불러오기 실패", message: "저장 파일의 storyID가 현재 스토리와 다릅니다.")
                return
            }
            gameState.restore(package: package, save: save)
        } catch {
            showAlert(title: "불러오기 실패", message: String(describing: error))
        }
    }

    private func presentBacklog() {
        let vc = BacklogViewController(entries: gameState.backlog)
        presentSheet(vc, title: "백로그")
    }

    private func presentGallery() {
        guard let package = storyPackage else { return }
        let vc = GalleryViewController(
            assets: Array(package.assets.cg.values),
            unlockedCG: gameState.unlockedCG,
            contentBaseURL: contentBaseURL
        )
        presentSheet(vc, title: "CG 갤러리")
    }

    private func presentTitleGallery() {
        guard loadStoryPackage(), let package = storyPackage else { return }
        let vc = GalleryViewController(
            assets: Array(package.assets.cg.values),
            unlockedCG: gameState.unlockedCG,
            contentBaseURL: contentBaseURL
        )
        presentSheet(vc, title: "CG 갤러리")
    }

    // MARK: - Helpers

    @discardableResult
    private func loadStoryPackage() -> Bool {
        if storyPackage != nil { return true }
        do {
            guard let url = StoryLoader.defaultStoryURL() else {
                throw StoryLoaderError.missingDefaultStory
            }
            let package = try storyLoader.loadStory(at: url)
            storyPackage = package
            contentBaseURL = url.deletingLastPathComponent().deletingLastPathComponent()
            return true
        } catch {
            showAlert(
                title: "스토리를 찾을 수 없음",
                message: "ExternalContent/Stories/weekend_rain.story.json을 찾거나 읽을 수 없습니다.\n\n\(error)"
            )
            return false
        }
    }

    private func presentSheet(_ vc: NSViewController, title: String) {
        guard let window else { return }
        let panel = NSPanel(
            contentRect: vc.view.bounds,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = title
        panel.minSize = NSSize(width: 680, height: 460)
        panel.contentViewController = vc
        window.beginSheet(panel)
    }

    private func showAlert(title: String, message: String) {
        guard let window else { return }
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.beginSheetModal(for: window)
    }

    private func installRootContentView(_ view: NSView) {
        guard let window else { return }
        view.frame = window.contentView?.bounds ?? NSRect(origin: .zero, size: Self.preferredContentSize)
        view.autoresizingMask = [.width, .height]
        window.contentView = view
    }

    private static func initialWindowFrame() -> NSRect {
        let screen = NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else {
            return NSRect(origin: .zero, size: preferredContentSize)
        }
        let w = max(minimumContentSize.width, min(preferredContentSize.width, visible.width - 80))
        let h = max(minimumContentSize.height, min(preferredContentSize.height, visible.height - 80))
        return NSRect(
            x: visible.midX - w / 2,
            y: visible.midY - h / 2,
            width: w,
            height: h
        )
    }
}
