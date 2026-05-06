import Foundation

public final class SaveManager {
    public let saveDirectory: URL

    public init(saveDirectory: URL? = nil) {
        if let saveDirectory {
            self.saveDirectory = saveDirectory
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            self.saveDirectory = base.appendingPathComponent("WeekendRain/Saves", isDirectory: true)
        }
    }

    public var quickSaveURL: URL {
        saveDirectory.appendingPathComponent("quicksave.wrain")
    }

    public func save(_ save: GameSave, to url: URL? = nil) throws {
        try FileManager.default.createDirectory(at: saveDirectory, withIntermediateDirectories: true)
        let destination = url ?? quickSaveURL
        let data = try NSKeyedArchiver.archivedData(withRootObject: save, requiringSecureCoding: true)
        try data.write(to: destination, options: .atomic)
    }

    public func load(from url: URL? = nil) throws -> GameSave {
        let source = url ?? quickSaveURL
        let data = try Data(contentsOf: source)
        guard let save = try NSKeyedUnarchiver.unarchivedObject(ofClass: GameSave.self, from: data) else {
            throw CocoaError(.coderReadCorrupt)
        }
        return save
    }
}

