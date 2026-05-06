import Foundation

public final class GameSave: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let storyID: String
    public let sceneID: String
    public let stats: GameStats
    public let selectedTagCounts: [String: Int]
    public let backlog: [BacklogEntry]
    public let unlockedCG: Set<String>
    public let savedAt: Date
    public let thumbnailPath: String?

    public init(
        storyID: String,
        sceneID: String,
        stats: GameStats,
        selectedTagCounts: [String: Int],
        backlog: [BacklogEntry],
        unlockedCG: Set<String>,
        savedAt: Date = Date(),
        thumbnailPath: String? = nil
    ) {
        self.storyID = storyID
        self.sceneID = sceneID
        self.stats = stats
        self.selectedTagCounts = selectedTagCounts
        self.backlog = backlog
        self.unlockedCG = unlockedCG
        self.savedAt = savedAt
        self.thumbnailPath = thumbnailPath
    }

    public required init?(coder: NSCoder) {
        guard
            let storyID = coder.decodeObject(of: NSString.self, forKey: CodingKey.storyID.rawValue) as String?,
            let sceneID = coder.decodeObject(of: NSString.self, forKey: CodingKey.sceneID.rawValue) as String?,
            let statsData = coder.decodeObject(of: NSData.self, forKey: CodingKey.stats.rawValue) as Data?,
            let tagCountsData = coder.decodeObject(of: NSData.self, forKey: CodingKey.selectedTagCounts.rawValue) as Data?,
            let backlogData = coder.decodeObject(of: NSData.self, forKey: CodingKey.backlog.rawValue) as Data?,
            let unlockedData = coder.decodeObject(of: NSData.self, forKey: CodingKey.unlockedCG.rawValue) as Data?,
            let savedAt = coder.decodeObject(of: NSDate.self, forKey: CodingKey.savedAt.rawValue) as Date?
        else {
            return nil
        }

        do {
            self.storyID = storyID
            self.sceneID = sceneID
            self.stats = try JSONDecoder().decode(GameStats.self, from: statsData)
            self.selectedTagCounts = try JSONDecoder().decode([String: Int].self, from: tagCountsData)
            self.backlog = try JSONDecoder().decode([BacklogEntry].self, from: backlogData)
            self.unlockedCG = Set(try JSONDecoder().decode([String].self, from: unlockedData))
            self.savedAt = savedAt
            self.thumbnailPath = coder.decodeObject(of: NSString.self, forKey: CodingKey.thumbnailPath.rawValue) as String?
        } catch {
            return nil
        }
    }

    public func encode(with coder: NSCoder) {
        coder.encode(storyID as NSString, forKey: CodingKey.storyID.rawValue)
        coder.encode(sceneID as NSString, forKey: CodingKey.sceneID.rawValue)
        coder.encode(encoded(stats), forKey: CodingKey.stats.rawValue)
        coder.encode(encoded(selectedTagCounts), forKey: CodingKey.selectedTagCounts.rawValue)
        coder.encode(encoded(backlog), forKey: CodingKey.backlog.rawValue)
        coder.encode(encoded(Array(unlockedCG).sorted()), forKey: CodingKey.unlockedCG.rawValue)
        coder.encode(savedAt as NSDate, forKey: CodingKey.savedAt.rawValue)
        coder.encode(thumbnailPath as NSString?, forKey: CodingKey.thumbnailPath.rawValue)
    }

    private func encoded<T: Encodable>(_ value: T) -> NSData {
        let data = (try? JSONEncoder().encode(value)) ?? Data()
        return data as NSData
    }

    private enum CodingKey: String {
        case storyID
        case sceneID
        case stats
        case selectedTagCounts
        case backlog
        case unlockedCG
        case savedAt
        case thumbnailPath
    }
}
