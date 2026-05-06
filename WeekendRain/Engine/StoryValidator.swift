import Foundation

public enum StoryValidationError: Error, CustomStringConvertible, Equatable {
    case duplicateSceneID(String)
    case missingScene(String)
    case invalidReference(source: String, target: String)
    case invalidAssetReference(source: String, role: String, target: String)
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

        for scene in package.scenes {
            if let background = scene.background, package.assets.backgrounds[background] == nil {
                throw StoryValidationError.invalidAssetReference(source: scene.id, role: "background", target: background)
            }

            if let character = scene.character, package.assets.characters[character] == nil {
                throw StoryValidationError.invalidAssetReference(source: scene.id, role: "character", target: character)
            }

            if let cg = scene.cg, package.assets.cg[cg] == nil {
                throw StoryValidationError.invalidAssetReference(source: scene.id, role: "cg", target: cg)
            }

            if let unlockCG = scene.unlockCG, package.assets.cg[unlockCG] == nil {
                throw StoryValidationError.invalidAssetReference(source: scene.id, role: "unlock_cg", target: unlockCG)
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
