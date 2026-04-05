import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/tokens/colors.dart';
import '../../../../design_system/tokens/spacing.dart';
import '../../../../routing/route_names.dart';

/// Placeholder login screen — ready for auth implementation.
///
/// Extension point: wire to AuthService + backend /auth/login.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.live_tv_rounded,
                  color: AppColors.textOnAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'OzaIPTV',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to your account',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 40),

              // Email field
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password field
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO(auth): Implement login via AuthService
                    context.goNamed(RouteNames.home);
                  },
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 16),

              // Skip (for personal/dev mode)
              TextButton(
                onPressed: () => context.goNamed(RouteNames.home),
                child: const Text('Continue without account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
