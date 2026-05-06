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
    try check(package.statBounds.initial == GameStats.defaults, "Unexpected initial stats")
    try check(package.scenes.count >= 106, "Expanded story should include at least 106 scenes including endings")
    try check(package.assets.backgrounds.count >= 96, "Expected expanded background set")
    try check(package.assets.characters.count >= 74, "Expected expanded character image set")
    try check(package.assets.cg.count >= 106, "Expected expanded CG image set")

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
        "umbrella_ask_red",
        "water_tower_touch",
        "letter_exchange_read_postmark",
        "stationery_compare_ink",
        "clock_set_current_time",
        "tram_validate_ticket",
        "mural_read_old_signature",
        "notebook_ask",
        "arcade_ask_initials",
        "kiosk_counsel_truth",
        "radio_trace_signal",
        "lost_umbrella_check_tags",
        "cassette_decode_label",
        "server_compare_timestamps",
        "elevator_check_floor_log",
        "airi_diary_detail",
        "locker_catalog_camera",
        "counseling_play_raw_tape",
        "antenna_ground_signal",
        "call_tell_sea_truth",
        "aquarium_read_plaque",
        "infirmary_check_pulse",
        "laundromat_wash_ribbon",
        "skybridge_hold_present",
        "hospital_breathe_clear_air",
        "clinic_read_consent_form",
        "observation_keep_chart",
        "sample_compare_clear_vial",
        "interrogation_record_all",
        "yuka_tell_airi",
        "shadow_listen_recorder",
        "tollbooth_refuse_shadow_fee",
        "registry_keep_current_name",
        "pawnshop_reject_red_key",
        "library_show_airi",
        "memory_name_current",
        "deck_count_real_lights",
        "museum_read_captions",
        "basement_match_birth_records",
        "weather_stop_loop_protocol",
        "bureau_ground_love_signal",
        "wash_return_wrong_umbrella",
        "cablecar_cut_return_thread",
        "atelier_unwind_thread",
        "koi_test_clear_scale",
        "mint_hold_letter_to_light",
        "stairwell_drop_red_thread",
        "rooftop_boundary",
        "gauge_measure_real_rain",
        "pool_keep_exit_lane",
        "tatami_return_uniform_unstitched",
        "letter_return_gently",
        "archive_compare_letter_fibers",
        "lab_separate_scent",
        "printshop_untie_pattern",
        "shrine_untie",
        "photo_keep_one_each",
        "darkroom_split_frame",
        "negative_count_real_frames",
        "corridor_reflect_clear_tea",
        "teahouse_brew_clear_water",
        "phone_call_sea_now",
        "bridge_return_reflection",
        "pier_wait_for_real_boat",
        "confession_play_raw_tape",
        "cinema_watch_hallway_memory",
        "deadletter_read_unsent_names",
        "microfilm_read_rain_records",
        "switchboard_call_present_number",
        "doll_remove_red_thread",
        "archive_read",
        "apartment_take_down",
        "platform_between",
        "lab_stabilize",
        "greenhouse_open_roof",
        "seed_vault_catalog_orchid",
        "aquarium_measure_pressure",
        "generator_ground_red_circuit",
        "tunnel_break_water_flow",
        "cathedral_open_valve",
        "reservoir_open_spillway",
        "siren_disable_alarm",
        "server_nave_preserve_log",
        "memorial_read_tags",
        "signal_cut_red_thread",
        "tide_release_clear_water",
        "postoffice_dispatch_clear_letters",
        "chapel_pay_exact_fare",
        "carriage_map_exit_track",
        "room_soothe",
        "blanket_uncover_chain_knot",
        "window_trace_real_exit",
        "musicbox_stop_lullaby",
        "threshold_name_sea_present",
        "umbrella_return_lower_it",
        "crosswalk_wait_green",
        "bus_step_off_loop",
        "station_clock_start_monday"
    ], package: package)
    try check(trueRoute == "true", "True route sequence failed")

    let boxRoute = try endingID(for: [
        "prologue_accept",
        "umbrella_silence",
        "water_tower_keep_rain",
        "letter_exchange_keep_sea_note",
        "stationery_buy_red_pen",
        "clock_accept_stopped_watch",
        "tram_ride_with_sea",
        "mural_paint_red_umbrella",
        "notebook_close_gently",
        "arcade_play_with_sea",
        "kiosk_delete_log",
        "radio_dedicate_song",
        "lost_umbrella_take_red_one",
        "cassette_buy_sea_song",
        "server_delete_for_sea",
        "elevator_hold_sea_button",
        "airi_defend_sea",
        "locker_hide_camera_for_sea",
        "counseling_keep_sea_confession",
        "antenna_keep_private_channel",
        "call_delete_airi",
        "aquarium_hold_red",
        "infirmary_hide_symptoms",
        "laundromat_keep_scent",
        "skybridge_cover_sea_eyes",
        "hospital_share_raindrop",
        "clinic_sign_for_sea",
        "observation_sign_with_sea",
        "sample_keep_sea_vial_warm",
        "interrogation_protect_sea_statement",
        "yuka_hide",
        "shadow_reject",
        "tollbooth_pay_with_sea_memory",
        "registry_write_two_names",
        "pawnshop_buy_red_key_for_sea",
        "library_burn_page",
        "memory_choose_sea_only",
        "deck_promise_only_two",
        "museum_hide_sea_photo",
        "basement_hide_record",
        "weather_keep_weekend_rain",
        "bureau_loop_weekend_forecast",
        "wash_keep_sea_handle_warm",
        "cablecar_share_single_token",
        "atelier_accept_red_measure",
        "koi_buy_red_umbrella_charm",
        "mint_stamp_two_names",
        "stairwell_keep_sea_hand",
        "rooftop_hold_hand",
        "gauge_keep_sea_vial_warm",
        "pool_lock_lane_with_sea",
        "tatami_accept_matching_stitch",
        "letter_return_gently",
        "archive_keep_envelope_warm",
        "lab_bottle_sea_scent",
        "printshop_print_two_names",
        "shrine_tie_forever",
        "photo_keep_couple_strip",
        "darkroom_keep_all_frames",
        "negative_sea_only_album",
        "corridor_drink_same_reflection",
        "teahouse_drink_same_cup",
        "phone_cut_outside",
        "bridge_stay_under_umbrella",
        "pier_board_with_sea",
        "confession_record_sea_only",
        "cinema_sit_with_sea_projection",
        "deadletter_seal_haru_sea",
        "microfilm_hide_sea_frame",
        "switchboard_patch_sea_only",
        "doll_keep_matching_hand",
        "archive_meet_sea",
        "apartment_leave_wall",
        "platform_yuka_leads",
        "lab_stabilize",
        "greenhouse_lock_inside",
        "seed_vault_keep_orchid_warm",
        "aquarium_watch_with_sea",
        "generator_lock_power_for_two",
        "tunnel_follow_sea_voice",
        "cathedral_kneel_with_sea",
        "reservoir_close_gate",
        "siren_play_sea_song",
        "server_nave_sea_delete_trace",
        "memorial_choose_red_umbrella",
        "signal_tie_new_knot",
        "tide_lock_key_with_sea",
        "postoffice_keep_sea_letters",
        "chapel_buy_red_charm",
        "carriage_sleep_next_to_sea",
        "room_accept",
        "blanket_accept_soft_restraint",
        "window_write_two_initials",
        "musicbox_keep_lullaby_playing",
        "threshold_step_inside",
        "umbrella_return_close_world",
        "crosswalk_cross_red_together",
        "bus_keep_seat_for_sea",
        "station_clock_keep_weekend"
    ], package: package)
    try check(boxRoute == "box", "Yandere box route sequence failed")

    let collapseRoute = try endingID(for: [
        "prologue_accept",
        "umbrella_message_airi",
        "water_tower_airi_memory",
        "letter_exchange_show_airi",
        "stationery_call_airi",
        "clock_call_airi_memory",
        "tram_text_airi_platform",
        "mural_send_airi_signature",
        "notebook_run",
        "arcade_invite_airi",
        "kiosk_airi_backup",
        "radio_call_airi",
        "lost_umbrella_wait_airi",
        "cassette_airi_voice",
        "server_send_airi_warning",
        "elevator_call_airi",
        "airi_stay",
        "locker_airi_keep_handkerchief",
        "counseling_airi_record_warning",
        "antenna_airi_call_emergency_line",
        "call_promise_airi",
        "aquarium_airi_warning",
        "infirmary_call_airi",
        "laundromat_answer_airi",
        "skybridge_wait_airi",
        "hospital_wait_airi",
        "clinic_call_airi_guardian",
        "observation_call_airi_baseline",
        "sample_airi_safety_photo",
        "interrogation_airi_keep_ribbon",
        "yuka_tell_airi",
        "shadow_listen_recorder",
        "tollbooth_leave_airi_coin",
        "registry_mark_airi_witness",
        "pawnshop_hide_airi_receipt",
        "library_show_airi",
        "memory_follow_airi_voice",
        "deck_share_location_airi",
        "museum_call_airi_witness",
        "basement_call_airi_witness",
        "weather_alert_airi",
        "bureau_airi_public_alert",
        "wash_airi_claim_ticket",
        "cablecar_airi_emergency_bell",
        "atelier_call_airi_tailor",
        "koi_send_airi_location",
        "mint_keep_airi_exit_map",
        "stairwell_leave_airi_pin",
        "rooftop_airi_call",
        "gauge_send_airi_reading",
        "pool_follow_airi_whistle",
        "tatami_hide_airi_thread",
        "letter_show_airi",
        "archive_call_airi_match",
        "lab_airi_keep_sample",
        "printshop_airi_exit_charm",
        "shrine_pray_airi",
        "photo_send_airi",
        "darkroom_airi_mark_exit",
        "negative_airi_backup_strip",
        "corridor_leave_airi_teacup",
        "teahouse_leave_airi_note",
        "phone_call_airi",
        "bridge_leave_airi_marker",
        "pier_leave_airi_ticket",
        "confession_airi_witness_line",
        "cinema_mark_airi_empty_seat",
        "deadletter_save_airi_note",
        "microfilm_send_airi_frame",
        "switchboard_leave_airi_line",
        "doll_tie_airi_warning",
        "archive_airi_escape",
        "apartment_call_airi",
        "platform_between",
        "lab_call_airi",
        "greenhouse_wait_airi",
        "seed_vault_airi_sample",
        "aquarium_airi_surface_signal",
        "generator_airi_flash_backup",
        "tunnel_wait_airi_rescue",
        "cathedral_mark_airi_exit",
        "reservoir_signal_airi",
        "siren_flash_airi_code",
        "server_nave_send_airi_backup",
        "memorial_hide_airi_tag",
        "signal_mark_airi_route",
        "tide_send_airi_beacon",
        "postoffice_airi_forward_warning",
        "chapel_leave_airi_coin",
        "carriage_mark_airi_seat",
        "room_call_airi",
        "blanket_leave_airi_corner",
        "window_mark_airi_breath_path",
        "musicbox_hide_airi_pin",
        "threshold_leave_mark_airi",
        "umbrella_return_airi_signal",
        "crosswalk_drop_airi_pin",
        "bus_drop_airi_ticket",
        "station_clock_drop_airi_note"
    ], package: package)
    try check(collapseRoute == "collapse", "Airi bad route sequence failed")

    let ghostRoute = try endingID(for: [
        "prologue_refuse",
        "umbrella_ask_red",
        "water_tower_touch",
        "letter_exchange_read_postmark",
        "stationery_compare_ink",
        "clock_set_current_time",
        "tram_validate_ticket",
        "mural_read_old_signature",
        "notebook_ask",
        "arcade_ask_initials",
        "kiosk_yuka_export",
        "radio_record_yuka",
        "lost_umbrella_scan_yuka",
        "cassette_send_yuka_index",
        "server_export_yuka_logs",
        "elevator_export_yuka_log",
        "airi_diary_detail",
        "locker_yuka_scan_lens",
        "counseling_yuka_extract_voiceprint",
        "antenna_yuka_trace_signal_map",
        "call_ask_yuka",
        "aquarium_read_plaque",
        "infirmary_save_chart",
        "laundromat_read_receipt",
        "skybridge_send_camera_yuka",
        "hospital_send_yuka_vitals",
        "clinic_send_yuka_chart",
        "observation_yuka_scan_waveform",
        "sample_yuka_catalog_vial",
        "interrogation_yuka_formal_case",
        "yuka_cooperate",
        "shadow_report_yuka",
        "tollbooth_yuka_copy_receipt",
        "registry_yuka_compare_names",
        "pawnshop_yuka_trace_key",
        "library_follow_shadow_note",
        "memory_mark_yuka_pattern",
        "deck_map_yuka",
        "museum_trace_yuka_catalog",
        "basement_yuka_microfilm",
        "weather_yuka_pull_archive",
        "bureau_yuka_archive_pressure",
        "wash_yuka_residue_sample",
        "cablecar_yuka_route_manifest",
        "atelier_photograph_repair_tags",
        "koi_yuka_sample_scale",
        "mint_yuka_trace_watermark",
        "stairwell_record_shadow_key",
        "rooftop_ask_shadow",
        "gauge_send_yuka_sensor_log",
        "pool_photograph_drain_code",
        "tatami_catalog_stitch_pattern",
        "letter_show_yuka",
        "archive_yuka_scan_postmark",
        "lab_yuka_test_scent",
        "printshop_yuka_catalog_block",
        "shrine_photograph",
        "photo_scan_yuka",
        "darkroom_yuka_develop_fourth",
        "negative_yuka_route_grid",
        "corridor_yuka_test_reflection",
        "teahouse_test_yuka_water",
        "phone_trace_yuka",
        "bridge_yuka_photo_reflection",
        "pier_send_yuka_manifest",
        "confession_yuka_extract_noise",
        "cinema_yuka_capture_frame",
        "deadletter_yuka_index_bundle",
        "microfilm_yuka_compare_frames",
        "switchboard_yuka_trace_call",
        "doll_shadow_serial_number",
        "archive_shadow_file",
        "apartment_read_water_bills",
        "platform_yuka_leads",
        "lab_send_yuka",
        "greenhouse_send_yuka_sample",
        "seed_vault_yuka_scan_gene",
        "aquarium_yuka_trace_current",
        "generator_yuka_export_voltage",
        "tunnel_record_yuka_echo",
        "cathedral_upload_yuka_core",
        "reservoir_upload_yuka_flow",
        "siren_send_yuka_frequency",
        "server_nave_listen_shadow",
        "memorial_photo_for_yuka",
        "signal_copy_yuka_table",
        "tide_export_yuka_final_key",
        "postoffice_yuka_scan_tube_log",
        "chapel_yuka_collect_offering_log",
        "carriage_yuka_pin_route_map",
        "room_escape",
        "blanket_scan_chain_serial",
        "window_send_yuka_condensation_map",
        "musicbox_extract_mechanism_log",
        "threshold_leave_recording_yuka",
        "umbrella_return_yuka_photo",
        "crosswalk_send_yuka_live",
        "bus_send_yuka_route",
        "station_clock_send_yuka_time"
    ], package: package)
    try check(ghostRoute == "ghost", "Hidden ghost route sequence failed")

    let abyssRoute = try endingID(for: [
        "prologue_accept",
        "umbrella_silence",
        "water_tower_ignore",
        "letter_exchange_answer_same_words",
        "stationery_write_until_blur",
        "clock_turn_back_hands",
        "tram_follow_wrong_car",
        "mural_step_into_paint",
        "notebook_run",
        "arcade_play_with_sea",
        "kiosk_delete_log",
        "radio_repeat_name",
        "lost_umbrella_smell_rain",
        "cassette_loop_name",
        "server_sync_sea_profile",
        "elevator_descend_without_floor",
        "airi_defend_sea",
        "locker_count_bus_numbers",
        "counseling_loop_third_chair",
        "antenna_answer_sea_static",
        "call_delete_airi",
        "aquarium_stare_too_long",
        "infirmary_accept_dizziness",
        "laundromat_watch_spin",
        "skybridge_walk_red_signal",
        "hospital_count_heartbeats",
        "clinic_copy_sea_pulse",
        "observation_trace_own_pulse",
        "sample_reflect_red_water",
        "interrogation_leave_third_chair",
        "yuka_hide",
        "shadow_ask_how_to_keep",
        "tollbooth_accept_shadow_price",
        "registry_erase_haru_name",
        "pawnshop_trade_voice_for_key",
        "library_burn_page",
        "memory_erase_other_names",
        "deck_step_into_reflection",
        "museum_touch_empty_frame",
        "basement_replace_name",
        "weather_raise_rainfall",
        "bureau_raise_private_rain",
        "wash_breathe_mineral_foam",
        "cablecar_step_into_wrong_car",
        "atelier_wrap_finger_red",
        "koi_follow_red_fish",
        "mint_press_name_until_red",
        "stairwell_count_wet_steps",
        "rooftop_hold_hand",
        "gauge_drink_rain_measure",
        "pool_step_into_reflection_lane",
        "tatami_sew_name_into_cuff",
        "letter_keep",
        "archive_press_letter_to_chest",
        "lab_breathe_red_scent",
        "printshop_stamp_until_blur",
        "shrine_tie_forever",
        "photo_cut_everyone_else",
        "darkroom_cut_until_red",
        "negative_step_into_blank",
        "corridor_swallow_reflection",
        "teahouse_swallow_red_sugar",
        "phone_listen_busy_signal",
        "bridge_follow_second_sea",
        "pier_follow_empty_ferry",
        "confession_loop_tape_backwards",
        "cinema_walk_into_screen",
        "deadletter_mail_to_loop",
        "microfilm_watch_loop",
        "switchboard_answer_own_voice",
        "doll_wear_porcelain_finger",
        "archive_meet_sea",
        "apartment_leave_wall",
        "platform_ignore_all",
        "lab_drink_with_sea",
        "greenhouse_breathe_rain",
        "seed_vault_swallow_seed_light",
        "aquarium_follow_red_fragment",
        "generator_listen_to_hum",
        "tunnel_drink_echo",
        "cathedral_baptize_rain",
        "reservoir_sink_name",
        "siren_listen_until_static",
        "server_nave_accept_loop_math",
        "memorial_float_own_name",
        "signal_pull_wrong_lever",
        "tide_swallow_alarm",
        "postoffice_mail_self_to_weekend",
        "chapel_offer_voice_to_machine",
        "carriage_board_blank_carriage",
        "room_accept",
        "blanket_pull_chain_under_cover",
        "window_erase_exit_with_breath",
        "musicbox_wind_until_voice_blurs",
        "threshold_answer_with_sea",
        "umbrella_return_become_handle",
        "crosswalk_follow_wrong_reflection",
        "bus_sleep_until_rain",
        "station_clock_forget_weekday"
    ], package: package)
    try check(abyssRoute == "abyss", "Abyss route sequence failed")

    var stats = GameStats(love: 95, yandere: 2, sanity: 50)
    stats.apply(StatDelta(love: 20, yandere: -10, sanity: -100), bounds: package.statBounds.range)
    try check(stats == GameStats(love: 100, yandere: 0, sanity: 0), "Stat clamp failed")

    let manager = GameStateManager()
    manager.load(package: package)
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
