import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopsync/core/utils/database_service.dart';
import 'package:shopsync/features/products/presentation/product_list_screen.dart';
import 'package:shopsync/features/orders/presentation/order_screen.dart';
import 'package:shopsync/features/suppliers/presentation/supplier_list_screen.dart';
import 'package:shopsync/features/sales/presentation/sales_screen.dart';
import 'package:shopsync/features/dashboard/presentation/dashboard_screen.dart';

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

class ShopSyncApp extends StatelessWidget {
  const ShopSyncApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});
  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _selectedIndex = 0;
  final _screens = [
    const DashboardScreen(),
    const OrderScreen(),
    const SalesScreen(),
    const ProductListScreen(),
    const SupplierListScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
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
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  );
                }
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white38,
                );
              }),
            ),
            child: NavigationBar(
              backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.8),
              elevation: 0,
              height: 72,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: [
                _buildNavItem(
                  Icons.grid_view_rounded,
                  Icons.grid_view_rounded,
                  'Home',
                  0,
                ),
                _buildNavItem(
                  Icons.receipt_long_rounded,
                  Icons.receipt_long_rounded,
                  'Orders',
                  1,
                ),
                _buildNavItem(
                  Icons.history_rounded,
                  Icons.history_rounded,
                  'Sales',
                  2,
                ),
                _buildNavItem(
                  Icons.inventory_2_rounded,
                  Icons.inventory_2_rounded,
                  'Stock',
                  3,
                ),
                _buildNavItem(
                  Icons.local_shipping_rounded,
                  Icons.local_shipping_rounded,
                  'Suppliers',
                  4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavItem(
    IconData icon,
    IconData selectedIcon,
    String label,
    int index,
  ) {
    return NavigationDestination(
      icon: Icon(icon, color: Colors.white38),
      selectedIcon: Icon(selectedIcon, color: const Color(0xFF818CF8)),
      label: label,
    );
  }
}

