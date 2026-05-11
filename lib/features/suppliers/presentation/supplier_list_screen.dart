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
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              await ref.read(backupServiceProvider).forceSyncCheck();
              ref.invalidate(cloudSyncStatusProvider);
              ref.invalidate(localAheadProvider);
            },
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            color: Theme.of(context).colorScheme.primary,
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
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2)
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            showArchived
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: showArchived
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                          ),
                          onPressed: () =>
                              ref
                                      .read(
                                        showArchivedSuppliersProvider.notifier,
                                      )
                                      .state =
                                  !showArchived,
                          tooltip: 'Show Voided Suppliers',
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.person_add_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => _showSupplierDialog(context, ref),
                        ),
                      ),
                    ],
                  ),

                  suppliersAsync.when(
                    data: (suppliers) {
                      final width = MediaQuery.of(context).size.width;
                      final horizontalPadding = width > 1200
                          ? width * 0.1
                          : (width > 800 ? 48.0 : 24.0);
                      final crossAxisCount = width > 1000
                          ? 3
                          : (width > 600 ? 2 : 1);

                      return suppliers.isEmpty
                          ? const SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  'No suppliers found',
                                  style: TextStyle(color: Colors.white38),
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              sliver: crossAxisCount > 1
                                  ? SliverGrid(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            mainAxisSpacing: 16,
                                            crossAxisSpacing: 16,
                                            mainAxisExtent: 240,
                                          ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) => _SupplierCard(
                                          supplier: suppliers[index],
                                        ),
                                        childCount: suppliers.length,
                                      ),
                                    )
                                  : SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: _SupplierCard(
                                            supplier: suppliers[index],
                                          ),
                                        ),
                                        childCount: suppliers.length,
                                      ),
                                    ),
                            );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6366F1),
                        ),
                      ),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          ),
        ],
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
    backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.98),
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
                letterSpacing: 2.5,
                fontSize: 14,
                color: Color(0xFF818CF8),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              nameController,
              'Supplier Name',
              Icons.person_rounded,
              context,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              contactController,
              'Phone Number',
              Icons.phone_rounded,
              context,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
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
  BuildContext context,
) {
  return TextField(
    controller: controller,
    style: const TextStyle(fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF818CF8), size: 20),
      labelStyle: const TextStyle(
        color: Colors.white38,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
      ),
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          if (hasBalance && isActive)
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.05),
              blurRadius: 30,
              spreadRadius: 5,
            ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isActive
                ? () => _showSettlementDialog(context, ref, supplier)
                : null,
            child: Opacity(
              opacity: isActive ? 1.0 : 0.6,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color:
                                (isActive
                                        ? const Color(0xFF6366F1)
                                        : Colors.white10)
                                    .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  (isActive
                                          ? const Color(0xFF6366F1)
                                          : Colors.white10)
                                      .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            isActive
                                ? Icons.local_shipping_rounded
                                : Icons.pause_circle_rounded,
                            color: isActive
                                ? const Color(0xFF818CF8)
                                : Colors.white24,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supplier.name.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    supplier.contact ?? 'No contact',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (supplier.contact != null &&
                                      supplier.contact!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        final Uri launchUri = Uri(
                                          scheme: 'tel',
                                          path: supplier.contact,
                                        );
                                        if (await canLaunchUrl(launchUri))
                                          await launchUrl(launchUri);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF818CF8,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.phone_in_talk_rounded,
                                          size: 14,
                                          color: Color(0xFF818CF8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Quick actions
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                color: Colors.white30,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                onPressed: () =>
                                    _showSupplierDialog(context, ref, supplier),
                              ),
                              IconButton(
                                icon: Icon(
                                  supplier.isVoid
                                      ? Icons.restore_rounded
                                      : Icons.delete_sweep_rounded,
                                  size: 16,
                                ),
                                color: supplier.isVoid
                                    ? Colors.greenAccent
                                    : Colors.redAccent.withValues(alpha: 0.3),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                onPressed: () => supplier.isVoid
                                    ? _showRestoreSupplierDialog(
                                        context,
                                        ref,
                                        supplier,
                                      )
                                    : _showVoidSupplierDialog(
                                        context,
                                        ref,
                                        supplier,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status Toggle
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                                  activeThumbColor: const Color(0xFF818CF8),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  isActive ? 'ACTIVE' : 'PAUSED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: isActive
                                        ? const Color(0xFF818CF8)
                                        : Colors.white24,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Balance Display
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (hasBalance
                                          ? Colors.redAccent
                                          : Colors.greenAccent)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    (hasBalance
                                            ? Colors.redAccent
                                            : Colors.greenAccent)
                                        .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'BALANCE:',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color:
                                        (hasBalance
                                                ? Colors.redAccent
                                                : Colors.greenAccent)
                                            .withValues(alpha: 0.5),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${supplier.balance.toStringAsFixed(0)} ETB',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: hasBalance
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRestoreSupplierDialog(
    BuildContext context,
    WidgetRef ref,
    Supplier s,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        title: const Text(
          'RESTORE SUPPLIER?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
            color: Colors.greenAccent,
          ),
        ),
        content: Text(
          'Do you want to bring "${s.name.replaceFirst('[VOID] ', '')}" back to your active list?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.white24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(supplierRepositoryProvider).unvoidSupplier(s.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'RESTORE',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVoidSupplierDialog(
    BuildContext context,
    WidgetRef ref,
    Supplier s,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        title: const Text(
          'VOID SUPPLIER?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
            color: Color(0xFFEF4444),
          ),
        ),
        content: const Text(
          'This will hide the supplier from your daily view. You can restore them later by toggling "Show Archived" in the top menu.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.white24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(supplierRepositoryProvider).voidSupplier(s.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'VOID',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w900,
              ),
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
      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.98),
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'SETTLE: ${supplier.name.toUpperCase()}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                fontSize: 14,
                color: Color(0xFF818CF8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Current Debt:',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${supplier.balance.toStringAsFixed(0)} ETB',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (supplier.balance != 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      amountController.text = supplier.balance.toStringAsFixed(
                        0,
                      );
                    },
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: const Text('SETTLE FULL BALANCE'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Payment Amount',
                prefixText: 'ETB ',
                prefixIcon: const Icon(
                  Icons.payments_rounded,
                  color: Color(0xFF818CF8),
                  size: 20,
                ),
                labelStyle: const TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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

                  if (amount > supplier.balance + 0.01) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Amount exceeds current balance'),
                      ),
                    );
                    return;
                  }

                  await ref
                      .read(supplierRepositoryProvider)
                      .updateBalance(supplier.id, -amount);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Payment of ${amount.toStringAsFixed(0)} ETB recorded',
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded),
                    SizedBox(width: 12),
                    Text(
                      'CONFIRM PAYMENT',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
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
