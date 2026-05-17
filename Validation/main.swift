import AppKit
import Foundation
import WeekendRainCore

enum ValidationFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw ValidationFailure.failed(message)
    }
}

func evaluateEnding(package: StoryPackage, stats: GameStats, tags: [String: Int] = [:]) -> EndingRule? {
    let matches = package.endings
        .filter { $0.matches(stats: stats, tagCounts: tags) }
        .sorted { $0.priority < $1.priority }

    return matches.first ?? package.endings.first { $0.id == package.metadata.defaultEnding }
}

func endingID(for choices: [String], package: StoryPackage) throws -> String {
    let manager = GameStateManager()
    manager.load(package: package)

    for choiceID in choices {
        advanceUntilChoice(manager)
        guard manager.availableChoices().contains(where: { $0.id == choiceID }) else {
            let sceneID = manager.currentScene?.id ?? "nil"
            throw ValidationFailure.failed("Choice \(choiceID) is not available at \(sceneID)")
        }
        manager.choose(choiceID: choiceID)
    }

    guard let endingID = manager.evaluateEnding()?.id else {
        throw ValidationFailure.failed("No ending resolved for route")
    }
    return endingID
}

func terminalSceneID(for choices: [String], package: StoryPackage) throws -> (sceneID: String, backlogIDs: Set<String>) {
    let manager = GameStateManager()
    manager.load(package: package)

    for choiceID in choices {
        advanceUntilChoice(manager)
        guard manager.availableChoices().contains(where: { $0.id == choiceID }) else {
            let sceneID = manager.currentScene?.id ?? "nil"
            throw ValidationFailure.failed("Choice \(choiceID) is not available at \(sceneID)")
        }
        manager.choose(choiceID: choiceID)
    }

    var remainingSteps = 80
    while let scene = manager.currentScene, !scene.isEndingScene, remainingSteps > 0 {
        remainingSteps -= 1
        switch manager.phase {
        case .presentingLine:
            manager.finishPresentingLine()
        case .transitioning:
            manager.advanceToNextScene()
        case .awaitingChoice:
            throw ValidationFailure.failed("Unexpected extra choice at \(scene.id)")
        case .loading, .backlog, .gallery, .ending:
            break
        }
    }

    guard remainingSteps > 0 else {
        throw ValidationFailure.failed("Route did not reach a terminal ending")
    }

    guard let sceneID = manager.currentScene?.id else {
        throw ValidationFailure.failed("Route ended without current scene")
    }

    return (sceneID, Set(manager.backlog.map(\.sceneID)))
}

func advanceUntilChoice(_ manager: GameStateManager) {
    while manager.availableChoices().isEmpty,
          let scene = manager.currentScene,
          !scene.isEndingScene,
          scene.nextScene != nil {
        manager.advanceToNextScene()
    }
}

func checkImageAsset(_ asset: VisualAsset, role: VisualAssetRenderer.Role, baseURL: URL) throws {
    let url = baseURL.appendingPathComponent(asset.path)
    try check(FileManager.default.fileExists(atPath: url.path), "Missing image file: \(asset.path)")
    guard let image = NSImage(contentsOf: url) else {
        throw ValidationFailure.failed("Image failed to load: \(asset.path)")
    }
    try check(image.size.width > 0 && image.size.height > 0, "Invalid image dimensions: \(asset.path)")

    let rendered = VisualAssetRenderer.image(for: asset, baseURL: baseURL, role: role)
    try check(rendered.size.width > 0 && rendered.size.height > 0, "Renderer failed for asset: \(asset.id)")
}

func checkTransparentCharacter(_ asset: VisualAsset, baseURL: URL) throws {
    let url = baseURL.appendingPathComponent(asset.path)
    guard
        let image = NSImage(contentsOf: url),
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff)
    else {
        throw ValidationFailure.failed("Transparent character failed to decode: \(asset.path)")
    }

    try check(bitmap.hasAlpha, "Character sprite must have alpha: \(asset.path)")
    let maxX = bitmap.pixelsWide - 1
    let maxY = bitmap.pixelsHigh - 1
    let corners = [
        bitmap.colorAt(x: 0, y: 0)?.alphaComponent,
        bitmap.colorAt(x: maxX, y: 0)?.alphaComponent,
        bitmap.colorAt(x: 0, y: maxY)?.alphaComponent,
        bitmap.colorAt(x: maxX, y: maxY)?.alphaComponent
    ]

    try check(corners.allSatisfy { ($0 ?? 1) <= 0.01 }, "Character sprite corners are not transparent: \(asset.path)")
}

func runValidation() throws {
    guard let storyURL = StoryLoader.defaultStoryURL() else {
        throw ValidationFailure.failed("Missing ExternalContent/Stories/weekend_rain.story.json")
    }

    let package = try StoryLoader().loadStory(at: storyURL)
    let contentBaseURL = storyURL.deletingLastPathComponent().deletingLastPathComponent()
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
    try check(legacyScene.visuals.isEmpty, "Legacy scene without visuals should decode with empty visuals")
    try check(
        legacyScene.stageVisuals == [SceneVisual(type: .character, id: "sea_normal", position: .center)],
        "Legacy scene should fall back to centered character staging"
    )
    try check(package.schemaVersion == 1, "schema_version should be 1")
    try check(package.metadata.storyID == "weekend_rain.v1", "Unexpected story id")
    try check(package.worldFoundation.cityName.contains("Rainveil City"), "World foundation city missing")
    try check(package.worldFoundation.annualRainDays == 300, "Rainveil annual rain days changed")
    try check(package.worldFoundation.emotionalLaw.contains("3배"), "World emotional law missing")
    try check(package.archetypes.count == 4, "Expected four character archetypes")
    try check(package.archetypes.map(\.id) == ["obsessor", "refugee", "catalyst", "shadow"], "Unexpected archetype order")
    try check(
        package.archetypes.first(where: { $0.id == "obsessor" })?.visualRule.contains("빨간색") == true,
        "Obsessor red visual rule missing"
    )
    try check(package.sceneIndex[package.metadata.startScene] != nil, "Missing start scene")
    try check(package.sceneIndex[package.metadata.finalScene] != nil, "Missing final scene")
    try check(package.endingIndex[package.metadata.defaultEnding] != nil, "Missing default ending rule")
    try check(package.statBounds.initial == GameStats.defaults, "Unexpected initial stats")
    try check(package.scenes.count >= 106, "Expanded story should include at least 106 scenes including endings")
    try check(package.assets.backgrounds.count >= 96, "Expected expanded background set")
    try check(package.assets.characters.count >= 74, "Expected expanded character image set")
    try check(package.assets.cg.count >= 106, "Expected expanded CG image set")

    let sceneTextLengths = package.scenes.map { $0.text.count }
    let averageSceneTextLength = Double(sceneTextLengths.reduce(0, +)) / Double(max(sceneTextLengths.count, 1))
    try check((sceneTextLengths.min() ?? 0) >= 200, "Scene text is too short for VN pacing (min 200 chars required)")
    try check(averageSceneTextLength >= 240, "Average scene text is too short for VN pacing (240 chars required)")
    let choiceTextLengths = package.scenes.flatMap { $0.choices.map { $0.text.count } }
    try check((choiceTextLengths.max() ?? 0) <= 18, "Choice labels should be short action verbs")

    let forbiddenSceneTerms = [
        "플레이어", "미연시", "선택지", "루트", "분기", "CG", "갤러리",
        "데이트 보상", "호감도", "집착도", "엔딩 조건", "트루",
        "Love", "Yandere", "Sanity", "비가시 태그", "판정 장면",
        "저장/로드", "중반부", "후반부", "클라이맥스", "이 구간", "이 장",
        "같은 컷", "다음 장면", "악역", "정답지", "화면은", "암전"
    ]
    for scene in package.scenes {
        let hits = forbiddenSceneTerms.filter { scene.text.contains($0) }
        let hitList = hits.joined(separator: ", ")
        try check(hits.isEmpty, "Scene \(scene.id) contains non-diegetic terms: \(hitList)")
        let prose = ([scene.speaker, scene.text] + scene.choices.map(\.text))
            .joined(separator: "\n")
            .replacingOccurrences(of: "Rainveil", with: "")
            .replacingOccurrences(of: "City", with: "")
        try check(
            prose.range(of: "[A-Za-z]", options: .regularExpression) == nil,
            "Scene \(scene.id) contains non-Korean Latin prose"
        )
        try check(
            scene.text.filter { $0 == "“" }.count == scene.text.filter { $0 == "”" }.count,
            "Scene \(scene.id) has unbalanced dialogue quotes"
        )
        try check(
            scene.text.filter { $0 == "‘" }.count == scene.text.filter { $0 == "’" }.count,
            "Scene \(scene.id) has unbalanced emphasis quotes"
        )
        if !scene.choices.isEmpty {
            try check(scene.decisionTitle?.isEmpty == false, "Choice scene \(scene.id) is missing decision_title")
            try check(scene.effects.contains("decision_moment"), "Choice scene \(scene.id) missing decision_moment effect")
        }
    }

    func checkAssetPath(_ asset: VisualAsset?, id: String, expectedPath: String) throws {
        try check(asset?.path == expectedPath, "Visual asset \(id) should use \(expectedPath), got \(asset?.path ?? "nil")")
    }

    try checkAssetPath(
        package.assets.backgrounds["rain_street"],
        id: "rain_street",
        expectedPath: "Assets/BG/confession_booth_alley.png"
    )
    try checkAssetPath(
        package.assets.backgrounds["bus_stop_evening"],
        id: "bus_stop_evening",
        expectedPath: "Assets/BG/shoe_locker_surveillance.png"
    )
    try checkAssetPath(
        package.assets.backgrounds["retro_arcade"],
        id: "retro_arcade",
        expectedPath: "Assets/BG/negative_sorting_arcade.png"
    )
    try checkAssetPath(
        package.assets.backgrounds["water_tower"],
        id: "water_tower",
        expectedPath: "Assets/BG/flood_siren_tower.png"
    )
    try checkAssetPath(
        package.assets.cg["cg_umbrella_gate"],
        id: "cg_umbrella_gate",
        expectedPath: "Assets/CG/cg_umbrella_memorial.png"
    )
    try checkAssetPath(
        package.assets.cg["cg_notebook_names"],
        id: "cg_notebook_names",
        expectedPath: "Assets/CG/cg_locker_charm_camera.png"
    )
    try checkAssetPath(
        package.assets.cg["cg_box"],
        id: "cg_box",
        expectedPath: "Assets/CG/cg_blanket_chain_knot.png"
    )
    try checkAssetPath(
        package.assets.characters["sea_normal"],
        id: "sea_normal",
        expectedPath: "Assets/Character/sea_station_clock.png"
    )
    try checkAssetPath(
        package.assets.characters["sea_tender_close"],
        id: "sea_tender_close",
        expectedPath: "Assets/Character/sea_orchid_umbrella_handle.png"
    )
    try checkAssetPath(
        package.assets.characters["sea_anxious"],
        id: "sea_anxious",
        expectedPath: "Assets/Character/sea_charm_camera.png"
    )

    let sceneVisualExpectations: [String: (background: String?, character: String?)] = [
        "prologue_rain_gate": ("shoe_locker_surveillance", "sea_station_clock"),
        "ch00_shared_umbrella": ("shoe_locker_surveillance", "sea_orchid_umbrella_handle"),
        "ch01_notebook": ("student_council_interrogation_room", "sea_charm_camera"),
        "ch02_airi_warning": ("student_council_interrogation_room", "airi_locker_evidence"),
        "ch03j_neon_koi_market": ("neon_koi_market", "sea_cablecar_token"),
        "ch03k_rain_mineral_mint": ("rain_mineral_mint", "yuka_rain_orchid_lab"),
        "ch04_rooftop_confession": ("school_rooftop", "sea_rooftop_thread"),
        "ch05e_rooftop_greenhouse": ("rooftop_greenhouse", "sea_orchid_umbrella_handle"),
        "ch05i_flood_siren_tower": ("flood_siren_tower", "airi_resolve"),
        "ch05m_tide_lock_gate": ("tide_lock_gate", "shadow_mineral_key"),
        "ch06d_final_crosswalk": ("final_crosswalk", "airi_resolve")
    ]
    for (sceneID, expected) in sceneVisualExpectations {
        guard let scene = package.sceneIndex[sceneID] else {
            throw ValidationFailure.failed("Missing visual expectation scene: \(sceneID)")
        }
        if let background = expected.background {
            try check(scene.background == background, "Scene \(sceneID) should use background \(background), got \(scene.background ?? "nil")")
        }
        if let character = expected.character {
            try check(scene.character == character, "Scene \(sceneID) should use character \(character), got \(scene.character ?? "nil")")
        }
    }

    func checkSceneVisuals(_ sceneID: String, expected: [(String, SceneVisualPosition)]) throws {
        guard let scene = package.sceneIndex[sceneID] else {
            throw ValidationFailure.failed("Missing staged visual scene: \(sceneID)")
        }
        let actual = scene.visuals.map { ($0.id, $0.position) }
        try check(
            actual.elementsEqual(expected, by: { $0.0 == $1.0 && $0.1 == $1.1 }),
            "Scene \(sceneID) staged visuals mismatch: \(actual)"
        )
    }

    try checkSceneVisuals(
        "ch02_airi_warning",
        expected: [("airi_locker_evidence", .left), ("sea_charm_camera", .right)]
    )
    try checkSceneVisuals(
        "ch03_yuka_investigation",
        expected: [("sea_mural_reflection", .left), ("yuka_lab_coat", .right)]
    )
    try checkSceneVisuals(
        "ch05z_a_final_corridor",
        expected: [("airi_resolve", .left), ("sea_threshold", .right)]
    )
    try checkSceneVisuals(
        "ch06f_weekend_station_clock",
        expected: [("airi_resolve", .left), ("sea_station_clock", .center), ("yuka_weather_terminal", .right)]
    )

    for assetID in [
        "sea_wall_mural",
        "maintenance_elevator",
        "rain_clinic_records",
        "weather_control_room",
        "ferry_pier",
        "flood_siren_tower",
        "weekend_station_clock",
        "weather_server_nave",
        "umbrella_memorial_canal",
        "railway_signal_box",
        "tide_lock_gate",
        "confession_booth_alley",
        "submerged_cinema",
        "dead_letter_sorting_room",
        "clinical_observation_ward",
        "rain_sample_vault",
        "student_council_interrogation_room",
        "kimono_repair_atelier",
        "neon_koi_market",
        "rain_mineral_mint",
        "roof_access_stairwell",
        "rain_letterpress_archive",
        "rain_scent_stationery_lab",
        "shrine_knot_printshop",
        "photo_booth_darkroom",
        "negative_sorting_arcade",
        "teacup_display_corridor",
        "flood_post_office",
        "vending_chapel_underpass",
        "sleeping_carriage_depot",
        "microfilm_reservoir_archive",
        "rain_switchboard_exchange",
        "automaton_doll_repair_studio",
        "rain_seed_vault",
        "underground_observation_aquarium",
        "moss_generator_room",
        "emotion_weather_bureau",
        "umbrella_wash_laundromat",
        "aerial_cablecar_transfer",
        "shoe_locker_surveillance",
        "counseling_recording_room",
        "rooftop_antenna_shrine",
        "black_umbrella_tollbooth",
        "forgotten_name_registry",
        "rain_pawnshop_counter",
        "rooftop_rain_gauge_deck",
        "abandoned_indoor_pool",
        "home_ec_tatami_room",
        "blanket_chain_inventory",
        "condensation_window_map",
        "broken_music_box_altar"
    ] {
        guard let asset = package.assets.backgrounds[assetID] else {
            throw ValidationFailure.failed("Missing generated background metadata: \(assetID)")
        }
        try checkImageAsset(asset, role: .background, baseURL: contentBaseURL)
    }

    for assetID in [
        "cg_sea_wall_mural",
        "cg_maintenance_elevator",
        "cg_rain_clinic_records",
        "cg_weather_control_room",
        "cg_ferry_pier",
        "cg_flood_siren_tower",
        "cg_weekend_station_clock",
        "cg_rainveil_final_evidence",
        "cg_rainveil_evidence_desk",
        "cg_umbrella_memorial",
        "cg_signal_red_thread",
        "cg_rooftop_red_thread",
        "cg_tide_lock_key",
        "cg_confession_cassette",
        "cg_submerged_cinema_memory",
        "cg_dead_letter_bundle",
        "cg_emotion_waveform_chart",
        "cg_rain_sample_vials",
        "cg_interrogation_table_ribbon",
        "cg_red_thread_spool",
        "cg_mineral_koi_scale",
        "cg_watermark_letter",
        "cg_red_envelope_scanner",
        "cg_postmark_route_map",
        "cg_shrine_knot_fibers",
        "cg_red_fourth_photo",
        "cg_negative_route_grid",
        "cg_teacup_missing_frame",
        "cg_pneumatic_love_letters",
        "cg_vending_chapel_offering",
        "cg_sleeping_carriage_route_map",
        "cg_microfilm_rain_records",
        "cg_switchboard_red_cable",
        "cg_doll_hand_red_thread",
        "cg_rain_orchid_seed",
        "cg_underwater_umbrella_fragment",
        "cg_generator_red_ribbon",
        "cg_emotion_barometer",
        "cg_umbrella_wash_residue",
        "cg_cablecar_token_thread",
        "cg_locker_charm_camera",
        "cg_counseling_cassette_thread",
        "cg_antenna_signal_charm",
        "cg_black_umbrella_receipt",
        "cg_forgotten_name_card",
        "cg_pawnshop_red_key",
        "cg_rooftop_rain_gauge",
        "cg_pool_red_whistle",
        "cg_tatami_red_stitch",
        "cg_blanket_chain_knot",
        "cg_condensation_window_map",
        "cg_music_box_red_key"
    ] {
        guard let asset = package.assets.cg[assetID] else {
            throw ValidationFailure.failed("Missing generated CG metadata: \(assetID)")
        }
        try checkImageAsset(asset, role: .cg, baseURL: contentBaseURL)
    }

    for assetID in [
        "sea_station_clock",
        "yuka_weather_terminal",
        "shadow_siren_tower",
        "airi_confession_note",
        "sea_confession_cassette",
        "yuka_clinic_vial",
        "sea_clinic_consent",
        "sea_rooftop_thread",
        "shadow_mineral_key",
        "airi_wet_envelope",
        "yuka_postmark_scanner",
        "sea_photo_strip",
        "airi_torn_photo",
        "yuka_archive_lantern",
        "sea_red_ticket",
        "airi_switchboard_receiver",
        "shadow_doll_thread",
        "yuka_rain_orchid_lab",
        "sea_orchid_umbrella_handle",
        "yuka_weather_raincoat",
        "sea_cablecar_token",
        "airi_locker_evidence",
        "sea_charm_camera",
        "shadow_receipt_ledger",
        "sea_name_card",
        "sea_rain_gauge_vial",
        "airi_pool_whistle",
        "sea_blanket_thread",
        "yuka_window_flashlight"
    ] {
        guard let asset = package.assets.characters[assetID] else {
            throw ValidationFailure.failed("Missing generated character metadata: \(assetID)")
        }
        try checkImageAsset(asset, role: .character, baseURL: contentBaseURL)
        try checkTransparentCharacter(asset, baseURL: contentBaseURL)
    }

    try check(
        evaluateEnding(
            package: package,
            stats: GameStats(love: 100, yandere: 100, sanity: 0),
            tags: ["yuka": 3, "truth": 3, "airi": 3]
        )?.id == "abyss",
        "Abyss ending priority failed"
    )

    try check(
        evaluateEnding(
            package: package,
            stats: GameStats(love: 30, yandere: 20, sanity: 80),
            tags: ["yuka": 3, "truth": 3]
        )?.id == "ghost",
        "Ghost ending condition failed"
    )

    try check(
        evaluateEnding(package: package, stats: GameStats(love: 95, yandere: 95, sanity: 30))?.id == "box",
        "Box ending condition failed"
    )

    try check(
        evaluateEnding(
            package: package,
            stats: GameStats(love: 40, yandere: 60, sanity: 60),
            tags: ["airi": 3]
        )?.id == "collapse",
        "Collapse ending condition failed"
    )

    try check(
        evaluateEnding(package: package, stats: GameStats(love: 95, yandere: 20, sanity: 80))?.id == "true",
        "True ending condition failed"
    )

    let trueRoute = try endingID(for: [
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
    ], package: package)
    try check(trueRoute == "true", "True route sequence failed")
    let trueTerminal = try terminalSceneID(for: [
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
    ], package: package)
    try check(trueTerminal.sceneID == "ending_true", "True route should reach ending_true, got \(trueTerminal.sceneID)")
    try check(trueTerminal.backlogIDs.contains("ch06g_all_routes_montage"), "True route should pass final montage bridge")
    try check(trueTerminal.backlogIDs.contains("ch06h_final_evidence_board"), "True route should pass final evidence board")

    let boxRoute = try endingID(for: [
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
    ], package: package)
    try check(boxRoute == "box", "Yandere box route sequence failed")
    let boxTerminal = try terminalSceneID(for: [
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
    ], package: package)
    try check(boxTerminal.sceneID == "ending_box", "Box route should reach ending_box")

    let collapseRoute = try endingID(for: [
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
    ], package: package)
    try check(collapseRoute == "collapse", "Airi bad route sequence failed")
    let collapseTerminal = try terminalSceneID(for: [
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
    ], package: package)
    try check(collapseTerminal.sceneID == "ending_collapse", "Collapse route should reach ending_collapse")

    let ghostRoute = try endingID(for: [
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
    ], package: package)
    try check(ghostRoute == "ghost", "Hidden ghost route sequence failed")
    let ghostTerminal = try terminalSceneID(for: [
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
    ], package: package)
    try check(ghostTerminal.sceneID == "ending_ghost", "Ghost route should reach ending_ghost")

    let abyssRoute = try endingID(for: [
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
    ], package: package)
    try check(abyssRoute == "abyss", "Abyss route sequence failed")
    let abyssTerminal = try terminalSceneID(for: [
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
    ], package: package)
    try check(abyssTerminal.sceneID == "ending_abyss", "Abyss route should reach ending_abyss")

    var stats = GameStats(love: 95, yandere: 2, sanity: 50)
    stats.apply(StatDelta(love: 20, yandere: -10, sanity: -100), bounds: package.statBounds.range)
    try check(stats == GameStats(love: 100, yandere: 0, sanity: 0), "Stat clamp failed")

    let manager = GameStateManager()
    manager.load(package: package)
    advanceUntilChoice(manager)
    manager.choose(choiceID: "prologue_accept")
    try check(manager.selectedTagCounts["sea_accept"] == 1, "Tag count failed")
    try check(manager.stats.love == 35 && manager.stats.yandere == 20, "Choice delta failed")

    let save = GameSave(
        storyID: package.metadata.storyID,
        sceneID: "ch04_rooftop_confession",
        stats: GameStats(love: 70, yandere: 25, sanity: 80),
        selectedTagCounts: ["truth": 2, "yuka": 1],
        backlog: [BacklogEntry(sceneID: "prologue_rain_gate", speaker: "세아", text: "우산 없어?", kind: .line)],
        unlockedCG: ["cg_true_rainbow"],
        thumbnailPath: "thumbs/save1.png"
    )
    let data = try NSKeyedArchiver.archivedData(withRootObject: save, requiringSecureCoding: true)
    guard let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: GameSave.self, from: data) else {
        throw ValidationFailure.failed("GameSave unarchive returned nil")
    }
    try check(restored.stats == save.stats, "GameSave stats round trip failed")
    try check(restored.backlog == save.backlog, "GameSave backlog round trip failed")
    try check(restored.unlockedCG == save.unlockedCG, "GameSave CG round trip failed")

    _ = NSApplication.shared
    let novelView = NovelSceneView(frame: NSRect(x: 0, y: 0, width: 960, height: 540))
    try check(novelView.rainView.superview === novelView, "NovelSceneView rain overlay missing")
    if let responsiveScene = package.sceneIndex["ch06f_weekend_station_clock"] {
        for size in [
            NSSize(width: 820, height: 520),
            NSSize(width: 1180, height: 720),
            NSSize(width: 1600, height: 950)
        ] {
            let responsiveView = NovelSceneView(frame: NSRect(origin: .zero, size: size))
            responsiveView.render(
                scene: responsiveScene,
                phase: .awaitingChoice,
                stats: GameStats(love: 88, yandere: 72, sanity: 44),
                choices: responsiveScene.choices,
                assets: package.assets,
                contentBaseURL: contentBaseURL
            )
            responsiveView.layoutSubtreeIfNeeded()
            try check(responsiveView.frame.size == size, "NovelSceneView responsive layout changed frame at \(size)")
        }
    }
    let backlog = BacklogViewController(entries: save.backlog)
    _ = backlog.view
    try check(backlog.view.bounds.width > 0, "Backlog view failed to load")
    let asset = Array(package.assets.cg.values).first!
    let gallery = GalleryViewController(assets: [asset], unlockedCG: [asset.id], contentBaseURL: contentBaseURL)
    _ = gallery.view
    try check(gallery.view.bounds.height > 0, "Gallery view failed to load")
}

do {
    try runValidation()
    print("WeekendRainValidation passed")
} catch {
    fputs("WeekendRainValidation failed: \(error)\n", stderr)
    exit(1)
}
