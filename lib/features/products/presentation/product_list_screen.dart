import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/features/suppliers/presentation/supplier_list_screen.dart';

import 'package:shopsync/features/dashboard/presentation/ui_providers.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final showVoided = ref.watch(showVoidedProductsProvider);

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
                title: const Text('INVENTORY'),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: showVoided
                          ? const Color(0xFF818CF8).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        showVoided
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: showVoided
                            ? const Color(0xFF818CF8)
                            : Colors.white24,
                      ),
                      onPressed: () => ref
                          .read(showVoidedProductsProvider.notifier)
                          .state = !showVoided,
                      tooltip: 'Show Voided Products',
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
                        Icons.add_rounded,
                        color: Color(0xFF818CF8),
                      ),
                      onPressed: () => _showProductDialog(context, ref),
                    ),
                  ),
                ],
              ),
              productsAsync.when(
                data: (products) => products.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No products found',
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
                            final product = products[index];
                            return _ProductCard(product: product);
                          }, childCount: products.length),
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

  void _onAddProduct(BuildContext context, WidgetRef ref) {
    _showProductDialog(context, ref);
  }
}

void _showProductDialog(
  BuildContext context,
  WidgetRef ref, [
  Product? existing,
]) {
  final nameController = TextEditingController(text: existing?.name);
  final costController =
      TextEditingController(text: existing?.costPrice.toStringAsFixed(0));
  final saleController =
      TextEditingController(text: existing?.sellingPrice.toStringAsFixed(0));
  int? selectedSupplierId = existing?.supplierId;
  final suppliers = ref.read(suppliersProvider).value ?? [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
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
              existing == null ? 'NEW PRODUCT' : 'EDIT PRODUCT',
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
              'Product Name',
              Icons.inventory_2_rounded,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    costController,
                    'Cost Price',
                    Icons.south_rounded,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    saleController,
                    'Selling Price',
                    Icons.sell_rounded,
                    isNumber: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'SUPPLIER (OPTIONAL)',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 10,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: selectedSupplierId,
              dropdownColor: const Color(0xFF1E293B),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('No Supplier')),
                ...suppliers.map(
                  (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                ),
              ],
              onChanged: (val) => setState(() => selectedSupplierId = val),
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
                      const SnackBar(content: Text('Please enter product name')),
                    );
                    return;
                  }
                  final cost = double.tryParse(costController.text);
                  final sale = double.tryParse(saleController.text);
                  
                  if (cost == null || cost < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter valid cost price')),
                    );
                    return;
                  }
                  if (sale == null || sale < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter valid sale price')),
                    );
                    return;
                  }

                  final product = existing ?? Product();
                  product.name = nameController.text.trim();
                  product.costPrice = cost;
                  product.sellingPrice = sale;
                  product.supplierId = selectedSupplierId;

                  await ref
                      .read(productRepositoryProvider)
                      .saveProduct(product);

                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(
                  existing == null ? 'SAVE PRODUCT' : 'UPDATE PRODUCT',
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
  IconData icon, {
  bool isNumber = false,
}) {
  return TextField(
    controller: controller,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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

class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVoid = product.isVoid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isVoid
            ? Colors.white.withValues(alpha: 0.01)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isVoid
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Opacity(
        opacity: isVoid ? 0.5 : 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isVoid ? Icons.auto_delete_rounded : Icons.inventory_2_rounded,
                color: isVoid ? Colors.white24 : const Color(0xFF818CF8),
              ),
            ),
            title: Text(
              product.name + (isVoid ? ' [VOID]' : ''),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  _buildPriceTag('COST', product.costPrice, Colors.redAccent),
                  const SizedBox(width: 12),
                  _buildPriceTag(
                    'SALE',
                    product.sellingPrice,
                    Colors.greenAccent,
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isVoid)
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white12,
                      size: 20,
                    ),
                    onPressed: () => _showProductDialog(context, ref, product),
                  ),
                IconButton(
                  icon: Icon(
                    isVoid ? Icons.restore_rounded : Icons.delete_sweep_rounded,
                    color: isVoid ? Colors.greenAccent : Colors.white12,
                    size: 20,
                  ),
                  onPressed: () => isVoid
                      ? _showRestoreProductDialog(context, ref, product)
                      : _showVoidProductDialog(context, ref, product),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRestoreProductDialog(BuildContext context, WidgetRef ref, Product p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'RESTORE PRODUCT?',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        content: Text(
          'Do you want to bring "${p.name}" back to your active inventory?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(productRepositoryProvider).unvoidProduct(p.id);
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

  void _showVoidProductDialog(BuildContext context, WidgetRef ref, Product p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'VOID PRODUCT?',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        content: const Text(
          'This will hide the product from your sales list. Past orders will NOT be affected.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(productRepositoryProvider).voidProduct(p.id);
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

  Widget _buildPriceTag(String label, double price, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              color: color.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            price.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
