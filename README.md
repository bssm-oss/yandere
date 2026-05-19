# Weekend Rain

`주말의 비 (Weekend Rain)` is a pure AppKit visual novel prototype. The runtime
uses `NSView`, `NSWindow`, `NSTableView`, `NSCollectionView`, Core Animation, and
external JSON story data. It does not use SpriteKit, SwiftUI, UserDefaults saves,
or `NSDocumentController`.

## Structure

```text
WeekendRain.xcodeproj
WeekendRain/
  App/                 AppDelegate, MainWindowController
  Engine/              GameStateManager, StoryLoader, ConversationEngine, SaveManager
  Models/              StoryNode, ChoiceNode, GameStats, GameSave, EndingRule
  Views/               NovelSceneView, ChoiceButton, SakuraRainView
  Backlog/             BacklogViewController + NSTableView
  Gallery/             GalleryViewController + NSCollectionView
ExternalContent/
  Stories/weekend_rain.story.json
  Assets/CG, BG, Character
```

`WeekendRain.xcodeproj` is generated from `project.yml` with XcodeGen. The
SwiftPM package is also present so the app can build and run on machines where
the active developer directory is Command Line Tools instead of full Xcode.

## Commands

```bash
xcodegen generate --spec project.yml
swift build
swift run WeekendRainValidation
./script/build_and_run.sh
```

The Codex app Run action is wired to `./script/build_and_run.sh`.

## Install From GitHub Release

1. Open the latest release on GitHub and download `WeekendRain.dmg`.
2. Open the DMG, then copy `WeekendRain.app` into `/Applications`.
3. Launch `WeekendRain` from Applications. If macOS blocks the first launch
   because this community build is ad-hoc signed, right-click the app and choose
   `Open` once.

The release DMG includes the story JSON and all external image assets under
`WeekendRain.app/Contents/Resources/ExternalContent`, so the visual novel runs
without a separate asset download.

## Local Packaging

```bash
./script/build_and_run.sh --package
```

The packaging command creates both `dist/WeekendRain-local.zip` and
`dist/WeekendRain.dmg`. Use the DMG for GitHub Releases and the ZIP only as a
local fallback artifact.
