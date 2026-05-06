import Foundation

public enum BacklogKind: String, Codable {
    case line
    case choice
}

public struct BacklogEntry: Codable, Equatable {
    public let sceneID: String
    public let speaker: String
    public let text: String
    public let kind: BacklogKind
    public let timestamp: Date

    public init(sceneID: String, speaker: String, text: String, kind: BacklogKind, timestamp: Date = Date()) {
        self.sceneID = sceneID
        self.speaker = speaker
        self.text = text
        self.kind = kind
        self.timestamp = timestamp
    }
}

