import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/suppliers/data/supplier_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_repository.dart';
import 'package:shopsync/main.dart';
import 'package:shopsync/features/dashboard/presentation/ui_providers.dart';
import 'package:url_launcher/url_launcher.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final backupService = ref.watch(backupServiceProvider);
  return SupplierRepository(dbService.isar, backupService);
});

final suppliersProvider = StreamProvider<List<Supplier>>((ref) {
  final repository = ref.watch(supplierRepositoryProvider);
  final showArchived = ref.watch(showArchivedSuppliersProvider);
  return repository.watchSuppliers(includeVoided: showArchived);
});

class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final showArchived = ref.watch(showArchivedSuppliersProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF020617)],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(backupServiceProvider).forceSyncCheck();
          ref.invalidate(cloudSyncStatusProvider);
          ref.invalidate(localAheadProvider);
        },
        backgroundColor: const Color(0xFF1E293B),
        color: const Color(0xFF818CF8),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar.large(
                backgroundColor: Colors.transparent,
                title: const Text('SUPPLIERS'),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: showArchived
                          ? const Color(0xFF818CF8).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        showArchived
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: showArchived
                            ? const Color(0xFF818CF8)
                            : Colors.white24,
                      ),
                      onPressed: () =>
                          ref
                                  .read(showArchivedSuppliersProvider.notifier)
                                  .state =
                              !showArchived,
                      tooltip: 'Show Voided Suppliers',
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.person_add_rounded,
                        color: Color(0xFF818CF8),
                      ),
                      onPressed: () => _showSupplierDialog(context, ref),
                    ),
                  ),
                ],
              ),
              suppliersAsync.when(
                data: (suppliers) => suppliers.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No suppliers found',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final supplier = suppliers[index];
                            return _SupplierCard(supplier: supplier);
                          }, childCount: suppliers.length),
                        ),
                      ),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

void _showSupplierDialog(
  BuildContext context,
  WidgetRef ref, [
  Supplier? existing,
]) {
  final nameController = TextEditingController(text: existing?.name);
  final contactController = TextEditingController(text: existing?.contact);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existing == null ? 'NEW SUPPLIER' : 'EDIT SUPPLIER',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 14,
                color: Colors.indigoAccent,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              nameController,
              'Supplier Name',
              Icons.person_rounded,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              contactController,
              'Phone Number',
              Icons.phone_rounded,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter supplier name'),
                      ),
                    );
                    return;
                  }
                  if (contactController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter phone number'),
                      ),
                    );
                    return;
                  }

                  final supplier = existing ?? Supplier();
                  supplier.name = nameController.text.trim();
                  supplier.contact = contactController.text.trim();

                  await ref
                      .read(supplierRepositoryProvider)
                      .saveSupplier(supplier);

                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(
                  existing == null ? 'SAVE SUPPLIER' : 'UPDATE SUPPLIER',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

Widget _buildTextField(
  TextEditingController controller,
  String label,
  IconData icon,
) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(fontSize: 14, color: Colors.white38),
    ),
  );
}

class _SupplierCard extends ConsumerWidget {
  final Supplier supplier;
  const _SupplierCard({required this.supplier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBalance = supplier.balance > 0;
    final isActive = supplier.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.02),
        ),
      ),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.5,
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isActive
                      ? Icons.local_shipping_rounded
                      : Icons.pause_circle_filled_rounded,
                  color: isActive ? const Color(0xFF818CF8) : Colors.white24,
                ),
              ),
              title: Text(
                supplier.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              subtitle: Row(
                children: [
                  Text(
                    supplier.contact ?? 'No contact',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'BALANCE',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white24,
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    supplier.balance.toStringAsFixed(0),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: hasBalance ? Colors.redAccent : Colors.greenAccent,
                    ),
                  ),
                ],
              ),
              onTap: isActive
                  ? () => _showSettlementDialog(context, ref, supplier)
                  : null,
            ),
            Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.05),
              indent: 20,
              endIndent: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: isActive,
                          onChanged: (val) async {
                            final updated = Supplier()
                              ..id = supplier.id
                              ..name = supplier.name
                              ..contact = supplier.contact
                              ..balance = supplier.balance
                              ..isActive = val;
                            await ref
                                .read(supplierRepositoryProvider)
                                .saveSupplier(updated);
                          },
                          activeColor: const Color(0xFF818CF8),
                        ),
                      ),
                      Text(
                        isActive ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: isActive
                              ? const Color(0xFF818CF8)
                              : Colors.white24,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: Colors.white12,
                    ),
                    onPressed: () =>
                        _showSupplierDialog(context, ref, supplier),
                  ),
                  IconButton(
                    icon: Icon(
                      supplier.isVoid
                          ? Icons.restore_rounded
                          : Icons.delete_outline_rounded,
                      size: 20,
                      color: supplier.isVoid
                          ? Colors.greenAccent
                          : Colors.white12,
                    ),
                    onPressed: () => supplier.isVoid
                        ? _showRestoreDialog(context, ref, supplier)
                        : _showVoidDialog(context, ref, supplier),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestoreDialog(BuildContext context, WidgetRef ref, Supplier s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'RESTORE SUPPLIER?',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        content: Text(
          'Do you want to bring "${s.name.replaceFirst('[VOID] ', '')}" back to your active list?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(supplierRepositoryProvider).unvoidSupplier(s.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'RESTORE',
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showVoidDialog(BuildContext context, WidgetRef ref, Supplier s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'VOID SUPPLIER?',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        content: const Text(
          'This will hide the supplier from your daily view. You can restore them later by toggling "Show Archived" in the top menu.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(supplierRepositoryProvider).voidSupplier(s.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'VOID',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettlementDialog(
    BuildContext context,
    WidgetRef ref,
    Supplier supplier,
  ) {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SETTLE: ${supplier.name.toUpperCase()}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 14,
                color: Colors.indigoAccent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Current Debt: ${supplier.balance.toStringAsFixed(2)} ETB',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Payment Amount',
                prefixText: 'ETB ',
                prefixIcon: const Icon(Icons.payments_rounded, size: 20),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter valid amount'),
                      ),
                    );
                    return;
                  }
                  await ref
                      .read(supplierRepositoryProvider)
                      .updateBalance(supplier.id, -amount);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'RECORD PAYMENT',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
