import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
import 'package:shopsync/main.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/license/presentation/license_provider.dart';
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
                      _buildCloudSync(
                        context,
                        ref,
                        userAsync,
                        cloudNewerAsync,
                        localAheadAsync,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader('COMMAND CENTER', context),
                      const SizedBox(height: 12),
                      _buildQuickActionsDock(context, ref),
                      // const SizedBox(height: 32),
                      _buildMainStats(dailyLogAsync),
                      const SizedBox(height: 24),
                      const FinancialWeeklyChart(),
                      const SizedBox(height: 32),
                      _buildSectionHeader('FINANCIAL INSIGHTS', context),
                      const SizedBox(height: 16),
                      _buildInsightsScroll(ref),
                      const SizedBox(height: 40),
                      const LowStockAlertWidget(),
                      // const SizedBox(height: 40),
                      // _buildSectionHeader('OPERATIONAL OVERVIEW', context),
                      // const SizedBox(height: 16),
                      // _buildOperationsGrid(ordersAsync, ref, crossAxisCount),
                      const SizedBox(
                        height: 140,
                      ), // Extra space for FAB and Bottom Nav
                      const SizedBox(height: 32),
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
    final hour = DateTime.now().hour;
    String greetingText = 'Good Morning';
    IconData icon = Icons.wb_sunny_rounded;
    Color color = Colors.orangeAccent;

    if (hour >= 12 && hour < 17) {
      greetingText = 'Good Afternoon';
      icon = Icons.wb_twilight_rounded;
      color = Colors.amberAccent;
    } else if (hour >= 17 || hour < 5) {
      greetingText = 'Good Evening';
      icon = Icons.nightlight_round;
      color = Colors.indigoAccent;
    }

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor.withValues(alpha: 0.8),
      toolbarHeight: 80,
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greetingText,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Welcome back!',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _buildLicenseStatusChip(context, ref),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildLicenseStatusChip(BuildContext context, WidgetRef ref) {
    final licenseState = ref.watch(licenseStateProvider);
    final expiry = licenseState.expiryDate;
    if (expiry == null) return const SizedBox.shrink();

    final days = expiry.difference(DateTime.now()).inDays;

    // Choose color depending on days remaining
    final isCritical = days <= 7;
    final themeColor = isCritical ? Colors.redAccent : const Color(0xFF10B981);

    return Center(
      child: GestureDetector(
        onTap: () => _showLicenseDetailsSheet(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCritical
                    ? Icons.warning_amber_rounded
                    : Icons.vpn_key_rounded,
                color: themeColor,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '$days ${days == 1 ? "day" : "days"} left',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: themeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLicenseDetailsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final licenseState = ref.watch(licenseStateProvider);
            final expiry = licenseState.expiryDate;
            final key = licenseState.licenseKey ?? 'N/A';
            final days = expiry != null
                ? expiry.difference(DateTime.now()).inDays
                : 0;

            String maskedKey = key;
            if (key.length > 8) {
              maskedKey =
                  '${key.substring(0, 4)}-****-${key.substring(key.length - 4)}';
            }

            final themeColor = days <= 7
                ? Colors.redAccent
                : const Color(0xFF818CF8);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'LICENSE DETAILS',
                      style: TextStyle(
                        color: Colors.white30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            days <= 7
                                ? Icons.warning_amber_rounded
                                : Icons.vpn_key_rounded,
                            color: themeColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$days ${days == 1 ? "Day" : "Days"} Remaining',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              days <= 7
                                  ? 'Your trial/license is expiring soon!'
                                  : 'Active subscription license',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    _buildInfoRow('License Key', maskedKey),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Expires On',
                      expiry != null
                          ? DateFormat('MMMM d, yyyy').format(expiry)
                          : 'N/A',
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF0F172A),
                                  title: const Text(
                                    'Forget License Key?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    'This will clear your local license key. You will need to re-activate the app.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text(
                                        'CANCEL',
                                        style: TextStyle(color: Colors.white24),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'CLEAR KEY',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                                await ref
                                    .read(licenseStateProvider.notifier)
                                    .deactivate();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: BorderSide(
                                color: Colors.redAccent.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'CLEAR KEY',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              _showChangeKeyDialog(context, ref);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'RENEW / CHANGE',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white30,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  void _showChangeKeyDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false;
            String? errorMsg;

            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'ENTER NEW LICENSE KEY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: controller,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'XXXX-XXXX-XXXX-XXXX',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'License key is required';
                        }
                        return null;
                      },
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMsg!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.white24),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isLoading = true;
                              errorMsg = null;
                            });

                            final success = await ref
                                .read(licenseStateProvider.notifier)
                                .activate(controller.text);

                            if (success) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'License renewed successfully!',
                                    ),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                              }
                            } else {
                              setState(() {
                                isLoading = false;
                                errorMsg =
                                    ref
                                        .read(licenseStateProvider)
                                        .errorMessage ??
                                    'Activation failed';
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ACTIVATE',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
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
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restore successful! Restarting app...'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          await restartAppWithNewDatabase(context);
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

  Widget _buildQuickActionsDock(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.01),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DockActionItem(
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
          ),
          _buildDockSeparator(),
          Expanded(
            child: _DockActionItem(
              label: 'Receive Stock',
              icon: Icons.add_business_rounded,
              color: const Color(0xFF10B981),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailyReceiveScreen()),
              ),
            ),
          ),
          _buildDockSeparator(),
          Expanded(
            child: _DockActionItem(
              label: 'New Requisition',
              icon: Icons.assignment_rounded,
              color: const Color(0xFF6366F1),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequisitionScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockSeparator() {
    return Container(
      height: 36,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withValues(alpha: 0.08),
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

class _DockActionItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DockActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DockActionItem> createState() => _DockActionItemState();
}

class _DockActionItemState extends State<_DockActionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                transform: Matrix4.identity()
                  ..translate(0.0, _isHovered ? -4.0 : 0.0)
                  ..scale(_isHovered ? 1.1 : 1.0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withValues(alpha: 0.2),
                      widget.color.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(
                        alpha: _isHovered ? 0.3 : 0.1,
                      ),
                      blurRadius: _isHovered ? 12 : 6,
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isHovered ? Colors.white : Colors.white60,
                  fontSize: 11,
                  fontWeight: _isHovered ? FontWeight.bold : FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
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
