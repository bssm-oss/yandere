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
        XCTAssertNotNil(package.endingIndex[package.metadata.defaultEnding])
        XCTAssertNoThrow(try StoryValidator.validate(package))
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

            var occupiedVisualPositions = Set<SceneVisualPosition>()
            for visual in scene.visuals {
                XCTAssertNotNil(package.assets.characters[visual.id], "\(scene.id) points to missing visual character \(visual.id)")
                XCTAssertTrue(occupiedVisualPositions.insert(visual.position).inserted, "\(scene.id) duplicates visual position \(visual.position)")
            }

            if scene.effects.contains("event_cg") {
                XCTAssertNotNil(scene.cg, "\(scene.id) has event_cg without cg")
            }

            for choice in scene.choices {
                XCTAssertTrue(sceneIDs.contains(choice.nextScene), "\(choice.id) points to missing \(choice.nextScene)")
            }
        }
    }

    func testLegacyCharacterFallbackAndStagedVisuals() throws {
        let legacySceneJSON = """
        {
          "id": "legacy_scene",
          "text": "legacy text",
          "speaker": "하루",
          "choices": [],
          "next_scene": null,
          "character": "sea_normal",
          "effects": []
        }
        """.data(using: .utf8)!
        let legacyScene = try JSONDecoder().decode(SceneNode.self, from: legacySceneJSON)
        XCTAssertTrue(legacyScene.visuals.isEmpty)
        XCTAssertEqual(
            legacyScene.stageVisuals,
            [SceneVisual(type: .character, id: "sea_normal", position: .center)]
        )

        let package = try TestSupport.loadPackage()
        XCTAssertEqual(
            package.sceneIndex["ch02_airi_warning"]?.visuals,
            [
                SceneVisual(type: .character, id: "airi_locker_evidence", position: .left),
                SceneVisual(type: .character, id: "sea_charm_camera", position: .right)
            ]
        )
        XCTAssertEqual(
            package.sceneIndex["ch06f_weekend_station_clock"]?.visuals,
            [
                SceneVisual(type: .character, id: "airi_resolve", position: .left),
                SceneVisual(type: .character, id: "sea_station_clock", position: .center),
                SceneVisual(type: .character, id: "yuka_weather_terminal", position: .right)
            ]
        )
    }

    func testAssetPathsStayBundledAndRelative() throws {
        let package = try TestSupport.loadPackage()
        let assets = Array(package.assets.backgrounds.values)
            + Array(package.assets.characters.values)
            + Array(package.assets.cg.values)

        for asset in assets {
            XCTAssertFalse(asset.path.contains(".."), asset.id)
            XCTAssertFalse(asset.path.contains("\\"), asset.id)
            XCTAssertFalse(asset.path.contains(":"), asset.id)
            XCTAssertFalse(asset.path.hasPrefix("/"), asset.id)
            XCTAssertFalse(asset.path.hasPrefix("~"), asset.id)
            XCTAssertTrue(asset.path.hasPrefix("Assets/"), asset.id)
        }
    }
}
