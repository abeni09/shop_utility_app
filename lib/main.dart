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
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      extendBody: true,
      body: Row(
        children: [
          if (!isMobile)
            _buildNavigationRail(),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: isMobile ? _buildBottomNavigationBar() : null,
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        labelType: NavigationRailLabelType.all,
        useIndicator: true,
        indicatorColor: const Color(0xFF818CF8).withValues(alpha: 0.2),
        selectedLabelTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        destinations: [
          _buildRailDestination(Icons.grid_view_rounded, 'Home'),
          _buildRailDestination(Icons.receipt_long_rounded, 'Orders'),
          _buildRailDestination(Icons.history_rounded, 'Sales'),
          _buildRailDestination(Icons.inventory_2_rounded, 'Stock'),
          _buildRailDestination(Icons.local_shipping_rounded, 'Suppliers'),
        ],
      ),
    );
  }

  NavigationRailDestination _buildRailDestination(IconData icon, String label) {
    return NavigationRailDestination(
      icon: Icon(icon, color: Colors.white38),
      selectedIcon: Icon(icon, color: const Color(0xFF818CF8)),
      label: Text(label),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: const Color(0xFF818CF8).withValues(alpha: 0.2),
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
              _buildNavItem(Icons.grid_view_rounded, 'Home'),
              _buildNavItem(Icons.receipt_long_rounded, 'Orders'),
              _buildNavItem(Icons.history_rounded, 'Sales'),
              _buildNavItem(Icons.inventory_2_rounded, 'Stock'),
              _buildNavItem(Icons.local_shipping_rounded, 'Suppliers'),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavItem(IconData icon, String label) {
    return NavigationDestination(
      icon: Icon(icon, color: Colors.white38),
      selectedIcon: Icon(icon, color: const Color(0xFF818CF8)),
      label: label,
    );
  }
}

