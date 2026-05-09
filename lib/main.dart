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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
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
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Suppliers',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLogAsync = ref.watch(dailyLogProvider);
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SHOPSYNC'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ordersAsync.when(
              data: (orders) {
                final total = orders.length;
                final out = orders
                    .where((o) => o.status == OrderStatus.sold)
                    .length;
                return _buildStatCard(
                  'Today\'s Delivery',
                  '$out / $total Fulfilled',
                  Colors.cyan,
                );
              },
              loading: () =>
                  _buildStatCard('Today\'s Delivery', '...', Colors.cyan),
              error: (_, _) =>
                  _buildStatCard('Today\'s Delivery', 'Error', Colors.red),
            ),
            const SizedBox(height: 16),
            dailyLogAsync.when(
              data: (log) => _buildStatCard(
                'Net Profit Today',
                '${log?.totalProfit.toStringAsFixed(2) ?? "0.00"} ETB',
                Colors.green,
              ),
              loading: () =>
                  _buildStatCard('Net Profit Today', '...', Colors.green),
              error: (_, _) =>
                  _buildStatCard('Net Profit Today', 'Error', Colors.red),
            ),
            const SizedBox(height: 32),
            const Text(
              'CONTROL PANEL',
              style: TextStyle(
                letterSpacing: 2,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    context,
                    'Quick Sale',
                    Icons.bolt,
                    Colors.cyan,
                    () {
                      showDialog(
                        context: context,
                        builder: (_) => const QuickSaleDialog(),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionTile(
                    context,
                    'Requisition',
                    Icons.shopping_basket,
                    Colors.amber,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RequisitionScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              context,
              'Cloud Backup',
              Icons.cloud_upload,
              Colors.blue,
              () async {
                final backupService = ref.read(backupServiceProvider);
                final success = await backupService.signIn();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Uploading backup to Google Drive...'),
                    ),
                  );
                  await backupService.uploadBackup();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup successful!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sign-in failed. Please try again.'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              letterSpacing: 1.2,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
