import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/main.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_model.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_settlement_model.dart';

class SyncManagerDialog extends ConsumerStatefulWidget {
  const SyncManagerDialog({super.key});

  @override
  ConsumerState<SyncManagerDialog> createState() => _SyncManagerDialogState();
}

class _SyncManagerDialogState extends ConsumerState<SyncManagerDialog> {
  bool _isLoading = false;
  String? _statusMessage;
  double _dbSizeKb = 0.0;
  int _productCount = 0;
  int _supplierCount = 0;
  int _orderCount = 0;
  int _settlementCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File('${dir.path}/shopsync_db.isar');
      double size = 0.0;
      if (await dbFile.exists()) {
        size = (await dbFile.length()) / 1024.0;
      }

      final isar = ref.read(databaseServiceProvider).isar;
      final products = await isar.products.count();
      final suppliers = await isar.suppliers.count();
      final orders = await isar.customerOrders.count();
      final settlements = await isar.supplierSettlements.count();

      if (mounted) {
        setState(() {
          _dbSizeKb = size;
          _productCount = products;
          _supplierCount = suppliers;
          _orderCount = orders;
          _settlementCount = settlements;
        });
      }
    } catch (e) {
      debugPrint('Error loading db stats: $e');
    }
  }

  Future<void> _handleUpload() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Uploading database to Google Drive...';
    });
    try {
      await ref.read(backupServiceProvider).uploadBackup(forceSignIn: true);
      ref.invalidate(cloudSyncStatusProvider);
      ref.invalidate(localAheadProvider);
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database backup uploaded successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
      }
    }
  }

  Future<void> _handleDownload() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text(
              'OVERWRITE DATABASE?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.5,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        content: const Text(
          'This will completely replace all your local inventory, orders, sales, and supplier data with the latest cloud backup. TThis action cannot be undone.',
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'OVERWRITE',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Restoring database from Google Drive...';
    });
    try {
      await ref.read(backupServiceProvider).restoreLatestBackup();
      // Reset providers that cache DB streams or statistics
      ref.invalidate(cloudSyncStatusProvider);
      ref.invalidate(localAheadProvider);
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Database restored successfully! Restart app if changes don\'t display immediately.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(backupUserProvider);
    final cloudNewerAsync = ref.watch(cloudSyncStatusProvider);
    final localAheadAsync = ref.watch(localAheadProvider);

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? _buildLoadingState()
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildAccountSection(userAsync),
                      const SizedBox(height: 20),
                      _buildStatusSection(
                        cloudNewerAsync,
                        localAheadAsync,
                        userAsync,
                      ),
                      const SizedBox(height: 20),
                      _buildStatsSection(),
                      const SizedBox(height: 24),
                      _buildActionsSection(userAsync),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF6366F1),
            strokeWidth: 4,
          ),
          const SizedBox(height: 24),
          Text(
            _statusMessage ?? 'Processing...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.cloud_sync_rounded,
            color: Color(0xFF818CF8),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SYNC MANAGER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                'Cloud Backup & Resolution',
                style: TextStyle(color: Colors.white30, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white30),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildAccountSection(AsyncValue<GoogleSignInAccount?> userAsync) {
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  color: Colors.white30,
                  size: 28,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cloud Sync Status',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Not signed in',
                        style: TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => ref.read(backupServiceProvider).signIn(),
                  child: const Text(
                    'SIGN IN',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF818CF8),
                child: Text(
                  user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'Google User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white30,
                  size: 18,
                ),
                tooltip: 'Sign Out',
                onPressed: () async {
                  await ref.read(backupServiceProvider).signOut();
                  ref.invalidate(cloudSyncStatusProvider);
                  ref.invalidate(localAheadProvider);
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatusSection(
    AsyncValue<bool> cloudNewerAsync,
    AsyncValue<bool> localAheadAsync,
    AsyncValue<GoogleSignInAccount?> userAsync,
  ) {
    if (userAsync.value == null) {
      return const SizedBox.shrink();
    }

    return cloudNewerAsync.when(
      data: (isCloudNewer) => localAheadAsync.when(
        data: (isLocalAhead) {
          String statusText = 'Database is synchronized';
          IconData statusIcon = Icons.check_circle_outline_rounded;
          Color statusColor = const Color(0xFF10B981);
          String statusDetail = 'Local data matches Google Drive backup.';

          if (isCloudNewer) {
            statusText = 'Cloud Update Available';
            statusIcon = Icons.cloud_download_outlined;
            statusColor = const Color(0xFFF59E0B);
            statusDetail =
                'There is a newer backup on Google Drive. Pull changes to restore.';
          } else if (isLocalAhead) {
            statusText = 'Local Changes Pending';
            statusIcon = Icons.cloud_upload_outlined;
            statusColor = const Color(0xFF818CF8);
            statusDetail =
                'Local modifications are newer than Drive backup. Push to backup.';
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusDetail,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DATABASE METRICS',
            style: TextStyle(
              color: Color(0xFF818CF8),
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'Database File Size',
            '${_dbSizeKb.toStringAsFixed(1)} KB',
            Icons.storage_rounded,
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildStatRow(
            'Products Count',
            '$_productCount items',
            Icons.inventory_2_outlined,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'Suppliers Count',
            '$_supplierCount contacts',
            Icons.people_outline,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'Orders & Sales',
            '$_orderCount logs',
            Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'Settlements',
            '$_settlementCount records',
            Icons.payment_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white30, size: 16),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(AsyncValue<GoogleSignInAccount?> userAsync) {
    if (userAsync.value == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => ref.read(backupServiceProvider).signIn(),
          icon: const Icon(Icons.login_rounded),
          label: const Text(
            'SIGN IN TO GOOGLE DRIVE',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF818CF8),
                  side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _handleUpload,
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: const Text(
                  'FORCE PUSH',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _handleDownload,
                icon: const Icon(Icons.cloud_download_rounded, size: 18),
                label: const Text(
                  'FORCE PULL',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white30,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                await ref.read(backupServiceProvider).forceSyncCheck();
                ref.invalidate(cloudSyncStatusProvider);
                ref.invalidate(localAheadProvider);
                await _loadStats();
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'REFRESH SYNC STATUS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
