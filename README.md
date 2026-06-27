# Wordle (Flutter)

A clone of the classic Wordle word-guessing game, built with Flutter. Supports on-screen taps and physical keyboard input, light/dark mode, and uses the same curated answer list and full guess-validation list approach as the original NYT Wordle.

## How to Play

1. Guess the hidden 5-letter word in 6 tries.
2. After each guess, each letter is colored to give you a clue:
   - 🟩 **Green** — the letter is in the word and in the correct spot.
   - 🟨 **Yellow** — the letter is in the word but in the wrong spot.
   - ⬜ **Gray** — the letter is not in the word at all.
3. Use the clues to figure out the word before you run out of guesses.

You can play using:
- The on-screen keyboard (tap to play).
- Your physical keyboard (PC, or a Bluetooth keyboard on mobile) — letters, `Backspace`, and `Enter` all work.

## Features

- 🎯 **Two-list word system** — guesses are validated against a list of ~12,900 words, while the actual answer is always picked from a curated list of ~2,300 common words, so the target word is always fair and recognizable (matching how the real NYT Wordle works).
- ⌨️ **Keyboard support** — play by tapping the on-screen keys or typing on a physical/Bluetooth keyboard.
- 🌗 **Light/Dark mode** — toggle manually via the icon in the top app bar, in addition to following your system theme by default.
- 🔁 **No repeats until exhausted** — the app won't give you the same answer word twice until every word in the answer list has appeared once.
- 🎬 **Flip animations** — tiles flip to reveal their color after each guess, just like the original.

## Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (Dart)
- **State management:** Built-in `StatefulWidget` + `setState`
- **Platforms:** Android, with support for Web/Desktop during development

## Project Structure

```
lib/
├── main.dart                # App entry point, theme setup
└── screens/
    ├── game_screens.dart    # Main game screen, UI, and input handling
    ├── wordle_game.dart     # Core game logic (guess checking, win/loss state)
    ├── word_list.dart       # Full list of valid guessable words (~12,900 words)
    └── answer_list.dart     # Curated list of possible answer words (~2,300 words)
```

## Getting Started (Run Locally)

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
- For Android builds: Android SDK + command-line tools (installable via Android Studio's SDK Manager)

### Setup

```bash
git clone https://github.com/<your-username>/<your-repo-name>.git
cd <your-repo-name>
flutter pub get
flutter run
```

### Build an Android APK

```bash
flutter build apk --release
```

The APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Download

You can download the latest installable APK directly from the [Releases](../../releases) page.

> **Note:** Since this app isn't distributed through the Google Play Store, you'll need to allow "Install from unknown sources" for the app you use to open the APK file (e.g. Files, Chrome, Gmail) when installing it on your Android device.

## License

This project is open source. Feel free to fork, modify, and learn from it.

## Acknowledgements

- Inspired by the original [Wordle](https://www.nytimes.com/games/wordle/index.html) by Josh Wardle, now owned by The New York Times.
- Word lists sourced from the publicly known NYT Wordle word lists.
