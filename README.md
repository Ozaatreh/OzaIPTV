# OzaIPTV

**Premium IPTV/OTT Streaming Application**

A production-grade, cross-platform IPTV/OTT application built with Flutter. Designed as a personal-first product that can evolve into a SaaS-ready platform.

> Built with Clean Architecture, Riverpod state management, and a premium "Dark Luxe Broadcast" design system.

---

## Features

- **Live TV Streaming** — Browse and watch live channels with HLS/DASH support
- **Multi-Source Fallback** — Automatic stream source switching when primary fails (up to 4 sources per channel)
- **EPG Guide** — Now/next program display with full schedule support
- **Search** — Instant channel search with debounced input
- **Favorites** — Persistent favorites with local storage
- **Watch History** — Automatic tracking of recently watched channels
- **Diagnostics** — Real-time stream health monitoring, fallback event logs, and device info
- **M3U Parsing** — Import channels from M3U/M3U8 playlists
- **Android TV Ready** — D-pad navigation, focus states, 10-foot UI principles
- **Cross-Platform** — Android, iOS, Android TV, Windows desktop

---

## Architecture

### Clean Architecture + Feature-First

```
lib/
├── app/              # App entry, bootstrap, environment config
├── core/             # Constants, enums, errors, extensions, utils
├── design_system/    # Theme, tokens, reusable components
├── domain/           # Entities, repository abstractions, use cases
├── data/             # Data sources, DTOs, mappers, repo implementations
├── services/         # API, auth, cache, EPG, M3U, playback, diagnostics
├── routing/          # go_router setup, guards, route names
└── features/         # Feature modules (splash, home, live_tv, player, etc.)
```

### Key Architecture Decisions

| Layer | Technology |
|---|---|
| State Management | Riverpod |
| Navigation | go_router |
| Networking | Dio |
| Local Storage | Hive |
| Video Playback | video_player + chewie (abstracted via PlayerFacade) |
| Code Generation | Freezed, json_serializable |

### Fallback System

The stream fallback system is a core architectural feature:

1. Every channel supports up to 4 stream sources with priorities
2. On startup, the highest-priority healthy source is selected
3. If playback fails, a single retry is attempted
4. If retry fails, the system switches to the next source automatically
5. All fallback events are logged for diagnostics
6. The last known working source is cached locally per channel
7. A clean error state appears only when all sources are exhausted

---

## Setup Instructions

### Prerequisites

- Flutter SDK ≥ 3.16.0
- Dart SDK ≥ 3.2.0
- Android Studio or VS Code with Flutter extensions
- For iOS: Xcode 15+ and CocoaPods
- For Windows: Visual Studio 2022 with C++ desktop workload

### Getting Started

```bash
# Clone the repository
git clone https://github.com/yourusername/ozaiptv.git
cd ozaiptv

# Verify Flutter setup
flutter doctor

# Install dependencies
flutter pub get

# Run code generation (if using Freezed models)
dart run build_runner build --delete-conflicting-outputs

# Run on connected device
flutter run
```

### Run on Specific Platforms

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Windows
flutter run -d windows

# Android TV (connect via ADB)
adb connect <tv-ip>:5555
flutter run -d <device-id>
```

---

## Building APK

### Development Build

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release Build

#### Step 1: Generate a Keystore

```bash
keytool -genkey -v -keystore android/app/release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias ozaiptv -storepass YOUR_STORE_PASSWORD -keypass YOUR_KEY_PASSWORD
```

#### Step 2: Create `android/key.properties`

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=ozaiptv
storeFile=release-keystore.jks
```

#### Step 3: Configure Signing in `android/app/build.gradle`

Add above `android {`:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Inside `android {`, add:

```groovy
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile file(keystoreProperties['storeFile'])
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

#### Step 4: Build

```bash
# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### Versioning

Edit `pubspec.yaml`:

```yaml
version: 1.0.0+1  # version_name+version_code
```

### Troubleshooting

| Issue | Solution |
|---|---|
| `Gradle build failed` | Run `cd android && ./gradlew clean` |
| `Missing keystore` | Verify `key.properties` path and keystore location |
| `Min SDK version error` | Set `minSdkVersion 21` in `android/app/build.gradle` |
| `Multidex error` | Add `multiDexEnabled true` in `defaultConfig` |
| `Plugin not found` | Run `flutter clean && flutter pub get` |

---

## CI/CD

### GitHub Actions Pipelines

- **`flutter_ci.yml`** — Runs on push/PR to `main`/`develop`: lint, analyze, test, build debug APK
- **`android_release.yml`** — Manual or tag-triggered: builds signed release APK/AAB, creates GitHub Release

### Required GitHub Secrets

| Secret | Description |
|---|---|
| `KEYSTORE_BASE64` | Base64-encoded release keystore file |
| `KEY_ALIAS` | Signing key alias |
| `KEY_PASSWORD` | Key password |
| `STORE_PASSWORD` | Keystore store password |

**Encoding your keystore:**

```bash
base64 -i android/app/release-keystore.jks | pbcopy  # macOS
base64 android/app/release-keystore.jks > keystore.txt  # Linux
```

Paste the output into the `KEYSTORE_BASE64` GitHub secret.

---

## Mock Data & Testing

The app ships with legal, publicly available test streams:

- **Big Buck Bunny** — Blender open movie (HLS via Mux)
- **Sintel** — Blender open movie (HLS + DASH via Akamai)
- **Tears of Steel** — Blender sci-fi short (HLS via Unified Streaming)
- **Apple Test Streams** — Apple's public HLS test streams

Mock data files are in `assets/mock/`:

- `channels.json` — Channel list with multiple stream sources per channel
- `epg.json` — EPG program data with relative time offsets

---

## API Contract (Backend Not Implemented)

The app is designed against these API contracts:

| Endpoint | Method | Description |
|---|---|---|
| `/auth/login` | POST | Authenticate user |
| `/auth/refresh` | POST | Refresh auth token |
| `/channels` | GET | List all channels |
| `/channels/{id}` | GET | Single channel details |
| `/categories` | GET | Channel categories |
| `/epg` | GET | EPG data |
| `/favorites` | GET/POST/DELETE | User favorites |
| `/history` | GET/POST | Watch history |
| `/playback/report` | POST | Report playback events |
| `/diagnostics/report` | POST | Submit diagnostics |

---

## Design System: Dark Luxe Broadcast

A premium dark theme with cinematic aesthetics:

- **Color Tokens** — Deep navy-blacks, gold accents, electric blue highlights
- **Typography** — Inter font family, scaled for mobile through TV
- **Spacing** — 4px-based grid system
- **Motion** — Consistent animation curves and durations
- **Components** — Channel cards, section headers, loading skeletons, error/empty states

---

## Roadmap

### Phase 2 (Next)
- [ ] Full EPG guide screen with timeline view
- [ ] Watch history screen
- [ ] Background music / audio track switching
- [ ] Platform adaptation polish (TV, Windows)

### Phase 3 (Future)
- [ ] Quote/Story Typography template
- [ ] SaaS multi-tenant architecture
- [ ] User authentication flow
- [ ] Cloud sync for favorites and history
- [ ] Push notifications for live events
- [ ] Analytics and crash reporting
- [ ] Chromecast / AirPlay support
- [ ] Picture-in-Picture mode
- [ ] Parental controls

---

## Project Structure

```
ozaiptv/
├── .github/workflows/          # CI/CD pipelines
├── android/                    # Android platform files
├── ios/                        # iOS platform files
├── windows/                    # Windows platform files
├── assets/
│   ├── images/                 # Static images
│   ├── icons/                  # Custom icons
│   ├── logos/                  # Brand logos
│   ├── mock/                   # Mock JSON data
│   └── animations/             # Lottie/Rive animations
├── lib/
│   ├── app/                    # Bootstrap, environment, app widget
│   ├── core/                   # Shared utilities, constants, enums
│   ├── design_system/          # Theme, tokens, reusable components
│   ├── domain/                 # Business entities, repository contracts
│   ├── data/                   # Implementations, data sources, DTOs
│   ├── services/               # Playback, M3U, EPG, diagnostics
│   ├── routing/                # Navigation setup
│   └── features/               # Feature screens and widgets
├── test/                       # Unit and widget tests
├── integration_test/           # Integration tests
├── pubspec.yaml
├── analysis_options.yaml
├── CHANGELOG.md
└── README.md
```

---

## License

This project is private. All rights reserved.

---

**OzaIPTV** — Premium Streaming, Engineered Right.
#   O z a I P T V  
 