import Foundation

public enum GameStatePhase: String {
    case loading
    case presentingLine
    case awaitingChoice
    case transitioning
    case backlog
    case gallery
    case ending
}

public protocol GameStateManagerDelegate: AnyObject {
    func gameStateManager(_ manager: GameStateManager, didEnter scene: SceneNode, phase: GameStatePhase)
    func gameStateManager(_ manager: GameStateManager, didFail error: Error)
}

public final class GameStateManager {
    public weak var delegate: GameStateManagerDelegate?

    public private(set) var phase: GameStatePhase = .loading
    public private(set) var storyPackage: StoryPackage?
    public private(set) var currentScene: SceneNode?
    public private(set) var stats: GameStats = .defaults
    public private(set) var selectedTagCounts: [String: Int] = [:]
    public private(set) var backlog: [BacklogEntry] = []
    public private(set) var unlockedCG: Set<String> = []

    public init() {}

    public func load(package: StoryPackage) {
        do {
            try StoryValidator.validate(package)
            storyPackage = package
            stats = package.statBounds.initial
            selectedTagCounts = [:]
            backlog = []
            unlockedCG = []
            enterScene(package.metadata.startScene, recordBacklog: true)
        } catch {
            delegate?.gameStateManager(self, didFail: error)
        }
    }

    public func restore(package: StoryPackage, save: GameSave) {
        do {
            try StoryValidator.validate(package)
            storyPackage = package
            stats = save.stats
            selectedTagCounts = save.selectedTagCounts
            backlog = save.backlog
            unlockedCG = save.unlockedCG
            enterScene(save.sceneID, recordBacklog: false)
        } catch {
            delegate?.gameStateManager(self, didFail: error)
        }
    }

    public func availableChoices() -> [ChoiceNode] {
        guard let currentScene else { return [] }
        return currentScene.choices.filter { choice in
            choice.conditions.allSatisfy { $0.isSatisfied(stats: stats, tagCounts: selectedTagCounts) }
        }
    }

    public func finishPresentingLine() {
        guard let currentScene else { return }
        if currentScene.isEndingScene {
            phase = .ending
        } else if !availableChoices().isEmpty {
            phase = .awaitingChoice
        } else {
            phase = .transitioning
        }
        delegate?.gameStateManager(self, didEnter: currentScene, phase: phase)
    }

    public func advanceToNextScene() {
        guard let nextScene = currentScene?.nextScene else { return }
        enterScene(nextScene, recordBacklog: true)
    }

    public func choose(choiceID: String) {
        guard let package = storyPackage, let scene = currentScene else { return }
        guard let choice = availableChoices().first(where: { $0.id == choiceID }) else { return }

        stats.apply(choice.delta, bounds: package.statBounds.range)
        for tag in choice.tags {
            selectedTagCounts[tag, default: 0] += 1
        }

        backlog.append(BacklogEntry(sceneID: scene.id, speaker: "선택", text: choice.text, kind: .choice))
        enterScene(choice.nextScene, recordBacklog: true)
    }

    public func makeSave(thumbnailPath: String? = nil) -> GameSave? {
        guard let package = storyPackage, let currentScene else { return nil }
        return GameSave(
            storyID: package.metadata.storyID,
            sceneID: currentScene.id,
            stats: stats,
            selectedTagCounts: selectedTagCounts,
            backlog: backlog,
            unlockedCG: unlockedCG,
            thumbnailPath: thumbnailPath
        )
    }

    public func evaluateEnding() -> EndingRule? {
        guard let package = storyPackage else { return nil }
        let matching = package.endings
            .filter { $0.matches(stats: stats, tagCounts: selectedTagCounts) }
            .sorted { $0.priority < $1.priority }

        if let ending = matching.first {
            return ending
        }

        return package.endings.first { $0.id == package.metadata.defaultEnding }
    }

    private func enterScene(_ sceneID: String, recordBacklog: Bool) {
        guard let package = storyPackage else { return }

        if sceneID == package.metadata.finalScene, let ending = evaluateEnding() {
            enterScene(ending.nextScene, recordBacklog: recordBacklog)
            return
        }

        guard let scene = package.sceneIndex[sceneID] else {
            delegate?.gameStateManager(self, didFail: StoryValidationError.missingScene(sceneID))
            return
        }

        currentScene = scene
        if let cg = scene.cg {
            unlockedCG.insert(cg)
        }

        if let cg = scene.unlockCG {
            unlockedCG.insert(cg)
        }

        if recordBacklog {
            backlog.append(BacklogEntry(sceneID: scene.id, speaker: scene.speaker, text: scene.text, kind: .line))
        }

        phase = scene.isEndingScene ? .ending : .presentingLine
        delegate?.gameStateManager(self, didEnter: scene, phase: phase)
    }
}
