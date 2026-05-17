import Foundation

public enum StoryValidationError: Error, CustomStringConvertible, Equatable {
    case duplicateSceneID(String)
    case missingScene(String)
    case invalidReference(source: String, target: String)
    case invalidAssetReference(source: String, role: String, target: String)
    case invalidAssetPath(source: String, path: String)
    case missingEventCG(String)
    case duplicateVisualPosition(source: String, position: String)
    case unreachableScene(String)
    case deadEndScene(String)
    case invalidConditionKey(String)

    public var description: String {
        switch self {
        case .duplicateSceneID(let id):
            return "Duplicate scene id: \(id)"
        case .missingScene(let id):
            return "Missing scene: \(id)"
        case .invalidReference(let source, let target):
            return "Invalid reference from \(source) to \(target)"
        case .invalidAssetReference(let source, let role, let target):
            return "Invalid \(role) asset reference from \(source) to \(target)"
        case .invalidAssetPath(let source, let path):
            return "Invalid asset path for \(source): \(path)"
        case .missingEventCG(let id):
            return "Scene has event_cg effect without cg: \(id)"
        case .duplicateVisualPosition(let source, let position):
            return "Duplicate visual position \(position) in scene \(source)"
        case .unreachableScene(let id):
            return "Scene is unreachable from start scene: \(id)"
        case .deadEndScene(let id):
            return "Non-ending scene has no choices or next_scene: \(id)"
        case .invalidConditionKey(let key):
            return "Invalid stat condition key: \(key)"
        }
    }
}

public enum StoryValidator {
    public static func validate(_ package: StoryPackage) throws {
        var sceneIDs = Set<String>()
        for scene in package.scenes {
            guard sceneIDs.insert(scene.id).inserted else {
                throw StoryValidationError.duplicateSceneID(scene.id)
            }
        }

        guard sceneIDs.contains(package.metadata.startScene) else {
            throw StoryValidationError.missingScene(package.metadata.startScene)
        }

        guard sceneIDs.contains(package.metadata.finalScene) else {
            throw StoryValidationError.missingScene(package.metadata.finalScene)
        }

        guard package.endingIndex[package.metadata.defaultEnding] != nil else {
            throw StoryValidationError.invalidReference(source: "default_ending", target: package.metadata.defaultEnding)
        }

        try validateAssetPaths(package.assets.backgrounds, expectedPrefix: "Assets/BG/")
        try validateAssetPaths(package.assets.characters, expectedPrefix: "Assets/Character/")
        try validateAssetPaths(package.assets.cg, expectedPrefix: "Assets/CG/")

        for scene in package.scenes {
            if let background = scene.background, package.assets.backgrounds[background] == nil {
                throw StoryValidationError.invalidAssetReference(source: scene.id, role: "background", target: background)
            }

            if let character = scene.character, package.assets.characters[character] == nil {
                throw StoryValidationError.invalidAssetReference(source: scene.id, role: "character", target: character)
            }

            var occupiedVisualPositions = Set<SceneVisualPosition>()
            for visual in scene.visuals {
                guard occupiedVisualPositions.insert(visual.position).inserted else {
                    throw StoryValidationError.duplicateVisualPosition(source: scene.id, position: visual.position.rawValue)
                }

                switch visual.type {
                case .character:
                    if package.assets.characters[visual.id] == nil {
                        throw StoryValidationError.invalidAssetReference(source: scene.id, role: "visuals.character", target: visual.id)
                    }
                }
            }

            if let cg = scene.cg, package.assets.cg[cg] == nil {
                throw StoryValidationError.invalidAssetReference(source: scene.id, role: "cg", target: cg)
            }

            if let unlockCG = scene.unlockCG, package.assets.cg[unlockCG] == nil {
                throw StoryValidationError.invalidAssetReference(source: scene.id, role: "unlock_cg", target: unlockCG)
            }

            if scene.effects.contains("event_cg"), scene.cg == nil {
                throw StoryValidationError.missingEventCG(scene.id)
            }

            if let nextScene = scene.nextScene, !sceneIDs.contains(nextScene) {
                throw StoryValidationError.invalidReference(source: scene.id, target: nextScene)
            }

            for choice in scene.choices {
                if !sceneIDs.contains(choice.nextScene) {
                    throw StoryValidationError.invalidReference(source: choice.id, target: choice.nextScene)
                }

                try validate(choice.conditions)
            }

            let isAllowedTerminal = scene.isEndingScene || scene.id == package.metadata.finalScene
            if scene.choices.isEmpty, scene.nextScene == nil, !isAllowedTerminal {
                throw StoryValidationError.deadEndScene(scene.id)
            }
        }

        for ending in package.endings {
            guard sceneIDs.contains(ending.nextScene) else {
                throw StoryValidationError.invalidReference(source: ending.id, target: ending.nextScene)
            }
            try validate([ending.condition])
        }

        let reachableSceneIDs = reachableScenes(from: package.metadata.startScene, in: package)
        for sceneID in sceneIDs where !reachableSceneIDs.contains(sceneID) {
            throw StoryValidationError.unreachableScene(sceneID)
        }
    }

    private static func reachableScenes(from startScene: String, in package: StoryPackage) -> Set<String> {
        let sceneIndex = package.sceneIndex
        var visited = Set<String>()
        var queue = [startScene]

        while let sceneID = queue.first {
            queue.removeFirst()
            guard visited.insert(sceneID).inserted, let scene = sceneIndex[sceneID] else { continue }

            if scene.id == package.metadata.finalScene {
                queue.append(contentsOf: package.endings.map(\.nextScene))
                continue
            }

            if let nextScene = scene.nextScene {
                queue.append(nextScene)
            }
            queue.append(contentsOf: scene.choices.map(\.nextScene))
        }

        return visited
    }

    private static func validateAssetPaths(_ assets: [String: VisualAsset], expectedPrefix: String) throws {
        for asset in assets.values {
            let path = asset.path
            let isSafeRelativePath = path.hasPrefix(expectedPrefix)
                && !path.contains("..")
                && !path.contains("\\")
                && !path.contains(":")
                && !path.hasPrefix("/")
                && !path.hasPrefix("~")

            if !isSafeRelativePath {
                throw StoryValidationError.invalidAssetPath(source: asset.id, path: path)
            }
        }
    }

    private static func validate(_ conditions: [StoryCondition]) throws {
        for condition in conditions {
            for key in condition.minStats.keys where StatKey(rawValue: key) == nil {
                throw StoryValidationError.invalidConditionKey(key)
            }

            for key in condition.maxStats.keys where StatKey(rawValue: key) == nil {
                throw StoryValidationError.invalidConditionKey(key)
            }
        }
    }
}
