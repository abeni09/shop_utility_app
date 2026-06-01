import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shopsync/core/presentation/widgets/theme_toggle_button.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/dashboard/presentation/dashboard_providers.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/dashboard/presentation/quick_sale_dialog.dart';
import 'package:shopsync/features/products/presentation/daily_receive_screen.dart';
import 'package:shopsync/features/products/presentation/receiving_report_screen.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/features/orders/presentation/requisition_screen.dart';
import 'package:shopsync/features/dashboard/presentation/ui_providers.dart';
import 'package:shopsync/features/dashboard/presentation/financial_report_screen.dart';
import 'package:shopsync/features/dashboard/presentation/financial_chart_widget.dart';
import 'package:shopsync/features/dashboard/presentation/low_stock_widget.dart';
import 'package:shopsync/features/backup/presentation/sync_manager_dialog.dart';
import 'dart:ui';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 1200
        ? width * 0.1
        : (width > 800 ? 48.0 : 24.0);
    final crossAxisCount = width > 1200 ? 4 : (width > 800 ? 3 : 2);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dailyLogAsync = ref.watch(dailyLogProvider);
    final ordersAsync = ref.watch(
      ordersForDateProvider((date: today, includeVoided: false)),
    );
    final userAsync = ref.watch(backupUserProvider);
    final cloudNewerAsync = ref.watch(cloudSyncStatusProvider);
    final localAheadAsync = ref.watch(localAheadProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient Mesh
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
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
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.15),
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
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            color: Theme.of(context).colorScheme.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _buildSliverAppBar(context, ref),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildGreeting(context),
                      const SizedBox(height: 24),
                      _buildCloudSync(
                        context,
                        ref,
                        userAsync,
                        cloudNewerAsync,
                        localAheadAsync,
                      ),
                      const SizedBox(height: 32),
                      _buildMainStats(dailyLogAsync),
                      const SizedBox(height: 24),
                      const FinancialWeeklyChart(),
                      const SizedBox(height: 32),
                      _buildSectionHeader('FINANCIAL INSIGHTS', context),
                      const SizedBox(height: 16),
                      _buildInsightsScroll(ref),
                      const SizedBox(height: 40),
                      const LowStockAlertWidget(),
                      const SizedBox(height: 40),
                      _buildSectionHeader('OPERATIONAL OVERVIEW', context),
                      const SizedBox(height: 16),
                      _buildOperationsGrid(ordersAsync, ref, crossAxisCount),
                      const SizedBox(height: 40),
                      _buildSectionHeader('QUICK ACTIONS', context),
                      const SizedBox(height: 16),
                      _buildQuickActionsGrid(context, ref, crossAxisCount),
                      const SizedBox(
                        height: 140,
                      ), // Extra space for FAB and Bottom Nav
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

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return SliverAppBar(
      expandedHeight: 120,
      collapsedHeight: 80,
      pinned: true,
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor.withValues(alpha: 0.8),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        centerTitle: false,
        title: Text(
          'SHOPSYNC',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : const Color(0xFF0F172A).withValues(alpha: 0.9),
          ),
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 24),
          child: ThemeToggleButton(),
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context) {
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

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.4),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Welcome back!',
              style: TextStyle(
                color: onSurface,
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
      error: (_, _) => const _HeroProfitCard(amount: 'ERR', label: 'ERROR'),
    );
  }

  Widget _buildCloudSync(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<GoogleSignInAccount?> userAsync,
    AsyncValue<bool> cloudNewerAsync,
    AsyncValue<bool> localAheadAsync,
  ) {
    return userAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (user) {
        final isCloudNewer = cloudNewerAsync.value ?? false;
        final isLocalAhead = localAheadAsync.value ?? false;

        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const SyncManagerDialog(),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.1),
                  const Color(0xFF6366F1).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_done_rounded,
                        color: Color(0xFF818CF8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user != null ? 'CLOUD SYNC ACTIVE' : 'CLOUD BACKUP',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Color(0xFF818CF8),
                            ),
                          ),
                          Text(
                            user != null
                                ? user.email
                                : 'Secure your data with Google Drive',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (user != null)
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () =>
                              ref.read(backupServiceProvider).signOut(),
                        ),
                      ),
                  ],
                ),
                if (user == null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => ref.read(backupServiceProvider).signIn(),
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text(
                        'SIGN IN WITH GOOGLE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ] else if (isCloudNewer || isLocalAhead) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (isCloudNewer)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleRestore(context, ref),
                            icon: const Icon(
                              Icons.cloud_download_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'RESTORE',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      if (isCloudNewer && isLocalAhead)
                        const SizedBox(width: 12),
                      if (isLocalAhead)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleBackup(context, ref),
                            icon: const Icon(
                              Icons.cloud_upload_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'BACKUP NOW',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'All data is backed up and synchronized',
                          style: TextStyle(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleBackup(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF818CF8)),
        ),
      );
      await ref.read(backupServiceProvider).uploadBackup(forceSignIn: true);
      if (context.mounted) {
        Navigator.pop(context);
        ref.invalidate(localAheadProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup successful!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        title: const Text(
          'RESTORE DATA?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
            color: Colors.orangeAccent,
          ),
        ),
        content: const Text(
          'This will overwrite your current local data with the version from the cloud. This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.white24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'RESTORE',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: Color(0xFF818CF8)),
            ),
          );
        }
        await ref.read(backupServiceProvider).restoreLatestBackup();
        // Force app restart logic usually needed, but here we'll just invalidate everything
        ref.invalidate(dailyLogProvider);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restore successful! Restarting data...'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restore failed: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
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
          style: TextStyle(
            letterSpacing: 2,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
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
          ref
              .watch(weeklyProfitProvider)
              .when(
                data: (stats) => _InsightCard(
                  label: 'LAST 7 DAYS',
                  value: '${stats['profit']?.toStringAsFixed(0)}',
                  color: const Color(0xFF6366F1),
                ),
                loading: () => const _InsightCard(
                  label: 'LAST 7 DAYS',
                  value: '...',
                  color: Colors.grey,
                ),
                error: (_, _) => const _InsightCard(
                  label: 'LAST 7 DAYS',
                  value: 'ERR',
                  color: Colors.redAccent,
                ),
              ),
          const SizedBox(width: 16),
          ref
              .watch(monthlyProfitProvider)
              .when(
                data: (stats) => _InsightCard(
                  label: 'LAST 30 DAYS',
                  value: '${stats['profit']?.toStringAsFixed(0)}',
                  color: const Color(0xFF10B981),
                ),
                loading: () => const _InsightCard(
                  label: 'LAST 30 DAYS',
                  value: '...',
                  color: Colors.grey,
                ),
                error: (_, _) => const _InsightCard(
                  label: 'LAST 30 DAYS',
                  value: 'ERR',
                  color: Colors.redAccent,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildOperationsGrid(
    AsyncValue ordersAsync,
    WidgetRef ref,
    int crossAxisCount,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        ordersAsync.when(
          data: (orders) {
            final total = orders.length;
            final out = orders
                .where((o) => o.status == OrderStatus.sold)
                .length;
            return _MiniOpCard(
              label: 'DELIVERIES',
              value: '$out/$total',
              sublabel: 'Completed',
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFF10B981),
            );
          },
          loading: () => const _MiniOpCard(
            label: 'DELIVERIES',
            value: '...',
            sublabel: 'Loading',
            icon: Icons.refresh,
            color: Colors.grey,
          ),
          error: (_, _) => const _MiniOpCard(
            label: 'DELIVERIES',
            value: '!',
            sublabel: 'Error',
            icon: Icons.error,
            color: Colors.redAccent,
          ),
        ),
        ref
            .watch(walkInAvailabilityProvider(DateTime.now()))
            .when(
              data: (availability) {
                final shortCount = availability.values
                    .where((v) => v.walkInAvailable < 0)
                    .length;
                return _MiniOpCard(
                  label: 'STOCK STATUS',
                  value: shortCount > 0 ? '$shortCount SHORT' : 'HEALTHY',
                  sublabel: shortCount > 0 ? 'Urgent Action' : 'All systems go',
                  icon: Icons.inventory_2_rounded,
                  color: shortCount > 0
                      ? Colors.redAccent
                      : const Color(0xFFF59E0B),
                );
              },
              loading: () => const _MiniOpCard(
                label: 'STOCK',
                value: '...',
                sublabel: 'Checking',
                icon: Icons.search,
                color: Colors.grey,
              ),
              error: (_, _) => const _MiniOpCard(
                label: 'STOCK',
                value: '!',
                sublabel: 'Error',
                icon: Icons.error,
                color: Colors.redAccent,
              ),
            ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(
    BuildContext context,
    WidgetRef ref,
    int crossAxisCount,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
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
          onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 2,
        ),
        _QuickActionCard(
          label: 'Receiving Report',
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFF10B981),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReceivingReportScreen()),
          ),
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
          Positioned(
            bottom: -20,
            right: -20,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FinancialReportScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'INSIGHTS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                  ],
                ),
              ),
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

  const _InsightCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.3),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const Expanded(child: SizedBox()),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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

  const Position({
    super.key,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.child,
  });

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
