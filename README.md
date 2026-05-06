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
