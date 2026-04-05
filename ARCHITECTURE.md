# OzaIPTV — Architecture Document

## Overview

OzaIPTV follows **Clean Architecture** combined with a **Feature-First** folder organization. The codebase is designed to be modular, testable, and ready for SaaS evolution without requiring a rewrite.

---

## Layer Diagram

```
┌──────────────────────────────────────────────────────┐
│                    Presentation                       │
│  Features → Screens, Widgets, Riverpod Providers      │
├──────────────────────────────────────────────────────┤
│                     Domain                            │
│  Entities, Repository Contracts, Use Cases             │
├──────────────────────────────────────────────────────┤
│                      Data                             │
│  Repository Impls, Data Sources, DTOs, Mappers         │
├──────────────────────────────────────────────────────┤
│                    Services                           │
│  Playback, M3U, EPG, Diagnostics, Auth, API, Cache    │
├──────────────────────────────────────────────────────┤
│                      Core                             │
│  Constants, Enums, Errors, Extensions, Network, Utils  │
├──────────────────────────────────────────────────────┤
│                  Design System                        │
│  Theme, Tokens, Components, Motion                    │
└──────────────────────────────────────────────────────┘
```

### Dependency Rule

Dependencies flow **inward only**: Presentation → Domain ← Data.

- **Domain** has zero dependencies on Flutter or any package (pure Dart).
- **Data** implements Domain contracts and depends on external packages (Hive, Dio).
- **Presentation** depends on Domain entities and Riverpod providers.
- **Services** are cross-cutting concerns accessed via Riverpod providers.

---

## State Management: Riverpod

### Provider Types Used

| Provider Type | Use Case |
|---|---|
| `Provider` | Singletons — repositories, services, managers |
| `FutureProvider` | Async data loading — channels, EPG, favorites |
| `FutureProvider.family` | Parameterized queries — channel by ID, programs by channel |
| `StateProvider` | Simple UI state — selected category, search query |
| `StateNotifierProvider` | Complex mutable state — PlaybackController, SettingsNotifier |

### Data Flow: Channel Playback

```
User taps channel
  → PlayerScreen reads channelByIdProvider(id)
  → PlaybackController.playChannel(channel)
    → StreamFallbackManager.initializeForChannel(channel)
    → StreamFallbackManager.currentSource → StreamSource
    → VideoPlayerController.networkUrl(source.url)
    → On success: fallbackManager.onSourceSuccess()
    → On failure: fallbackManager.onSourceFailed()
      → Returns next source or null (all exhausted)
      → If next: reinitialize player with new URL
      → If null: show error state
```

### Data Flow: Favorites Toggle

```
User taps favorite button
  → FavoritesRepositoryImpl.addFavorite(channelId)
    → Hive box write
  → ref.invalidate(isFavoriteProvider(channelId))
  → ref.invalidate(favoritesProvider)
  → UI rebuilds reactively
```

---

## Playback Architecture

The playback system has five key components:

### 1. PlayerFacade (Abstract)

An interface that decouples the app from `video_player`. In production, this could wrap ExoPlayer (Android), AVPlayer (iOS), or a custom native player.

```dart
abstract class PlayerFacade {
  Future<void> initialize(StreamSource source);
  Future<void> play();
  Future<void> pause();
  Stream<PlayerStateEvent> get stateStream;
}
```

### 2. PlaybackController (StateNotifier)

Orchestrates the full lifecycle: channel selection → source resolution → playback → fallback → diagnostics. Exposes `PlaybackSessionState` to the UI.

### 3. StreamFallbackManager

The core resilience engine. Encapsulates all retry and failover logic:

- Sorts sources by priority, health score, and last-known-working preference
- Allows one retry per source before switching
- Records every event (retry, fail, switch, success, exhausted)
- Capped at `maxFallbackAttempts` (default 4)

### 4. StreamHealthMonitor

Persists health data across sessions using Hive. Calculates a reliability score (0–100) based on success rate and consecutive failures.

### 5. PlaybackDiagnosticsReporter

Generates `DiagnosticsSnapshot` objects from the current playback state for the diagnostics screen and future server reporting.

---

## Navigation: go_router

### Route Structure

```
/ (splash)
├── /home              ← ShellRoute (bottom nav / side rail)
├── /live-tv
├── /search
├── /favorites
├── /settings
│   └── /settings/diagnostics
├── /player/:channelId ← Full-screen (outside shell)
├── /epg               ← Full-screen
└── /history           ← Full-screen
```

### Adaptive Navigation

`ShellScaffold` detects screen width:
- **< 800px** → Bottom `NavigationBar` (mobile)
- **800–1199px** → Compact `NavigationRail` (tablet/small desktop)
- **≥ 1200px** → Extended `NavigationRail` with labels (wide desktop)

---

## Design System: Dark Luxe Broadcast

### Token Hierarchy

```
Tokens (raw values)
  → colors.dart    Color constants
  → spacing.dart   Spacing, radius, shadows
  → typography.dart  TextStyle definitions

Theme (Flutter ThemeData)
  → app_theme.dart   Composes tokens into Material 3 theme

Components (reusable widgets)
  → channel_card.dart     Card with focus states
  → section_header.dart   Title + action
  → loading_states.dart   Skeletons, empty, error
  → glass_container.dart  Glassmorphism
  → tv_focus.dart         D-pad focus wrapper
  → responsive_grid.dart  Adaptive columns
```

### Color Palette

| Token | Hex | Usage |
|---|---|---|
| backgroundPrimary | #0A0A0F | App background |
| accentGold | #D4A843 | Primary accent, CTAs |
| accentBlue | #4A9EFF | Secondary accent, focus rings |
| liveRed | #FF3B3B | Live indicators |
| textPrimary | #F0F0F5 | Headings, body |
| textTertiary | #7A7A90 | Captions, disabled |

---

## Platform Adaptation

### Android TV

- `TvFocusable` wraps interactive elements with visible focus ring and scale animation
- `KeyboardListener` in player handles D-pad (arrows, select, back)
- `ShellScaffold` uses NavigationRail instead of BottomNav
- `PlatformUtils.isAndroidTV` detection (extendable via `device_info_plus`)

### Windows Desktop

- Keyboard/mouse support throughout
- Resizable layouts via `ResponsiveGrid`
- Side navigation rail at ≥800px width

### iOS

- Standard Material 3 theming (dark)
- Orientation support (portrait + landscape in player)
- Safe area handling

---

## Local Persistence Strategy

| Box | Contents | Strategy |
|---|---|---|
| `favorites` | Channel IDs + timestamps | Key = channelId, Value = JSON |
| `history` | Watch events | Key = channelId_timestamp, Value = JSON |
| `settings` | App preferences | Single key, full settings JSON |
| `cache` | API response cache | Key = endpoint, Value = JSON + TTL |
| `recent_searches` | Search terms | Ordered list |
| `stream_health` | Source health data | Key = sourceId, Value = JSON scores |

All boxes use `Hive<String>` for simplicity and JSON encoding.

---

## Error Handling Strategy

### Layer-Specific Errors

```
AppFailure (base)
  ├── NetworkFailure   → Dio errors, timeouts
  ├── ServerFailure    → HTTP 4xx/5xx
  ├── CacheFailure     → Hive read/write failures
  ├── PlaybackFailure  → Stream errors, codec issues
  ├── ParseFailure     → M3U/JSON/XMLTV parsing
  └── AuthFailure      → Token expiry, invalid credentials
```

### UI Error States

Every screen handles three states via Riverpod's `AsyncValue`:
1. **Loading** → Shimmer skeletons or spinner
2. **Error** → `ErrorStateWidget` with retry button
3. **Empty** → `EmptyStateWidget` with contextual message

---

## Testing Strategy

### Unit Tests (test/unit/)

- `stream_fallback_manager_test.dart` — Fallback logic, retry behavior, source exhaustion
- `m3u_parser_test.dart` — Playlist parsing, attribute extraction, protocol detection
- `channel_test.dart` — Entity behavior, source filtering, protocol inference
- `epg_program_test.dart` — Progress calculation, time-based states

### Widget Tests (test/widget/)

Extension point for testing individual components with `WidgetTester`.

### Integration Tests (integration_test/)

Extension point for full-flow tests (splash → home → player → fallback).

---

## File Naming Conventions

| Type | Convention | Example |
|---|---|---|
| Screens | `feature_screen.dart` | `home_screen.dart` |
| Widgets | `descriptive_widget.dart` | `channel_card.dart` |
| Entities | `entity_name.dart` | `channel.dart` |
| Repositories | `name_repository.dart` (abstract) | `channel_repository.dart` |
| Implementations | `name_repository_impl.dart` | `channel_repository_impl.dart` |
| Providers | Declared inside relevant files | `channelsProvider` |
| Tests | `subject_test.dart` | `channel_test.dart` |
| Constants | `category_constants.dart` | `app_constants.dart` |

---

## Build & Deploy

See `README.md` for full setup, build, and CI/CD instructions.
