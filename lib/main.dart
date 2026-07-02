import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopsync/core/utils/database_service.dart';
import 'package:shopsync/features/dashboard/presentation/ui_providers.dart';
import 'package:shopsync/features/products/presentation/product_list_screen.dart';
import 'package:shopsync/features/orders/presentation/order_screen.dart';
import 'package:shopsync/features/suppliers/presentation/supplier_list_screen.dart';
import 'package:shopsync/features/sales/presentation/sales_screen.dart';
import 'package:shopsync/features/dashboard/presentation/dashboard_screen.dart';
import 'package:shopsync/features/license/presentation/license_guard_shell.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService not initialized');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbService = await DatabaseService.create();
  runApp(
    ProviderScope(
      overrides: [databaseServiceProvider.overrideWithValue(dbService)],
      child: const ShopSyncApp(),
    ),
  );
}

class ShopSyncApp extends ConsumerWidget {
  const ShopSyncApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'ShopSync',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
          surface: Colors.white,
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF10B981),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A),
          primary: const Color(0xFF818CF8),
          secondary: const Color(0xFF10B981),
        ),
        scaffoldBackgroundColor: const Color(0xFF020617),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
      home: const LicenseGuardShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  DateTime? _lastPressed;

  static const _screens = [
    DashboardScreen(),
    OrderScreen(),
    SalesScreen(),
    ProductListScreen(),
    SupplierListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final selectedIndex = ref.watch(bottomNavIndexProvider);
        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 600;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            final now = DateTime.now();
            final maxDuration = const Duration(seconds: 2);
            final isWarningTarget =
                _lastPressed == null ||
                now.difference(_lastPressed!) > maxDuration;

            if (isWarningTarget) {
              _lastPressed = now;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'PRESS BACK AGAIN TO EXIT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: maxDuration,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            } else {
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            }
          },
          child: Scaffold(
            extendBody: true,
            resizeToAvoidBottomInset: true,
            body: Row(
              children: [
                if (!isMobile)
                  _buildNavigationRail(context, ref, selectedIndex),
                Expanded(
                  child: IndexedStack(index: selectedIndex, children: _screens),
                ),
              ],
            ),
            bottomNavigationBar: isMobile
                ? _buildBottomNavigationBar(context, ref, selectedIndex)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            ref.read(bottomNavIndexProvider.notifier).state = index,
        labelType: NavigationRailLabelType.all,
        useIndicator: true,
        indicatorColor: const Color(0xFF818CF8).withValues(alpha: 0.2),
        selectedLabelTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        destinations: [
          _buildRailDestination(context, Icons.grid_view_rounded, 'Home'),
          _buildRailDestination(context, Icons.receipt_long_rounded, 'Orders'),
          _buildRailDestination(context, Icons.history_rounded, 'Sales'),
          _buildRailDestination(context, Icons.inventory_2_rounded, 'Stock'),
          _buildRailDestination(
            context,
            Icons.local_shipping_rounded,
            'Suppliers',
          ),
        ],
      ),
    );
  }

  NavigationRailDestination _buildRailDestination(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationRailDestination(
      icon: Icon(icon, color: colorScheme.onSurface.withValues(alpha: 0.4)),
      selectedIcon: Icon(icon, color: colorScheme.primary),
      label: Text(label),
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.2),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                );
              }
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              );
            }),
          ),
          child: NavigationBar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.8),
            elevation: 0,
            height: 72,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                ref.read(bottomNavIndexProvider.notifier).state = index,
            destinations: [
              _buildNavItem(context, Icons.grid_view_rounded, 'Home'),
              _buildNavItem(context, Icons.receipt_long_rounded, 'Orders'),
              _buildNavItem(context, Icons.history_rounded, 'Sales'),
              _buildNavItem(context, Icons.inventory_2_rounded, 'Stock'),
              _buildNavItem(context, Icons.local_shipping_rounded, 'Suppliers'),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationDestination(
      icon: Icon(icon, color: colorScheme.onSurface.withValues(alpha: 0.4)),
      selectedIcon: Icon(icon, color: colorScheme.primary),
      label: '',
    );
  }
}
