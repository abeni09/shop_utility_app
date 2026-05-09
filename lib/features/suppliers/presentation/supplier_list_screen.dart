import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/suppliers/data/supplier_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_repository.dart';
import 'package:shopsync/main.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SupplierRepository(dbService.isar);
});

final suppliersProvider = StreamProvider<List<Supplier>>((ref) {
  final repository = ref.watch(supplierRepositoryProvider);
  return repository.watchSuppliers();
});

class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);

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
              title: const Text('SUPPLIERS'),
              actions: [
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
                    onPressed: () => _showAddSupplierDialog(context, ref),
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
                        delegate: SliverChildBuilderDelegate((context, index) {
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
    );
  }

  void _showAddSupplierDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final contactController = TextEditingController();

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
            const Text(
              'NEW SUPPLIER',
              style: TextStyle(
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
              'Contact Info',
              Icons.contact_page_rounded,
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
                  final supplier = Supplier()
                    ..name = nameController.text
                    ..contact = contactController.text;
                  await ref
                      .read(supplierRepositoryProvider)
                      .saveSupplier(supplier);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'SAVE SUPPLIER',
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
}

class _SupplierCard extends ConsumerWidget {
  final Supplier supplier;
  const _SupplierCard({required this.supplier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBalance = supplier.balance > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: Color(0xFF818CF8),
          ),
        ),
        title: Text(
          supplier.name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        subtitle: Text(
          supplier.contact ?? 'No contact',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
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
              '${supplier.balance.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: hasBalance ? Colors.redAccent : Colors.greenAccent,
              ),
            ),
          ],
        ),
        onTap: () => _showSettlementDialog(context, ref, supplier),
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
                  final amount = double.tryParse(amountController.text) ?? 0.0;
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
