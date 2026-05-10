import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopsync/core/utils/database_service.dart';
import 'package:shopsync/features/products/presentation/product_list_screen.dart';
import 'package:shopsync/features/orders/presentation/order_screen.dart';
import 'package:shopsync/features/suppliers/presentation/supplier_list_screen.dart';
import 'package:shopsync/features/orders/presentation/requisition_screen.dart';
import 'package:shopsync/features/dashboard/presentation/dashboard_providers.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/dashboard/presentation/quick_sale_dialog.dart';

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

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});
  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;
  final _screens = [
    const DashboardScreen(),
    const OrderScreen(),
    const ProductListScreen(),
    const SupplierListScreen(),
  ];

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
                  Icons.inventory_2_rounded,
                  Icons.inventory_2_rounded,
                  'Stock',
                  2,
                ),
                _buildNavItem(
                  Icons.local_shipping_rounded,
                  Icons.local_shipping_rounded,
                  'Suppliers',
                  3,
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
    final isSelected = _selectedIndex == index;
    return NavigationDestination(
      icon: Icon(icon, color: Colors.white38),
      selectedIcon: Icon(selectedIcon, color: const Color(0xFF818CF8)),
      label: label,
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLogAsync = ref.watch(dailyLogProvider);
    final ordersAsync = ref.watch(ordersProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF020617)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              backgroundColor: Colors.transparent,
              title: const Text('SHOPSYNC'),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF818CF8),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildGreeting(),
                  const SizedBox(height: 28),
                  dailyLogAsync.when(
                    data: (log) => _buildHeroCard(
                      'NET PROFIT TODAY',
                      log?.totalProfit.toStringAsFixed(2) ?? "0.00",
                      'ETB',
                      const [Color(0xFF6366F1), Color(0xFF818CF8)],
                      Icons.account_balance_wallet_rounded,
                    ),
                    loading: () => _buildHeroCard(
                      'NET PROFIT TODAY',
                      '...',
                      'ETB',
                      [Colors.grey.shade800, Colors.grey.shade900],
                      Icons.hourglass_empty,
                    ),
                    error: (_, _) => _buildHeroCard(
                      'NET PROFIT TODAY',
                      'ERROR',
                      '',
                      [Colors.red.shade900, Colors.red.shade800],
                      Icons.error_outline,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'FINANCIAL INSIGHTS',
                    style: TextStyle(
                      letterSpacing: 2.5,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        ref
                            .watch(weeklyProfitProvider)
                            .when(
                              data: (stats) => _buildInsightCard(
                                'LAST 7 DAYS',
                                '${stats['profit']?.toStringAsFixed(0)}',
                                Colors.indigoAccent,
                              ),
                              loading: () => _buildInsightCard(
                                'LAST 7 DAYS',
                                '...',
                                Colors.grey,
                              ),
                              error: (_, _) => _buildInsightCard(
                                'LAST 7 DAYS',
                                'ERR',
                                Colors.redAccent,
                              ),
                            ),
                        const SizedBox(width: 12),
                        ref
                            .watch(monthlyProfitProvider)
                            .when(
                              data: (stats) => _buildInsightCard(
                                'LAST 30 DAYS',
                                '${stats['profit']?.toStringAsFixed(0)}',
                                Colors.greenAccent,
                              ),
                              loading: () => _buildInsightCard(
                                'LAST 30 DAYS',
                                '...',
                                Colors.grey,
                              ),
                              error: (_, _) => _buildInsightCard(
                                'LAST 30 DAYS',
                                'ERR',
                                Colors.redAccent,
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ordersAsync.when(
                          data: (orders) {
                            final total = orders.length;
                            final out = orders
                                .where((o) => o.status == OrderStatus.sold)
                                .length;
                            return _buildMiniStat(
                              'DELIVERY',
                              '$out/$total',
                              'Fulfilled',
                              const Color(0xFF10B981),
                            );
                          },
                          loading: () => _buildMiniStat(
                            'DELIVERY',
                            '...',
                            '...',
                            Colors.grey,
                          ),
                          error: (_, _) => _buildMiniStat(
                            'DELIVERY',
                            '!',
                            'Err',
                            Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMiniStat(
                          'ALERTS',
                          '0',
                          'No Issues',
                          const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      letterSpacing: 2.5,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildActionGrid(context, ref),
                  const SizedBox(height: 24),
                  _buildBackupTile(context, ref),
                  const SizedBox(
                    height: 120,
                  ), // Bottom padding for FAB and Nav Bar
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Command Center',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.indigo.shade300,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Welcome back, Admin',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(
    String label,
    String value,
    String unit,
    List<Color> colors,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.1),
              size: 120,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String label, String value, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white24,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'ETB',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _buildGlassAction(
            'Quick Sale',
            Icons.bolt_rounded,
            const Color(0xFF818CF8),
            () => showDialog(
              context: context,
              builder: (_) => const QuickSaleDialog(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGlassAction(
            'Requisition',
            Icons.shopping_cart_rounded,
            const Color(0xFFF472B6),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RequisitionScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupTile(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(backupUserProvider);
    final user = userAsync.value;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () async {
              final backupService = ref.read(backupServiceProvider);
              try {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connecting to Google Drive...')));
                final success = await backupService.signIn();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing with Cloud...')));
                  await backupService.uploadBackup();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF10B981),
                        content: Text('Backup Secured Successfully!', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sign-in cancelled or interrupted.')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.redAccent,
                      content: Text('Cloud Sync Failed: ${e.toString().split(':').last}'),
                    ),
                  );
                }
              }
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            leading: const Icon(Icons.cloud_done_rounded, color: Color(0xFF38BDF8)),
            title: const Text(
              'CLOUD SYNC & BACKUP',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
            ),
            subtitle: Text(
              user != null ? 'Connected: ${user.email}' : 'Secure your data to Google Drive',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
            ),
            trailing: user != null
                ? IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    onPressed: () async {
                      await ref.read(backupServiceProvider).signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disconnected from Google Account')));
                      }
                    },
                  )
                : const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ),
        ],
      ),
    );
  }
}
