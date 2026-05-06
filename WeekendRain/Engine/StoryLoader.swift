import Foundation

public enum StoryLoaderError: LocalizedError {
    case missingDefaultStory

    public var errorDescription: String? {
        switch self {
        case .missingDefaultStory:
            return "ExternalContent/Stories/weekend_rain.story.json was not found."
        }
    }
}

public final class StoryLoader {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func loadStory(at url: URL) throws -> StoryPackage {
        let data = try Data(contentsOf: url)
        let package = try decoder.decode(StoryPackage.self, from: data)
        try StoryValidator.validate(package)
        return package
    }

    public func loadDefaultStory() throws -> StoryPackage {
        guard let url = Self.defaultStoryURL() else {
            throw StoryLoaderError.missingDefaultStory
        }

        return try loadStory(at: url)
    }

    public static func defaultStoryURL() -> URL? {
        let fileManager = FileManager.default
        let environmentPath = ProcessInfo.processInfo.environment["WEEKEND_RAIN_CONTENT_PATH"]
        var candidates: [URL] = []

        if let environmentPath, !environmentPath.isEmpty {
            candidates.append(URL(fileURLWithPath: environmentPath))
        }

        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        candidates.append(currentDirectory.appendingPathComponent("ExternalContent", isDirectory: true))

        let bundleURL = Bundle.main.bundleURL
        candidates.append(bundleURL.appendingPathComponent("Contents/Resources/ExternalContent", isDirectory: true))
        candidates.append(bundleURL.deletingLastPathComponent().appendingPathComponent("ExternalContent", isDirectory: true))
        candidates.append(bundleURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("ExternalContent", isDirectory: true))

        return candidates
            .map { $0.appendingPathComponent("Stories/weekend_rain.story.json") }
            .first { fileManager.fileExists(atPath: $0.path) }
    }
}

