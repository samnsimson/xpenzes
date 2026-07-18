import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/navigation/screens/root_shell.dart';

class XpenzesApp extends ConsumerWidget {
  const XpenzesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Xpenzes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ref
          .watch(authProvider)
          .when(
            loading: () => const _SplashScreen(),
            error: (_, _) => const AuthScreen(),
            data: (user) {
              if (user == null) return const AuthScreen();
              if (!user.isOnboarded) return const OnboardingScreen();
              return const RootShell();
            },
          ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Xpenzes',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading...',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
