#!/usr/bin/env python3
import json
from pathlib import Path

try:
    from PIL import Image
except Exception as exc:
    raise SystemExit(f"Pillow is required for asset QA: {exc}")


root = Path.cwd()
story_path = root / "ExternalContent/Stories/weekend_rain.story.json"
content_root = root / "ExternalContent"
icon_path = root / "WeekendRain/App/AppIcon.icns"
icon_source_path = root / "WeekendRain/App/AppIconSource.png"

story = json.loads(story_path.read_text())

for icon_file in [icon_path, icon_source_path]:
    if not icon_file.exists():
        raise SystemExit(f"missing app icon file: {icon_file}")
    if icon_file.stat().st_size <= 0:
        raise SystemExit(f"empty app icon file: {icon_file}")

for bucket in ["backgrounds", "characters", "cg"]:
    assets = story["assets"][bucket]
    for asset_id, asset in assets.items():
        if asset.get("id") != asset_id:
            raise SystemExit(f"asset id mismatch: {bucket}.{asset_id}")

        path = content_root / asset["path"]
        if not path.exists():
            raise SystemExit(f"missing asset file: {path}")

        image = Image.open(path)
        image.load()
        if image.width <= 0 or image.height <= 0:
            raise SystemExit(f"invalid image dimensions: {path}")

        if bucket == "characters" and "transparent" in asset.get("tags", []):
            if image.mode != "RGBA":
                raise SystemExit(f"transparent character is not RGBA: {path} ({image.mode})")

            corners = [
                image.getpixel((0, 0))[3],
                image.getpixel((image.width - 1, 0))[3],
                image.getpixel((0, image.height - 1))[3],
                image.getpixel((image.width - 1, image.height - 1))[3],
            ]
            if any(alpha != 0 for alpha in corners):
                raise SystemExit(f"character transparent corners failed: {path} {corners}")

print("asset pipeline passed")
