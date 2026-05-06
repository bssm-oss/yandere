import AppKit
import XCTest
@testable import WeekendRainCore

final class AssetPipelineTests: XCTestCase {
    func testProjectBoundGeneratedAssetsExistAndLoad() throws {
        let package = try TestSupport.loadPackage()
        let contentBaseURL = TestSupport.projectRoot.appendingPathComponent("ExternalContent")
        let fileManager = FileManager.default

        let requiredAssets = [
            ("sea_wall_mural", package.assets.backgrounds, .background),
            ("maintenance_elevator", package.assets.backgrounds, .background),
            ("rain_clinic_records", package.assets.backgrounds, .background),
            ("weather_control_room", package.assets.backgrounds, .background),
            ("ferry_pier", package.assets.backgrounds, .background),
            ("flood_siren_tower", package.assets.backgrounds, .background),
            ("weekend_station_clock", package.assets.backgrounds, .background),
            ("cg_rainveil_final_evidence", package.assets.cg, .cg),
            ("sea_station_clock", package.assets.characters, .character),
            ("yuka_weather_terminal", package.assets.characters, .character),
            ("shadow_siren_tower", package.assets.characters, .character)
        ].map { id, bucket, role in
            guard let asset = bucket[id] else {
                XCTFail("Missing generated asset metadata: \(id)")
                return (VisualAsset(id: id, name: id, path: "", prompt: "", tags: []), role)
            }
            return (asset, role)
        }

        for (asset, role) in requiredAssets {
            let url = contentBaseURL.appendingPathComponent(asset.path)
            XCTAssertTrue(fileManager.fileExists(atPath: url.path), "Missing generated PNG: \(asset.path)")
            XCTAssertNotNil(NSImage(contentsOf: url), "Generated PNG did not load: \(asset.path)")
            let rendered = VisualAssetRenderer.image(for: asset, baseURL: contentBaseURL, role: role)
            XCTAssertGreaterThan(rendered.size.width, 0)
            XCTAssertGreaterThan(rendered.size.height, 0)
        }
    }
}
