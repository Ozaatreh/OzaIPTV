import 'package:flutter/material.dart';

/// Route guards for authentication and feature gating.
///
/// Extension point: wire this into go_router's `redirect`
/// when auth is implemented.
class RouteGuards {
  const RouteGuards._();

  /// Check if the user is authenticated.
  /// Returns the redirect path, or null if access is allowed.
  static String? authGuard(BuildContext context) {
    // TODO(auth): Check auth state from Riverpod provider
    // final isAuthenticated = ...;
    // if (!isAuthenticated) return '/auth/login';
    return null;
  }

  /// Check if the user has premium access.
  static String? premiumGuard(BuildContext context) {
    // TODO(auth): Check subscription status
    return null;
  }
}
