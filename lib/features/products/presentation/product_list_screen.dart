import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProductDialog(context, ref),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(product.name),
                subtitle: Text('Cost: ${product.costPrice} | Sale: ${product.sellingPrice}'),
                trailing: Text(product.unit),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final unitController = TextEditingController(text: 'piece');
    final costController = TextEditingController();
    final saleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit')),
            TextField(controller: costController, decoration: const InputDecoration(labelText: 'Cost Price'), keyboardType: TextInputType.number),
            TextField(controller: saleController, decoration: const InputDecoration(labelText: 'Selling Price'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final product = Product()
                ..name = nameController.text
                ..unit = unitController.text
                ..costPrice = double.tryParse(costController.text) ?? 0.0
                ..sellingPrice = double.tryParse(saleController.text) ?? 0.0
                ..lastUpdated = DateTime.now();
              
              await ref.read(productRepositoryProvider).saveProduct(product);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
