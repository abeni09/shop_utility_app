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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddSupplierDialog(context, ref),
          ),
        ],
      ),
      body: suppliersAsync.when(
        data: (suppliers) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: suppliers.length,
          itemBuilder: (context, index) {
            final supplier = suppliers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(supplier.contact ?? 'No contact info'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Balance', style: TextStyle(fontSize: 10)),
                    Text(
                      '${supplier.balance.toStringAsFixed(2)} ETB',
                      style: TextStyle(
                        color: supplier.balance > 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showSettlementDialog(context, ref, supplier),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final contactController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Supplier Name')),
            TextField(controller: contactController, decoration: const InputDecoration(labelText: 'Contact (Phone/Link)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final supplier = Supplier()
                ..name = nameController.text
                ..contact = contactController.text;
              await ref.read(supplierRepositoryProvider).saveSupplier(supplier);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSettlementDialog(BuildContext context, WidgetRef ref, Supplier supplier) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settle with ${supplier.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Balance: ${supplier.balance.toStringAsFixed(2)} ETB'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Payment Amount', prefixText: 'ETB '),
              keyboardType: TextInputType.number,
            ),
            const Text('Entering a positive amount will REDUCE the balance you owe.', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              await ref.read(supplierRepositoryProvider).updateBalance(supplier.id, -amount);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }
}
