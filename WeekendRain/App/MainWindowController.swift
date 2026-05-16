import AppKit
import WeekendRainCore

final class MainWindowController: NSWindowController, GameStateManagerDelegate {
    private static let preferredContentSize = NSSize(width: 960, height: 540)
    private static let minimumContentSize = NSSize(width: 720, height: 405)
    private static let maximumContentSize = NSSize(width: 1280, height: 720)

    private let titleView = TitleView()
    private let sceneView = NovelSceneView()
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
        window.maxSize = Self.maximumContentSize
        window.contentMinSize = Self.minimumContentSize
        window.contentMaxSize = Self.maximumContentSize
        window.isRestorable = false
        super.init(window: window)
        window.contentView = titleView
        window.setContentSize(Self.preferredContentSize)
        gameState.delegate = self
        wireTitleActions()
        wireGameActions()
    }

    required init?(coder: NSCoder) { nil }

    func presentMainWindow() {
        guard let window else { return }
        let frame = Self.initialWindowFrame()
        window.setFrame(frame, display: true, animate: false)
        window.setContentSize(Self.preferredContentSize)
        window.makeKeyAndOrderFront(nil)
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
        guard let window else { return }
        sceneView.alphaValue = 0
        window.contentView = sceneView
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.55
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            sceneView.animator().alphaValue = 1.0
        }
    }

    // MARK: - In-Game Actions

    private func saveGame() {
        guard let save = gameState.makeSave() else { return }
        do {
            try saveManager.save(save)
            showAlert(title: "저장 완료", message: "게임을 저장했습니다.")
        } catch {
            showAlert(title: "저장 실패", message: String(describing: error))
        }
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
