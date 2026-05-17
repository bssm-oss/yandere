import XCTest
@testable import WeekendRainCore

final class FlagLogicTests: XCTestCase {
    func testEndingPriority() throws {
        let package = try TestSupport.loadPackage()

        XCTAssertEqual(
            TestSupport.evaluateEnding(
                package: package,
                stats: GameStats(love: 100, yandere: 100, sanity: 0),
                tags: ["yuka": 3, "truth": 3, "airi": 3]
            )?.id,
            "abyss"
        )

        XCTAssertEqual(
            TestSupport.evaluateEnding(
                package: package,
                stats: GameStats(love: 30, yandere: 20, sanity: 80),
                tags: ["yuka": 3, "truth": 3]
            )?.id,
            "ghost"
        )

        XCTAssertEqual(
            TestSupport.evaluateEnding(
                package: package,
                stats: GameStats(love: 95, yandere: 95, sanity: 30)
            )?.id,
            "box"
        )

        XCTAssertEqual(
            TestSupport.evaluateEnding(
                package: package,
                stats: GameStats(love: 40, yandere: 60, sanity: 60),
                tags: ["airi": 3]
            )?.id,
            "collapse"
        )

        XCTAssertEqual(
            TestSupport.evaluateEnding(
                package: package,
                stats: GameStats(love: 95, yandere: 20, sanity: 80)
            )?.id,
            "true"
        )
    }

    func testStatsClampAndTagCount() throws {
        let package = try TestSupport.loadPackage()
        var stats = GameStats(love: 95, yandere: 2, sanity: 50)
        stats.apply(StatDelta(love: 20, yandere: -10, sanity: -100), bounds: package.statBounds.range)

        XCTAssertEqual(stats.love, 100)
        XCTAssertEqual(stats.yandere, 0)
        XCTAssertEqual(stats.sanity, 0)

        let manager = GameStateManager()
        manager.load(package: package)
        TestSupport.advanceUntilChoice(manager)
        manager.choose(choiceID: "prologue_accept")
        XCTAssertEqual(manager.selectedTagCounts["sea_accept"], 1)
        XCTAssertEqual(manager.stats.love, 35)
        XCTAssertEqual(manager.stats.yandere, 20)
    }

    func testMajorRoutesAreReachable() throws {
        let package = try TestSupport.loadPackage()

        let trueRoute = [
            "prologue_accept",
            "notebook_ask",
            "airi_diary_detail",
            "yuka_tell_airi",
            "shadow_listen_recorder",
            "rooftop_boundary",
            "archive_compare_letter_fibers",
            "room_soothe",
            "threshold_name_sea_present",
            "station_clock_start_monday"
        ]
        XCTAssertEqual(try TestSupport.endingID(for: trueRoute, package: package), "true")
        let trueTerminal = try TestSupport.terminalSceneID(for: trueRoute, package: package)
        XCTAssertEqual(trueTerminal.sceneID, "ending_true")
        XCTAssertTrue(trueTerminal.backlogIDs.contains("ch06g_all_routes_montage"))
        XCTAssertTrue(trueTerminal.backlogIDs.contains("ch06h_final_evidence_board"))

        let boxRoute = [
            "prologue_accept",
            "notebook_close_gently",
            "airi_defend_sea",
            "yuka_hide",
            "shadow_reject",
            "rooftop_hold_hand",
            "archive_meet_sea",
            "room_accept",
            "threshold_step_inside",
            "station_clock_keep_weekend"
        ]
        XCTAssertEqual(try TestSupport.endingID(for: boxRoute, package: package), "box")
        XCTAssertEqual(try TestSupport.terminalSceneID(for: boxRoute, package: package).sceneID, "ending_box")

        let collapseRoute = [
            "prologue_accept",
            "notebook_run",
            "airi_stay",
            "yuka_tell_airi",
            "shadow_leave_airi_signal",
            "rooftop_airi_call",
            "archive_airi_escape",
            "room_call_airi",
            "threshold_leave_mark_airi",
            "station_clock_drop_airi_note"
        ]
        XCTAssertEqual(try TestSupport.endingID(for: collapseRoute, package: package), "collapse")
        XCTAssertEqual(try TestSupport.terminalSceneID(for: collapseRoute, package: package).sceneID, "ending_collapse")

        let ghostRoute = [
            "prologue_refuse",
            "notebook_ask",
            "airi_diary_detail",
            "yuka_cooperate",
            "shadow_report_yuka",
            "rooftop_ask_shadow",
            "archive_shadow_file",
            "room_escape",
            "threshold_leave_recording_yuka",
            "station_clock_send_yuka_time"
        ]
        XCTAssertEqual(try TestSupport.endingID(for: ghostRoute, package: package), "ghost")
        XCTAssertEqual(try TestSupport.terminalSceneID(for: ghostRoute, package: package).sceneID, "ending_ghost")

        let abyssRoute = [
            "prologue_accept",
            "notebook_run",
            "airi_defend_sea",
            "yuka_hide",
            "shadow_ask_how_to_keep",
            "rooftop_hold_hand",
            "archive_meet_sea",
            "room_accept",
            "threshold_answer_with_sea",
            "station_clock_forget_weekday"
        ]
        XCTAssertEqual(try TestSupport.endingID(for: abyssRoute, package: package), "abyss")
        XCTAssertEqual(try TestSupport.terminalSceneID(for: abyssRoute, package: package).sceneID, "ending_abyss")
    }
}
