import XCTest
@testable import WeekendRainCore

final class StoryDecodingTests: XCTestCase {
    func testStoryDecodesAndValidates() throws {
        let package = try TestSupport.loadPackage()

        XCTAssertEqual(package.schemaVersion, 1)
        XCTAssertEqual(package.metadata.storyID, "weekend_rain.v1")
        XCTAssertTrue(package.systemMessage.contains("주말의 비"))
        XCTAssertTrue(package.worldFoundation.cityName.contains("Rainveil City"))
        XCTAssertEqual(package.worldFoundation.annualRainDays, 300)
        XCTAssertEqual(package.archetypes.map(\.id), ["obsessor", "refugee", "catalyst", "shadow"])
        XCTAssertTrue(package.archetypes[0].visualRule.contains("빨간색"))
        XCTAssertNotNil(package.sceneIndex[package.metadata.startScene])
        XCTAssertNotNil(package.sceneIndex[package.metadata.finalScene])
        XCTAssertGreaterThanOrEqual(package.scenes.count, 62)
        XCTAssertGreaterThanOrEqual(package.assets.backgrounds.count, 52)
        XCTAssertGreaterThanOrEqual(package.assets.characters.count, 48)
        XCTAssertGreaterThanOrEqual(package.assets.cg.count, 63)
        XCTAssertEqual(package.statBounds.initial, GameStats.defaults)
    }

    func testSceneReferencesResolve() throws {
        let package = try TestSupport.loadPackage()
        let sceneIDs = Set(package.scenes.map(\.id))

        for scene in package.scenes {
            if let nextScene = scene.nextScene {
                XCTAssertTrue(sceneIDs.contains(nextScene), "\(scene.id) points to missing \(nextScene)")
            }

            if let background = scene.background {
                XCTAssertNotNil(package.assets.backgrounds[background], "\(scene.id) points to missing background \(background)")
            }

            if let character = scene.character {
                XCTAssertNotNil(package.assets.characters[character], "\(scene.id) points to missing character \(character)")
            }

            if let cg = scene.cg {
                XCTAssertNotNil(package.assets.cg[cg], "\(scene.id) points to missing cg \(cg)")
            }

            if let unlockCG = scene.unlockCG {
                XCTAssertNotNil(package.assets.cg[unlockCG], "\(scene.id) points to missing unlock_cg \(unlockCG)")
            }

            for choice in scene.choices {
                XCTAssertTrue(sceneIDs.contains(choice.nextScene), "\(choice.id) points to missing \(choice.nextScene)")
            }
        }
    }
}
