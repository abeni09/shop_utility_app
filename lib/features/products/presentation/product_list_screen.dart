import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/features/products/data/stock_adjustment_model.dart';
import 'package:shopsync/features/suppliers/presentation/supplier_list_screen.dart';

import 'package:shopsync/features/dashboard/presentation/ui_providers.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(sortedProductsProvider);
    final showVoided = ref.watch(showVoidedProductsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
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
              resizeToAvoidBottomInset: false,
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
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.sort_rounded,
                            color: Color(0xFF6366F1),
                          ),
                          onPressed: () => _showSortOptions(context, ref),
                          tooltip: 'Sort Products',
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: showVoided
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
                            showVoided
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: showVoided
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                          ),
                          onPressed: () =>
                              ref
                                      .read(showVoidedProductsProvider.notifier)
                                      .state =
                                  !showVoided,
                          tooltip: 'Show Voided Products',
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
                            Icons.add_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => _showProductDialog(context, ref),
                        ),
                      ),
                    ],
                  ),

                  productsAsync.when(
                    data: (products) {
                      final width = MediaQuery.of(context).size.width;
                      final horizontalPadding = width > 1200
                          ? width * 0.1
                          : (width > 800 ? 48.0 : 24.0);
                      final crossAxisCount = width > 1000
                          ? 3
                          : (width > 600 ? 2 : 1);

                      final filtered = products
                          .where((p) => showVoided ? true : !p.isVoid)
                          .toList();

                      return filtered.isEmpty
                          ? const SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  'No products found',
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
                                            mainAxisExtent: 180,
                                          ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) => _ProductCard(
                                          product: filtered[index],
                                        ),
                                        childCount: filtered.length,
                                      ),
                                    )
                                  : SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: _ProductCard(
                                            product: filtered[index],
                                          ),
                                        ),
                                        childCount: filtered.length,
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

  void _showSortOptions(BuildContext context, WidgetRef ref) {
    final currentSort = ref.read(productSortTypeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'SORT PRODUCTS BY',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 2.0,
                    color: Color(0xFF818CF8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _sortTile(context, ref, 'Recently Added', ProductSortType.newest, currentSort),
              _sortTile(context, ref, 'Oldest First', ProductSortType.oldest, currentSort),
              _sortTile(context, ref, 'Name (A - Z)', ProductSortType.nameAsc, currentSort),
              _sortTile(context, ref, 'Name (Z - A)', ProductSortType.nameDesc, currentSort),
              _sortTile(context, ref, 'Price (Low to High)', ProductSortType.priceAsc, currentSort),
              _sortTile(context, ref, 'Price (High to Low)', ProductSortType.priceDesc, currentSort),
            ],
          ),
        );
      },
    );
  }

  Widget _sortTile(
    BuildContext context,
    WidgetRef ref,
    String title,
    ProductSortType type,
    ProductSortType current,
  ) {
    final isSelected = type == current;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF818CF8) : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF818CF8))
          : null,
      onTap: () {
        ref.read(productSortTypeProvider.notifier).state = type;
        Navigator.pop(context);
      },
    );
  }
}

void _showProductDialog(
  BuildContext context,
  WidgetRef ref, [
  Product? existing,
]) {
  final nameController = TextEditingController(text: existing?.name);
  final costController = TextEditingController(
    text: existing?.costPrice.toStringAsFixed(0),
  );
  final saleController = TextEditingController(
    text: existing?.sellingPrice.toStringAsFixed(0),
  );
  int? selectedSupplierId = existing?.supplierId;
  var suppliers = ref.read(suppliersProvider).value ?? [];
  // Only show active and non-void suppliers
  suppliers = suppliers.where((s) => s.isActive && !s.isVoid).toList();
  // Ensure the existing supplier is in the list even if inactive
  if (existing?.supplierId != null) {
    final existingSupplier = (ref.read(suppliersProvider).value ?? [])
        .where((s) => s.id == existing!.supplierId)
        .firstOrNull;
    if (existingSupplier != null &&
        !suppliers.any((s) => s.id == existingSupplier.id)) {
      suppliers.add(existingSupplier);
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.98),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'NEW PRODUCT' : 'EDIT PRODUCT',
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
                'Product Name',
                Icons.inventory_2_rounded,
                context,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      costController,
                      'Cost Price',
                      Icons.south_rounded,
                      context,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      saleController,
                      'Selling Price',
                      Icons.sell_rounded,
                      context,
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
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No Supplier'),
                  ),
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
                          content: Text('Please enter product name'),
                        ),
                      );
                      return;
                    }
                    final cost = double.tryParse(costController.text);
                    final sale = double.tryParse(saleController.text);

                    if (cost == null || cost < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter valid cost price'),
                        ),
                      );
                      return;
                    }
                    if (sale == null || sale < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter valid sale price'),
                        ),
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
    ),
  );
}

Widget _buildTextField(
  TextEditingController controller,
  String label,
  IconData icon,
  BuildContext context, {
  bool isNumber = false,
}) {
  return TextField(
    controller: controller,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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

class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVoid = product.isVoid;
    final stockAsync = ref.watch(walkInAvailabilityProvider(DateTime.now()));

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
          if (!isVoid)
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: -10,
            ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Decorative background icon
            Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  isVoid
                      ? Icons.auto_delete_rounded
                      : Icons.inventory_2_rounded,
                  size: 150,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color:
                              (isVoid ? Colors.grey : const Color(0xFF6366F1))
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                (isVoid ? Colors.grey : const Color(0xFF6366F1))
                                    .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          isVoid
                              ? Icons.auto_delete_rounded
                              : Icons.inventory_2_rounded,
                          color: isVoid
                              ? Colors.white38
                              : const Color(0xFF818CF8),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1,
                                color: isVoid ? Colors.white38 : Colors.white,
                              ),
                            ),
                            if (isVoid)
                              const Text(
                                'ARCHIVED / VOID',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Quick actions strip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isVoid)
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                color: Colors.white38,
                                onPressed: () =>
                                    _showProductDialog(context, ref, product),
                              ),
                            if (!isVoid)
                              IconButton(
                                icon: const Icon(Icons.tune_rounded, size: 18),
                                color: const Color(0xFF818CF8),
                                onPressed: () => _showAdjustmentDialog(
                                  context,
                                  ref,
                                  product,
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                isVoid
                                    ? Icons.restore_rounded
                                    : Icons.delete_sweep_rounded,
                                size: 18,
                              ),
                              color: isVoid
                                  ? Colors.greenAccent
                                  : Colors.redAccent.withValues(alpha: 0.5),
                              onPressed: () => isVoid
                                  ? _showRestoreProductDialog(
                                      context,
                                      ref,
                                      product,
                                    )
                                  : _showVoidProductDialog(
                                      context,
                                      ref,
                                      product,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Flexible(
                        child: _buildModernPriceTag(
                          context,
                          'COST',
                          'ETB ${product.costPrice.toStringAsFixed(0)}',
                          Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _buildModernPriceTag(
                          context,
                          'SALE',
                          'ETB ${product.sellingPrice.toStringAsFixed(0)}',
                          Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      stockAsync.when(
                        data: (avail) {
                          final status = avail[product.id];
                          final remaining = status?.physicalRemaining ?? 0.0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: remaining > 0
                                    ? [
                                        const Color(0xFF6366F1),
                                        const Color(0xFF818CF8),
                                      ]
                                    : [
                                        const Color(0xFFF43F5E),
                                        const Color(0xFFFB7185),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (remaining > 0
                                              ? const Color(0xFF6366F1)
                                              : const Color(0xFFF43F5E))
                                          .withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.analytics_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${remaining.toStringAsFixed(1)} IN STOCK',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (_, _) => const SizedBox(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPriceTag(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white24,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  void _showRestoreProductDialog(
    BuildContext context,
    WidgetRef ref,
    Product p,
  ) {
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

  void _showAdjustmentDialog(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) {
    final amountController = TextEditingController();
    String reason = 'damage';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                'ADJUST STOCK: ${product.name.toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 14,
                  color: Color(0xFF818CF8),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Adjustment Amount',
                  helperText: 'Use negative for losses (damage, consumption)',
                  prefixIcon: const Icon(Icons.add_chart_rounded),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'REASON',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white24,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['damage', 'self-consumption', 'correction', 'other']
                    .map(
                      (r) => ChoiceChip(
                        label: Text(r),
                        selected: reason == r,
                        onSelected: (val) {
                          if (val) setModalState(() => reason = r);
                        },
                        selectedColor: const Color(0xFF6366F1),
                        labelStyle: TextStyle(
                          color: reason == r ? Colors.white : Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount == 0) return;

                    final adj = StockAdjustment()
                      ..productId = product.id
                      ..amount = amount
                      ..reason = reason
                      ..date = DateTime.now();

                    await ref
                        .read(stockAdjustmentRepositoryProvider)
                        .saveAdjustment(adj);

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('SAVE ADJUSTMENT'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
