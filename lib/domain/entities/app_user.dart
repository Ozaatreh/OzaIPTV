import 'package:equatable/equatable.dart';

/// Represents an authenticated user (future SaaS-ready).
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.subscription = UserSubscription.free,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final UserSubscription subscription;
  final DateTime? createdAt;

  bool get isPremium => subscription != UserSubscription.free;

  @override
  List<Object?> get props => [id, email];
}

enum UserSubscription { free, basic, premium, enterprise }
