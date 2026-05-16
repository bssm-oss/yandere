import Foundation
@testable import WeekendRainCore

enum TestSupport {
    static var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    static var storyURL: URL {
        projectRoot.appendingPathComponent("ExternalContent/Stories/weekend_rain.story.json")
    }

    static func loadPackage() throws -> StoryPackage {
        try StoryLoader().loadStory(at: storyURL)
    }

    static func evaluateEnding(package: StoryPackage, stats: GameStats, tags: [String: Int] = [:]) -> EndingRule? {
        let matches = package.endings
            .filter { $0.matches(stats: stats, tagCounts: tags) }
            .sorted { $0.priority < $1.priority }

        return matches.first ?? package.endings.first { $0.id == package.metadata.defaultEnding }
    }

    static func endingID(for choices: [String], package: StoryPackage) throws -> String {
        let manager = GameStateManager()
        manager.load(package: package)

        for choiceID in choices {
            advanceUntilChoice(manager)
            guard manager.availableChoices().contains(where: { $0.id == choiceID }) else {
                throw NSError(domain: "WeekendRainTests", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Choice \(choiceID) is not available at \(manager.currentScene?.id ?? "nil")"
                ])
            }
            manager.choose(choiceID: choiceID)
        }

        return manager.evaluateEnding()?.id ?? ""
    }

    static func advanceUntilChoice(_ manager: GameStateManager) {
        while manager.availableChoices().isEmpty,
              let scene = manager.currentScene,
              !scene.isEndingScene,
              scene.nextScene != nil {
            manager.advanceToNextScene()
        }
    }
}
