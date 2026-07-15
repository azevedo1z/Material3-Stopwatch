# Stopwatch App

A modern Flutter stopwatch application featuring a custom-painted analog clock with smooth sweeping hands, Material 3 theming with dark mode support, and Riverpod-based state management.

## Features

- **Analog clock face** - Custom `CustomPaint` dial with 60 tick marks, smooth second/minute/hour hands driven by millisecond-precision elapsed time
- **Zero-padded digital display** - `HH:MM:SS.cs` format with accent-colored centiseconds
- **Start / Pause / Reset** - Circular action buttons; reset fades in only when there's elapsed time
- **Material 3 dark theme** - Purple accent (`#6C63FF`), supports system light/dark mode
- **Riverpod state management** - `StopwatchService` lives as a provider with proper timer lifecycle (no leaks)
- **About page** - Version history shown as styled chips

## Getting Started

```sh
git clone https://github.com/azevedo1z/Flutter-Stopwatch.git
cd Flutter-Stopwatch
flutter pub get
flutter run
```

### Requirements

- Flutter SDK `>=3.0.5`
- Dart SDK `>=3.0.5 <4.0.0`

## Project Structure

```
lib/
├── data/
│   └── stopwatch_provider.dart      # Riverpod providers + StopwatchService
├── presentation/
│   ├── main.dart                    # App entry point, Material 3 theme config
│   └── views/
│       ├── home_view.dart           # Main screen (clock, timer display, buttons)
│       └── about_view.dart          # About page with version chips
└── widgets/
    └── AnimatedStopwatch.dart       # Analog clock (CustomPaint + AnimationController)
```

## Architecture

The app follows a layered structure:

| Layer | Responsibility |
|---|---|
| **`data/`** | Riverpod providers and `StopwatchService` - owns the `Stopwatch` instance, a `Timer.periodic` at ~60fps, and all state mutations |
| **`presentation/`** | UI screens that `watch` providers and call service methods. No business logic in widgets |
| **`widgets/`** | Reusable visual components. `AnimatedStopwatch` uses an `AnimationController` to repaint a `StopwatchPainter` that draws the clock face, tick marks, and hands |

State flows in one direction: **user action → `StopwatchService` method → provider state update → UI rebuild**.

## Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | Reactive state management |
| `cupertino_icons` | iOS-style icons |
| `flutter_lints` | Static analysis rules |

## Usage

| Action | How |
|---|---|
| Start / Pause | Tap the large circular button (green ▶ / red ⏸) |
| Reset | Tap the smaller reset button (appears after starting) |
| About | Tap the info icon in the top-right corner |

## Developer

Developed by [Gabriel Azevedo](https://github.com/azevedo1z)

| Version | Date | Notes |
|---|---|---|
| 1.0 | July 2023 | Initial release |
| 2.0 | February 2025 | Riverpod migration, animated clock |
| 2.1 | March 2026 | Material 3 UI, bug fixes (timer leak, state sync, smooth hands) |
