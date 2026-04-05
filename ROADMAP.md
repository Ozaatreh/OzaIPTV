# OzaIPTV — Product Roadmap

## Completed (v1.0)

### Core
- [x] Clean Architecture with feature-first organization
- [x] Riverpod state management
- [x] go_router navigation with adaptive shell
- [x] Hive local persistence
- [x] Environment configuration (dev/staging/prod)
- [x] Mock data with legal test streams
- [x] M3U playlist parser

### Playback
- [x] HLS streaming via video_player
- [x] Multi-source fallback system (up to 4 sources)
- [x] Automatic retry + source switching
- [x] Stream health monitoring
- [x] Playback diagnostics reporting
- [x] Player abstraction (PlayerFacade)

### Features
- [x] Home dashboard with hero section
- [x] Live TV listing with category filters
- [x] Full-screen player with overlay controls
- [x] EPG guide screen with timeline
- [x] Now/next EPG overlay in player
- [x] In-player channel drawer (swipe up)
- [x] Search with debounced instant results
- [x] Favorites with local persistence
- [x] Watch history with date grouping
- [x] Settings with working controls
- [x] Diagnostics screen with fallback event log

### Design
- [x] Dark Luxe Broadcast design system
- [x] Glassmorphism components
- [x] Shimmer loading skeletons
- [x] Error and empty state components
- [x] TV focus wrapper with glow/scale

### Platform
- [x] Android mobile support
- [x] iOS support
- [x] Windows desktop support
- [x] Android TV D-pad keyboard handling
- [x] Adaptive navigation (bottom nav / side rail)
- [x] Responsive grid (2–5 columns)

### DevOps
- [x] GitHub Actions CI (lint, analyze, test, build)
- [x] GitHub Actions release pipeline (signed APK/AAB)
- [x] Comprehensive README with build instructions
- [x] Architecture documentation
- [x] SaaS migration guide

---

## v1.1 — Player Polish

- [ ] DASH protocol support (via `media_kit` or custom ExoPlayer bridge)
- [ ] Audio track selection UI
- [ ] Subtitle rendering (WebVTT, SRT)
- [ ] Picture-in-Picture mode (Android)
- [ ] Background audio playback
- [ ] Volume gesture control (swipe right side)
- [ ] Brightness gesture control (swipe left side)
- [ ] Double-tap to seek forward/backward
- [ ] Playback speed control
- [ ] Buffer health indicator in controls

---

## v1.2 — Content Discovery

- [ ] Channel detail screen (description, schedule, related)
- [ ] Category landing pages with curated sections
- [ ] "Trending Now" section based on watch data
- [ ] Channel recommendations based on history
- [ ] Recently added channels section
- [ ] Country/language filter in Live TV
- [ ] Sort options (name, popularity, recently added)

---

## v1.3 — EPG Enhancement

- [ ] Full XMLTV parser service
- [ ] Horizontal timeline grid (traditional EPG view)
- [ ] Program detail bottom sheet
- [ ] Program reminders / notifications
- [ ] Multi-day EPG navigation
- [ ] Search within EPG programs
- [ ] EPG data caching with TTL

---

## v1.4 — Casting & Multi-Screen

- [ ] Chromecast support
- [ ] AirPlay support
- [ ] DLNA/UPnP discovery
- [ ] Multi-screen: browse on phone, play on TV
- [ ] QR code pairing for TV ↔ phone

---

## v2.0 — SaaS Foundation

- [ ] Backend API server deployment
- [ ] User authentication (email/password, social)
- [ ] Cloud sync for favorites and history
- [ ] Admin panel for channel management
- [ ] M3U import via API
- [ ] XMLTV import via API
- [ ] Tenant isolation (multi-org support)
- [ ] Role-based access control

---

## v2.1 — Monetization

- [ ] Subscription tiers (Free, Basic, Premium)
- [ ] Stripe integration
- [ ] Google Play Billing
- [ ] App Store In-App Purchase
- [ ] Usage metering dashboard
- [ ] Trial period support
- [ ] Promo code system

---

## v2.2 — Analytics & Observability

- [ ] Sentry crash reporting
- [ ] Mixpanel/PostHog event tracking
- [ ] Stream quality analytics dashboard
- [ ] User engagement metrics
- [ ] A/B testing framework
- [ ] Server-side feature flags

---

## v3.0 — White-Label Platform

- [ ] Per-tenant theming (colors, logo, app name)
- [ ] Custom domain support
- [ ] Branded APK generation pipeline
- [ ] Tenant onboarding wizard
- [ ] API key management for integrators
- [ ] Webhook support for external systems
- [ ] White-label documentation

---

## Extension Points in Current Codebase

| Extension Point | Location | Description |
|---|---|---|
| Player implementation | `services/playback/player_facade.dart` | Swap video_player for ExoPlayer/AVPlayer |
| Data source swap | `data/repositories/*_impl.dart` | Add API data sources alongside mock |
| Auth flow | `services/auth/`, `routing/route_guards.dart` | Implement login/signup screens |
| Stream protocols | `core/enums/stream_protocol.dart` | Add RTMP, WebRTC, etc. |
| EPG sources | `data/datasources/mock_epg_datasource.dart` | Add XMLTV parser, API source |
| API client | `core/network/dio_client.dart` | Add auth interceptor, retry logic |
| Theme variants | `design_system/theme/app_theme.dart` | Light theme, per-tenant themes |
| Notifications | New service in `services/notifications/` | FCM integration |
| Analytics | New service in `services/analytics/` | Event tracking |
