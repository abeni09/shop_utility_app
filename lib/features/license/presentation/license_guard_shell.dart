import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/license/presentation/license_provider.dart';
import 'package:shopsync/features/license/presentation/activation_screen.dart';
import 'package:shopsync/main.dart';

class LicenseGuardShell extends ConsumerWidget {
  const LicenseGuardShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(licenseStateProvider);

    switch (state.status) {
      case LicenseStatus.checking:
        return const Scaffold(
          backgroundColor: Color(0xFF020617),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF6366F1),
                  strokeWidth: 4,
                ),
                SizedBox(height: 24),
                Text(
                  'Verifying activation license...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      case LicenseStatus.active:
        return const MainNavigationShell();
      case LicenseStatus.expired:
      case LicenseStatus.clockTampered:
      case LicenseStatus.notActivated:
        return const ActivationScreen();
    }
  }
}
