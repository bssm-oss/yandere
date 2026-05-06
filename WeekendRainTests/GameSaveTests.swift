import XCTest
@testable import WeekendRainCore

final class GameSaveTests: XCTestCase {
    func testSecureArchiveRoundTrip() throws {
        let save = GameSave(
            storyID: "weekend_rain.v1",
            sceneID: "ch04_rooftop_confession",
            stats: GameStats(love: 70, yandere: 25, sanity: 80),
            selectedTagCounts: ["truth": 2, "yuka": 1],
            backlog: [
                BacklogEntry(sceneID: "prologue_rain_gate", speaker: "세아", text: "우산 없어?", kind: .line),
                BacklogEntry(sceneID: "prologue_rain_gate", speaker: "선택", text: "붉은 우산 안으로 들어간다.", kind: .choice)
            ],
            unlockedCG: ["cg_true_rainbow"],
            thumbnailPath: "thumbs/save1.png"
        )

        let data = try NSKeyedArchiver.archivedData(withRootObject: save, requiringSecureCoding: true)
        let restored = try XCTUnwrap(NSKeyedUnarchiver.unarchivedObject(ofClass: GameSave.self, from: data))

        XCTAssertEqual(restored.storyID, save.storyID)
        XCTAssertEqual(restored.sceneID, save.sceneID)
        XCTAssertEqual(restored.stats, save.stats)
        XCTAssertEqual(restored.selectedTagCounts, save.selectedTagCounts)
        XCTAssertEqual(restored.backlog, save.backlog)
        XCTAssertEqual(restored.unlockedCG, save.unlockedCG)
        XCTAssertEqual(restored.thumbnailPath, save.thumbnailPath)
    }
}

