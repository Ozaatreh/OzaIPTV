# OzaIPTV — SaaS Migration Guide

This document outlines the steps and architectural changes required to evolve OzaIPTV from a personal IPTV app into a multi-tenant SaaS platform.

---

## Current State (Personal App)

- **Data source**: Local mock JSON + M3U parsing
- **Auth**: Structure-ready, not implemented
- **Storage**: Hive (device-local)
- **Sync**: None
- **Multi-user**: No
- **Billing**: No

---

## Phase 1: Backend Integration

### 1.1 — Deploy API Server

Implement the API contracts already defined in `lib/services/api/api_contracts.dart`:

```
POST   /auth/login
POST   /auth/refresh
GET    /channels
GET    /channels/{id}
GET    /categories
GET    /epg
GET/POST/DELETE /favorites
GET/POST       /history
POST   /playback/report
POST   /diagnostics/report
```

**Recommended stack**: Node.js + Fastify, or Dart Shelf, backed by PostgreSQL + Redis.

### 1.2 — Swap Data Sources

The app already uses the **Repository pattern**. To migrate:

1. Create `ApiChannelDataSource` implementing the same interface as `MockChannelDataSource`
2. Update `channelRepositoryProvider` to inject `ApiChannelDataSource` when `!EnvironmentConfig.enableMockData`
3. Repeat for EPG, favorites, history

```dart
final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  if (EnvironmentConfig.enableMockData) {
    return ChannelRepositoryImpl(ref.watch(mockChannelDataSourceProvider));
  }
  return ApiChannelRepositoryImpl(ref.watch(apiChannelDataSourceProvider));
});
```

### 1.3 — Authentication Flow

1. Implement `AuthService` in `lib/services/auth/`
2. Store tokens securely (`flutter_secure_storage`)
3. Wire `RouteGuards.authGuard` into go_router's `redirect`
4. Add auth interceptor to Dio client for token refresh

---

## Phase 2: Multi-Tenancy

### 2.1 — Tenant Isolation

**Database**: Row-level tenancy with `tenant_id` column on all tables.

**API**: Include `X-Tenant-ID` header or derive from JWT claims.

**App**: Store tenant context in the auth token. No client-side changes needed — the API returns only tenant-scoped data.

### 2.2 — User Roles

| Role | Capabilities |
|---|---|
| Viewer | Watch, favorite, history |
| Admin | Manage channels, sources, categories |
| Super Admin | Manage tenants, billing, analytics |

Add `role` field to `AppUser` entity and implement role-based route guards.

### 2.3 — Channel Management

Build an admin panel (web or in-app) for:
- CRUD channels and categories
- Managing stream sources per channel
- Uploading M3U playlists via API
- EPG data import (XMLTV)

---

## Phase 3: Billing & Subscriptions

### 3.1 — Subscription Tiers

| Tier | Channels | Features |
|---|---|---|
| Free | Public/demo channels only | Basic player |
| Basic | Up to 100 channels | Favorites, history |
| Premium | Unlimited | EPG, multi-device, priority support |
| Enterprise | Custom | White-label, API access, analytics |

### 3.2 — Payment Integration

- **Stripe** for web/API payments
- **Google Play Billing** for Android
- **App Store In-App Purchase** for iOS
- Store subscription status in `AppUser.subscription`
- Gate features in the app with `premiumGuard`

### 3.3 — Usage Metering

Track:
- Concurrent viewers per tenant
- Bandwidth consumption
- Stream health metrics (via `/playback/report`)
- Device count per user

---

## Phase 4: Infrastructure

### 4.1 — CDN & Stream Proxying

For SaaS, you likely need:
- **CDN** (CloudFront, Bunny, Cloudflare Stream) for stream delivery
- **Origin shield** for source protection
- **Token-based stream authentication** (signed URLs with expiry)
- **Adaptive bitrate packaging** (AWS MediaConvert, Mux)

### 4.2 — Observability

- **Crash reporting**: Sentry or Firebase Crashlytics
- **Analytics**: Mixpanel, Amplitude, or PostHog
- **Server monitoring**: Grafana + Prometheus
- **Stream health dashboard**: Built from `/diagnostics/report` data

### 4.3 — Push Notifications

- **Firebase Cloud Messaging** (Android, iOS, Web)
- Notify users of: live events starting, new channels, system maintenance

---

## Migration Checklist

```
[ ] Deploy API server with auth endpoints
[ ] Create ApiChannelDataSource
[ ] Swap repository providers based on environment
[ ] Implement secure token storage
[ ] Wire auth guard into router
[ ] Add Dio auth interceptor with token refresh
[ ] Test end-to-end: login → browse → play → favorite → history
[ ] Add tenant_id to all API endpoints
[ ] Build admin panel for channel management
[ ] Integrate Stripe / Play Billing / IAP
[ ] Add usage metering endpoints
[ ] Configure CDN for stream delivery
[ ] Add signed URL support to stream sources
[ ] Integrate crash reporting and analytics
[ ] Set up push notifications
[ ] White-label theming support (per-tenant colors/logo)
```

---

## Code Changes Summary

| Area | Change | Effort |
|---|---|---|
| Data sources | Add API implementations | Medium |
| Auth | Implement full flow | Medium |
| Routing | Wire auth guards | Small |
| Network | Add auth interceptor | Small |
| Entities | Add tenant/role fields | Small |
| Settings | Cloud sync | Medium |
| Billing | Payment integration | Large |
| Admin | Channel management UI | Large |
| Infrastructure | CDN, monitoring | Large |

The architecture is already designed for this migration. No structural rewrites are needed — it's additive work on top of the existing clean architecture.
