# Minesweeper

A native iOS Minesweeper app built with SwiftUI, Swift 6, and SwiftData.

## Features

- **Classic gameplay** - tap to reveal, long-press to flag, chord-reveal on numbered cells
- **First-tap safety** - mines are placed after your first tap, guaranteeing a safe 3x3 opening zone
- **Difficulty presets** - Easy (9x9), Medium (16x16), Hard (16x30), Extreme (20x30), plus fully custom board sizes
- **Themes** - Classic bevel and Dark rounded skins with live preview
- **Stats** - per-difficulty win rate, best/average time, and game history (persisted with SwiftData)
- **Pinch to zoom** - smoothly zoom into large boards
- **Haptic feedback** - tactile responses on reveal, flag, win, and loss

## Requirements

- Xcode 16+
- iOS 17.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Getting Started

```bash
# Install XcodeGen (if needed)
brew install xcodegen

# Generate the Xcode project
cd Minesweeper && xcodegen generate
```

Then open `Minesweeper/Minesweeper.xcodeproj` in Xcode and run on a simulator or device.

## Running Tests

```bash
xcodebuild test \
  -project Minesweeper/Minesweeper.xcodeproj \
  -scheme Minesweeper \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO
```

## Project Structure

```
Minesweeper/
├── project.yml                 # XcodeGen spec (generates .xcodeproj)
├── Minesweeper/
│   ├── App/                    # App entry point
│   ├── Models/                 # Cell, GameBoard, Difficulty, SkinTheme, GameRecord
│   ├── ViewModels/             # GameViewModel (state machine, timer, haptics)
│   └── Views/                  # SwiftUI views (board, cells, pickers, stats)
└── MinesweeperTests/           # Swift Testing suite (~117 tests)
```
