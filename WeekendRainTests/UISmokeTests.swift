import AppKit
import XCTest
@testable import WeekendRainCore

final class UISmokeTests: XCTestCase {
    func testAppKitViewsInstantiate() throws {
        _ = NSApplication.shared

        let novelView = NovelSceneView(frame: NSRect(x: 0, y: 0, width: 960, height: 540))
        XCTAssertNotNil(novelView.rainView)

        let backlog = BacklogViewController(entries: [
            BacklogEntry(sceneID: "scene", speaker: "세아", text: "하루 군.", kind: .line)
        ])
        _ = backlog.view
        XCTAssertGreaterThan(backlog.view.bounds.width, 0)

        let asset = VisualAsset(
            id: "cg_true_rainbow",
            name: "이 멈춰버린 세상에서",
            path: "Assets/CG/cg_true_rainbow.png",
            prompt: "rain clears",
            tags: ["cg"]
        )
        let gallery = GalleryViewController(assets: [asset], unlockedCG: [asset.id])
        _ = gallery.view
        XCTAssertGreaterThan(gallery.view.bounds.height, 0)
    }

    func testNovelSceneViewRendersAtResponsiveSizes() throws {
        _ = NSApplication.shared
        let package = try TestSupport.loadPackage()
        let scene = try XCTUnwrap(package.sceneIndex["ch06f_weekend_station_clock"])

        for size in [
            NSSize(width: 820, height: 520),
            NSSize(width: 1180, height: 720),
            NSSize(width: 1600, height: 950)
        ] {
            let view = NovelSceneView(frame: NSRect(origin: .zero, size: size))
            view.render(
                scene: scene,
                phase: .awaitingChoice,
                stats: GameStats(love: 88, yandere: 72, sanity: 44),
                choices: scene.choices,
                assets: package.assets,
                contentBaseURL: TestSupport.projectRoot.appendingPathComponent("ExternalContent")
            )
            view.layoutSubtreeIfNeeded()
            XCTAssertEqual(view.frame.size, size)
        }
    }
}
