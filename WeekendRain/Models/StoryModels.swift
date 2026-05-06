import Foundation

public struct StoryPackage: Codable, Equatable {
    public let schemaVersion: Int
    public let metadata: StoryMetadata
    public let systemMessage: String
    public let worldFoundation: WorldFoundation
    public let archetypes: [CharacterArchetype]
    public let statBounds: StatBounds
    public let assets: AssetManifest
    public let scenes: [SceneNode]
    public let endings: [EndingRule]

    public var sceneIndex: [String: SceneNode] {
        scenes.reduce(into: [:]) { index, scene in
            index[scene.id] = scene
        }
    }

    public var endingIndex: [String: EndingRule] {
        endings.reduce(into: [:]) { index, ending in
            index[ending.id] = ending
        }
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case metadata
        case systemMessage = "system_message"
        case worldFoundation = "world_foundation"
        case archetypes
        case statBounds = "stat_bounds"
        case assets
        case scenes
        case endings
    }
}

public struct StoryMetadata: Codable, Equatable {
    public let storyID: String
    public let title: String
    public let subtitle: String
    public let locale: String
    public let startScene: String
    public let finalScene: String
    public let defaultEnding: String

    enum CodingKeys: String, CodingKey {
        case storyID = "story_id"
        case title
        case subtitle
        case locale
        case startScene = "start_scene"
        case finalScene = "final_scene"
        case defaultEnding = "default_ending"
    }
}

public struct WorldFoundation: Codable, Equatable {
    public let cityName: String
    public let annualRainDays: Int
    public let rainMeaning: String
    public let emotionalLaw: String
    public let mineralRumor: String
    public let era: String
    public let techCulture: String

    enum CodingKeys: String, CodingKey {
        case cityName = "city_name"
        case annualRainDays = "annual_rain_days"
        case rainMeaning = "rain_meaning"
        case emotionalLaw = "emotional_law"
        case mineralRumor = "mineral_rumor"
        case era
        case techCulture = "tech_culture"
    }
}

public struct CharacterArchetype: Codable, Equatable {
    public let id: String
    public let name: String
    public let coreDesire: String
    public let visualRule: String
    public let narrativeRole: String
    public let speechPattern: String
    public let loopInvariant: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case coreDesire = "core_desire"
        case visualRule = "visual_rule"
        case narrativeRole = "narrative_role"
        case speechPattern = "speech_pattern"
        case loopInvariant = "loop_invariant"
    }
}

public struct StatBounds: Codable, Equatable {
    public let min: Int
    public let max: Int
    public let initial: GameStats

    public var range: ClosedRange<Int> {
        min...max
    }
}

public struct GameStats: Codable, Equatable {
    public var love: Int
    public var yandere: Int
    public var sanity: Int

    public init(love: Int, yandere: Int, sanity: Int) {
        self.love = love
        self.yandere = yandere
        self.sanity = sanity
    }

    public static let defaults = GameStats(love: 20, yandere: 15, sanity: 60)

    public mutating func apply(_ delta: StatDelta, bounds: ClosedRange<Int> = 0...100) {
        love = Self.clamp(love + delta.love, to: bounds)
        yandere = Self.clamp(yandere + delta.yandere, to: bounds)
        sanity = Self.clamp(sanity + delta.sanity, to: bounds)
    }

    public func value(for key: StatKey) -> Int {
        switch key {
        case .love:
            return love
        case .yandere:
            return yandere
        case .sanity:
            return sanity
        }
    }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

public struct StatDelta: Codable, Equatable {
    public let love: Int
    public let yandere: Int
    public let sanity: Int

    public init(love: Int = 0, yandere: Int = 0, sanity: Int = 0) {
        self.love = love
        self.yandere = yandere
        self.sanity = sanity
    }
}

public enum StatKey: String, Codable, CaseIterable {
    case love
    case yandere
    case sanity
}

public struct SceneNode: Codable, Equatable {
    public let id: String
    public let text: String
    public let speaker: String
    public let choices: [ChoiceNode]
    public let nextScene: String?
    public let background: String?
    public let character: String?
    public let cg: String?
    public let music: String?
    public let effects: [String]
    public let unlockCG: String?

    public var isEndingScene: Bool {
        id.hasPrefix("ending_")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case speaker
        case choices
        case nextScene = "next_scene"
        case background
        case character
        case cg
        case music
        case effects
        case unlockCG = "unlock_cg"
    }

    public init(
        id: String,
        text: String,
        speaker: String,
        choices: [ChoiceNode],
        nextScene: String?,
        background: String? = nil,
        character: String? = nil,
        cg: String? = nil,
        music: String? = nil,
        effects: [String] = [],
        unlockCG: String? = nil
    ) {
        self.id = id
        self.text = text
        self.speaker = speaker
        self.choices = choices
        self.nextScene = nextScene
        self.background = background
        self.character = character
        self.cg = cg
        self.music = music
        self.effects = effects
        self.unlockCG = unlockCG
    }
}

public struct ChoiceNode: Codable, Equatable {
    public let id: String
    public let text: String
    public let delta: StatDelta
    public let tags: [String]
    public let nextScene: String
    public let conditions: [StoryCondition]

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case delta
        case tags
        case nextScene = "next_scene"
        case conditions
    }

    public init(
        id: String,
        text: String,
        delta: StatDelta,
        tags: [String],
        nextScene: String,
        conditions: [StoryCondition] = []
    ) {
        self.id = id
        self.text = text
        self.delta = delta
        self.tags = tags
        self.nextScene = nextScene
        self.conditions = conditions
    }
}

public struct StoryCondition: Codable, Equatable {
    public let minStats: [String: Int]
    public let maxStats: [String: Int]
    public let tagsAtLeast: [String: Int]

    enum CodingKeys: String, CodingKey {
        case minStats = "min_stats"
        case maxStats = "max_stats"
        case tagsAtLeast = "tags_at_least"
    }

    public init(
        minStats: [String: Int] = [:],
        maxStats: [String: Int] = [:],
        tagsAtLeast: [String: Int] = [:]
    ) {
        self.minStats = minStats
        self.maxStats = maxStats
        self.tagsAtLeast = tagsAtLeast
    }

    public func isSatisfied(stats: GameStats, tagCounts: [String: Int]) -> Bool {
        for (rawKey, minimum) in minStats {
            guard let key = StatKey(rawValue: rawKey), stats.value(for: key) >= minimum else {
                return false
            }
        }

        for (rawKey, maximum) in maxStats {
            guard let key = StatKey(rawValue: rawKey), stats.value(for: key) <= maximum else {
                return false
            }
        }

        for (tag, minimum) in tagsAtLeast {
            guard (tagCounts[tag] ?? 0) >= minimum else {
                return false
            }
        }

        return true
    }
}

public struct EndingRule: Codable, Equatable {
    public let id: String
    public let route: String
    public let title: String
    public let priority: Int
    public let nextScene: String
    public let condition: StoryCondition

    enum CodingKeys: String, CodingKey {
        case id
        case route
        case title
        case priority
        case nextScene = "next_scene"
        case condition
    }

    public func matches(stats: GameStats, tagCounts: [String: Int]) -> Bool {
        condition.isSatisfied(stats: stats, tagCounts: tagCounts)
    }
}

public struct AssetManifest: Codable, Equatable {
    public let visualStyle: [String]
    public let backgrounds: [String: VisualAsset]
    public let characters: [String: VisualAsset]
    public let cg: [String: VisualAsset]

    enum CodingKeys: String, CodingKey {
        case visualStyle = "visual_style"
        case backgrounds
        case characters
        case cg
    }
}

public struct VisualAsset: Codable, Equatable {
    public let id: String
    public let name: String
    public let path: String
    public let prompt: String
    public let tags: [String]
}
