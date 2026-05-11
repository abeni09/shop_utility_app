import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/dashboard/presentation/dashboard_providers.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/dashboard/presentation/quick_sale_dialog.dart';
import 'package:shopsync/features/products/presentation/daily_receive_screen.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/features/orders/presentation/requisition_screen.dart';
import 'package:shopsync/features/sales/presentation/sales_screen.dart';
import 'dart:ui';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dailyLogAsync = ref.watch(dailyLogProvider);
    final ordersAsync = ref.watch(ordersForDateProvider((date: today, includeVoided: false)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient Mesh
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF020617),
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          RefreshIndicator(
            onRefresh: () async {
              await ref.read(backupServiceProvider).forceSyncCheck();
              ref.invalidate(cloudSyncStatusProvider);
              ref.invalidate(localAheadProvider);
              ref.invalidate(weeklyProfitProvider);
              ref.invalidate(monthlyProfitProvider);
            },
            backgroundColor: const Color(0xFF1E293B),
            color: const Color(0xFF818CF8),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _buildSliverAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildGreeting(),
                      const SizedBox(height: 32),
                      _buildMainStats(dailyLogAsync),
                      const SizedBox(height: 40),
                      _buildSectionHeader('FINANCIAL INSIGHTS'),
                      const SizedBox(height: 16),
                      _buildInsightsScroll(ref),
                      const SizedBox(height: 40),
                      _buildSectionHeader('OPERATIONAL OVERVIEW'),
                      const SizedBox(height: 16),
                      _buildOperationsGrid(ordersAsync, ref),
                      const SizedBox(height: 40),
                      _buildSectionHeader('QUICK ACTIONS'),
                      const SizedBox(height: 16),
                      _buildQuickActionsGrid(context, ref),
                      const SizedBox(height: 140), // Extra space for FAB and Bottom Nav
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      collapsedHeight: 80,
      pinned: true,
      backgroundColor: const Color(0xFF020617).withValues(alpha: 0.8),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        centerTitle: false,
        title: Text(
          'SHOPSYNC',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: _CircleIconButton(
            icon: Icons.notifications_none_rounded,
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    IconData icon = Icons.wb_sunny_rounded;
    Color color = Colors.orangeAccent;

    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      icon = Icons.wb_twilight_rounded;
      color = Colors.amberAccent;
    } else if (hour >= 17 || hour < 5) {
      greeting = 'Good Evening';
      icon = Icons.nightlight_round;
      color = Colors.indigoAccent;
    }

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const Text(
              'Welcome back!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ],
    );
  }

  Widget _buildMainStats(AsyncValue dailyLogAsync) {
    return dailyLogAsync.when(
      data: (log) => _HeroProfitCard(
        amount: log?.totalProfit.toStringAsFixed(2) ?? "0.00",
        label: 'NET PROFIT TODAY',
      ),
      loading: () => const _HeroProfitCard(amount: '...', label: 'LOADING...'),
      error: (_, __) => const _HeroProfitCard(amount: 'ERR', label: 'ERROR'),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            letterSpacing: 2,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsScroll(WidgetRef ref) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          ref.watch(weeklyProfitProvider).when(
                data: (stats) => _InsightCard(
                  label: 'LAST 7 DAYS',
                  value: '${stats['profit']?.toStringAsFixed(0)}',
                  color: const Color(0xFF6366F1),
                ),
                loading: () => const _InsightCard(label: 'LAST 7 DAYS', value: '...', color: Colors.grey),
                error: (_, __) => const _InsightCard(label: 'LAST 7 DAYS', value: 'ERR', color: Colors.redAccent),
              ),
          const SizedBox(width: 16),
          ref.watch(monthlyProfitProvider).when(
                data: (stats) => _InsightCard(
                  label: 'LAST 30 DAYS',
                  value: '${stats['profit']?.toStringAsFixed(0)}',
                  color: const Color(0xFF10B981),
                ),
                loading: () => const _InsightCard(label: 'LAST 30 DAYS', value: '...', color: Colors.grey),
                error: (_, __) => const _InsightCard(label: 'LAST 30 DAYS', value: 'ERR', color: Colors.redAccent),
              ),
        ],
      ),
    );
  }

  Widget _buildOperationsGrid(AsyncValue ordersAsync, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: ordersAsync.when(
            data: (orders) {
              final total = orders.length;
              final out = orders.where((o) => o.status == OrderStatus.sold).length;
              return _MiniOpCard(
                label: 'DELIVERIES',
                value: '$out/$total',
                sublabel: 'Completed',
                icon: Icons.local_shipping_rounded,
                color: const Color(0xFF10B981),
              );
            },
            loading: () => const _MiniOpCard(label: 'DELIVERIES', value: '...', sublabel: 'Loading', icon: Icons.refresh, color: Colors.grey),
            error: (_, __) => const _MiniOpCard(label: 'DELIVERIES', value: '!', sublabel: 'Error', icon: Icons.error, color: Colors.redAccent),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ref.watch(walkInAvailabilityProvider(DateTime.now())).when(
                data: (availability) {
                  final shortCount = availability.values.where((v) => v.walkInAvailable < 0).length;
                  return _MiniOpCard(
                    label: 'STOCK STATUS',
                    value: shortCount > 0 ? '$shortCount SHORT' : 'HEALTHY',
                    sublabel: shortCount > 0 ? 'Urgent Action' : 'All systems go',
                    icon: Icons.inventory_2_rounded,
                    color: shortCount > 0 ? Colors.redAccent : const Color(0xFFF59E0B),
                  );
                },
                loading: () => const _MiniOpCard(label: 'STOCK', value: '...', sublabel: 'Checking', icon: Icons.search, color: Colors.grey),
                error: (_, __) => const _MiniOpCard(label: 'STOCK', value: '!', sublabel: 'Error', icon: Icons.error, color: Colors.redAccent),
              ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _QuickActionCard(
          label: 'Quick Sell',
          icon: Icons.bolt_rounded,
          color: const Color(0xFFF59E0B),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const QuickSaleDialog(),
          ),
        ),
        _QuickActionCard(
          label: 'Receive Stock',
          icon: Icons.add_business_rounded,
          color: const Color(0xFF10B981),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyReceiveScreen()),
          ),
        ),
        _QuickActionCard(
          label: 'New Requisition',
          icon: Icons.assignment_rounded,
          color: const Color(0xFF6366F1),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RequisitionScreen()),
          ),
        ),
        _QuickActionCard(
          label: 'View History',
          icon: Icons.analytics_rounded,
          color: const Color(0xFF818CF8),
          onTap: () {
             // We can jump to sales tab or open a summary
          },
        ),
      ],
    );
  }
}

class _HeroProfitCard extends StatelessWidget {
  final String amount;
  final String label;

  const _HeroProfitCard({required this.amount, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Position(
            bottom: -20,
            right: -20,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8, left: 8),
                      child: Text(
                        'ETB',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InsightCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Text(
            '$value ETB',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniOpCard extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final IconData icon;
  final Color color;

  const _MiniOpCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.4),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF818CF8), size: 20),
        onPressed: onPressed,
      ),
    );
  }
}

class Position extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final Widget child;

  const Position({super.key, this.top, this.bottom, this.left, this.right, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}
