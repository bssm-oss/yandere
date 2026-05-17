#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="WeekendRain"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
PACKAGE_ZIP="$DIST_DIR/$APP_NAME-local.zip"
REPORT_DIR="$ROOT_DIR/tmp/e2e"
ITERATIONS=1
INTERVAL=30
WATCH=0

usage() {
  cat >&2 <<USAGE
usage: $0 [--iterations N] [--watch] [--interval SECONDS]

Runs full local E2E QA:
  - JSON syntax validation
  - Swift build
  - WeekendRainValidation route/system checks
  - app bundle launch smoke
  - package zip creation
  - packaged ExternalContent/resource checks
  - ad-hoc codesign verification
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --iterations)
      ITERATIONS="${2:?missing iteration count}"
      shift 2
      ;;
    --watch)
      WATCH=1
      shift
      ;;
    --interval)
      INTERVAL="${2:?missing interval seconds}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [ "$WATCH" -eq 1 ]; then
  ITERATIONS=0
fi

mkdir -p "$REPORT_DIR"
cd "$ROOT_DIR"

run_step() {
  local name="$1"
  shift
  printf '\n[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$name"
  "$@"
}

verify_assets_legacy() {
  python3 - <<'PY'
import json
from pathlib import Path

try:
    from PIL import Image
except Exception as exc:
    raise SystemExit(f"Pillow is required for asset QA: {exc}")

root = Path.cwd()
story = json.loads((root / "ExternalContent/Stories/weekend_rain.story.json").read_text())
content = root / "ExternalContent"

required = {
    "backgrounds": [
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
        "broken_music_box_altar",
    ],
    "characters": [
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
        "yuka_window_flashlight",
    ],
    "cg": [
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
        "cg_music_box_red_key",
    ],
}

for bucket, ids in required.items():
    for asset_id in ids:
        asset = story["assets"][bucket][asset_id]
        path = content / asset["path"]
        if not path.exists():
            raise SystemExit(f"missing asset file: {path}")
        image = Image.open(path)
        if image.width <= 0 or image.height <= 0:
            raise SystemExit(f"invalid image dimensions: {path}")
        if bucket == "characters":
            if image.mode != "RGBA":
                raise SystemExit(f"character is not RGBA: {path} ({image.mode})")
            corners = [
                image.getpixel((0, 0))[3],
                image.getpixel((image.width - 1, 0))[3],
                image.getpixel((0, image.height - 1))[3],
                image.getpixel((image.width - 1, image.height - 1))[3],
            ]
            if any(alpha != 0 for alpha in corners):
                raise SystemExit(f"character transparent corners failed: {path} {corners}")

print("asset pipeline passed")
PY
}

verify_assets() {
  python3 "$ROOT_DIR/script/e2e_asset_check.py"
}

verify_package() {
  test -d "$APP_BUNDLE"
  test -f "$PACKAGE_ZIP"
  codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
  local package_manifest="$REPORT_DIR/package-contents.txt"
  zipinfo -1 "$PACKAGE_ZIP" > "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/AppIcon.icns' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Stories/weekend_rain.story.json' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/sea_wall_mural.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/weather_server_nave.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/confession_booth_alley.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/clinical_observation_ward.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/kimono_repair_atelier.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/roof_access_stairwell.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/rain_letterpress_archive.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/shrine_knot_printshop.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/photo_booth_darkroom.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/negative_sorting_arcade.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/teacup_display_corridor.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/flood_post_office.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/vending_chapel_underpass.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/sleeping_carriage_depot.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/microfilm_reservoir_archive.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/rain_switchboard_exchange.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/automaton_doll_repair_studio.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/rain_seed_vault.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/underground_observation_aquarium.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/moss_generator_room.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/emotion_weather_bureau.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/umbrella_wash_laundromat.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/aerial_cablecar_transfer.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/shoe_locker_surveillance.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/counseling_recording_room.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/rooftop_antenna_shrine.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/black_umbrella_tollbooth.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/forgotten_name_registry.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/rain_pawnshop_counter.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/rooftop_rain_gauge_deck.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/abandoned_indoor_pool.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/home_ec_tatami_room.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/blanket_chain_inventory.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/condensation_window_map.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/BG/broken_music_box_altar.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_rainveil_final_evidence.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_tide_lock_key.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_rooftop_red_thread.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_confession_cassette.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_emotion_waveform_chart.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_red_thread_spool.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_watermark_letter.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_red_envelope_scanner.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_shrine_knot_fibers.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_red_fourth_photo.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_negative_route_grid.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_teacup_missing_frame.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_pneumatic_love_letters.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_vending_chapel_offering.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_sleeping_carriage_route_map.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_microfilm_rain_records.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_switchboard_red_cable.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_doll_hand_red_thread.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_rain_orchid_seed.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_underwater_umbrella_fragment.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_generator_red_ribbon.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_emotion_barometer.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_umbrella_wash_residue.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_cablecar_token_thread.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_locker_charm_camera.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_counseling_cassette_thread.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_antenna_signal_charm.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_black_umbrella_receipt.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_forgotten_name_card.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_pawnshop_red_key.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_rooftop_rain_gauge.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_pool_red_whistle.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_tatami_red_stitch.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_blanket_chain_knot.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_condensation_window_map.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/CG/cg_music_box_red_key.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/sea_station_clock.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/airi_confession_note.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/yuka_clinic_vial.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/sea_rooftop_thread.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/shadow_mineral_key.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/airi_wet_envelope.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/yuka_postmark_scanner.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/sea_photo_strip.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/airi_torn_photo.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/yuka_archive_lantern.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/sea_red_ticket.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/airi_switchboard_receiver.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/shadow_doll_thread.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/yuka_rain_orchid_lab.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/sea_orchid_umbrella_handle.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/yuka_weather_raincoat.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/sea_cablecar_token.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/airi_locker_evidence.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/sea_charm_camera.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/shadow_receipt_ledger.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/sea_name_card.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/sea_rain_gauge_vial.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/airi_pool_whistle.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/sea_blanket_thread.png' "$package_manifest"
  /usr/bin/grep -q 'WeekendRain.app/Contents/Resources/ExternalContent/Assets/Character/yuka_window_flashlight.png' "$package_manifest"
  WEEKEND_RAIN_CONTENT_PATH="$APP_BUNDLE/Contents/Resources/ExternalContent" swift run WeekendRainValidation
}

run_cycle() {
  local cycle="$1"
  local report="$REPORT_DIR/e2e-$(date -u +%Y%m%dT%H%M%SZ)-cycle-${cycle}.log"

  {
    echo "WeekendRain E2E QA cycle $cycle"
    echo "root=$ROOT_DIR"
    run_step "JSON syntax" bash -lc 'python3 -m json.tool ExternalContent/Stories/weekend_rain.story.json >/dev/null && echo json-ok'
    run_step "Generated asset files" verify_assets
    run_step "Swift build" swift build
    run_step "Xcode unit tests" xcodebuild test -scheme WeekendRain -destination 'platform=macOS' -quiet
    run_step "Scenario/system validation" swift run WeekendRainValidation
    run_step "App launch smoke" ./script/build_and_run.sh --verify
    pkill -f '/dist/WeekendRain.app/Contents/MacOS/WeekendRain' >/dev/null 2>&1 || true
    run_step "Package app zip" ./script/build_and_run.sh --package
    run_step "Packaged resources/signature" verify_package
    echo "E2E QA cycle $cycle passed"
  } 2>&1 | tee "$report"
}

cycle=1
while true; do
  run_cycle "$cycle"
  if [ "$ITERATIONS" -gt 0 ] && [ "$cycle" -ge "$ITERATIONS" ]; then
    break
  fi
  cycle=$((cycle + 1))
  sleep "$INTERVAL"
done
