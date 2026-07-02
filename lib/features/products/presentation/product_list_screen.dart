import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/features/products/data/stock_adjustment_model.dart';
import 'package:shopsync/features/suppliers/presentation/supplier_list_screen.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/products/data/holiday_model.dart';
import 'package:shopsync/features/products/presentation/holiday_providers.dart';

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
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF10B981),
                          ),
                          onPressed: () =>
                              _showSafetyStockRecommender(context, ref),
                          tooltip: 'Smart Safety Stock Recommender',
                        ),
                      ),
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
                            Icons.calendar_month_rounded,
                            color: Colors.orangeAccent,
                          ),
                          onPressed: () => _showHolidayManager(context, ref),
                          tooltip: 'Manage Holidays',
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
              _sortTile(
                context,
                ref,
                'Recently Added',
                ProductSortType.newest,
                currentSort,
              ),
              _sortTile(
                context,
                ref,
                'Oldest First',
                ProductSortType.oldest,
                currentSort,
              ),
              _sortTile(
                context,
                ref,
                'Name (A - Z)',
                ProductSortType.nameAsc,
                currentSort,
              ),
              _sortTile(
                context,
                ref,
                'Name (Z - A)',
                ProductSortType.nameDesc,
                currentSort,
              ),
              _sortTile(
                context,
                ref,
                'Price (Low to High)',
                ProductSortType.priceAsc,
                currentSort,
              ),
              _sortTile(
                context,
                ref,
                'Price (High to Low)',
                ProductSortType.priceDesc,
                currentSort,
              ),
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

void _showSafetyStockRecommender(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.98),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => _SafetyStockRecommenderBody(ref: ref),
  );
}

void _showProductDialog(
  BuildContext context,
  WidgetRef ref, [
  Product? existing,
]) {
  String? selectedImagePath = existing?.imagePath;
  final nameController = TextEditingController(text: existing?.name);
  final costController = TextEditingController(
    text: existing?.costPrice.toStringAsFixed(0),
  );
  final saleController = TextEditingController(
    text: existing?.sellingPrice.toStringAsFixed(0),
  );
  final minStockController = TextEditingController(
    text: (existing?.minStockThreshold ?? 5).toString(),
  );
  final shelfLifeController = TextEditingController(
    text: (existing?.shelfLifeDays ?? 30).toString(),
  );
  bool hasQuota = existing?.hasQuota ?? false;
  final weekdayQuotaController = TextEditingController(
    text: existing?.weekdayQuota?.toString() ?? '',
  );
  final weekendQuotaController = TextEditingController(
    text: existing?.weekendQuota?.toString() ?? '',
  );
  final holidayQuotaController = TextEditingController(
    text: existing?.holidayQuota?.toString() ?? '',
  );
  final overQuotaCostController = TextEditingController(
    text: existing?.overQuotaCostPrice?.toString() ?? '',
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
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final source = await showDialog<ImageSource>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E293B),
                        title: const Text('Select Image Source', style: TextStyle(color: Colors.white)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, ImageSource.camera),
                            child: const Text('Camera', style: TextStyle(color: Color(0xFF818CF8))),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, ImageSource.gallery),
                            child: const Text('Gallery', style: TextStyle(color: Color(0xFF818CF8))),
                          ),
                        ],
                      ),
                    );
                    if (source == null) return;
                    final pickedFile = await picker.pickImage(source: source);
                    if (pickedFile != null) {
                      final appDir = await getApplicationDocumentsDirectory();
                      final String fileExtension = p.extension(pickedFile.path).isNotEmpty
                          ? p.extension(pickedFile.path)
                          : '.jpg';
                      final String newFileName = '${const Uuid().v4()}$fileExtension';
                      final String targetPath = p.join(appDir.path, newFileName);
                      
                      final File localFile = await File(pickedFile.path).copy(targetPath);
                      setState(() {
                        selectedImagePath = localFile.path;
                      });
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 2,
                          ),
                        ),
                        child: selectedImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.file(
                                  File(selectedImagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.broken_image_rounded,
                                    size: 40,
                                    color: Colors.white24,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.add_a_photo_rounded,
                                size: 40,
                                color: Colors.white24,
                              ),
                      ),
                      if (selectedImagePath != null)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedImagePath = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
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
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      minStockController,
                      'Min Stock Alert Limit',
                      Icons.warning_amber_rounded,
                      context,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      shelfLifeController,
                      'Shelf Life (Days)',
                      Icons.hourglass_bottom_rounded,
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
                initialValue: selectedSupplierId,
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DAILY SUPPLIER QUOTA',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 10,
                      color: Colors.white24,
                    ),
                  ),
                  Switch(
                    value: hasQuota,
                    activeThumbColor: const Color(0xFF6366F1),
                    onChanged: (val) {
                      setState(() {
                        hasQuota = val;
                      });
                    },
                  ),
                ],
              ),
              if (hasQuota) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        weekdayQuotaController,
                        'Weekday Quota Limit',
                        Icons.date_range_rounded,
                        context,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        weekendQuotaController,
                        'Weekend Quota Limit',
                        Icons.weekend_rounded,
                        context,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        holidayQuotaController,
                        'Holiday Quota Limit',
                        Icons.campaign_rounded,
                        context,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        overQuotaCostController,
                        'Over-Quota Price',
                        Icons.trending_up_rounded,
                        context,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
              ],
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

                    final threshold =
                        int.tryParse(minStockController.text) ?? 5;
                    final shelfLife =
                        int.tryParse(shelfLifeController.text) ?? 30;
                    final product = existing ?? Product();
                    product.name = nameController.text.trim();
                    product.costPrice = cost;
                    product.sellingPrice = sale;
                    product.supplierId = selectedSupplierId;
                    product.minStockThreshold = threshold;
                    product.shelfLifeDays = shelfLife;
                    product.imagePath = selectedImagePath;

                    if (hasQuota) {
                      final weekdayQuota = double.tryParse(
                        weekdayQuotaController.text,
                      );
                      final weekendQuota = double.tryParse(
                        weekendQuotaController.text,
                      );
                      final holidayQuota = double.tryParse(
                        holidayQuotaController.text,
                      );
                      final overQuotaPrice = double.tryParse(
                        overQuotaCostController.text,
                      );

                      if (weekdayQuota == null || weekdayQuota < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter valid weekday quota'),
                          ),
                        );
                        return;
                      }
                      if (overQuotaPrice == null || overQuotaPrice < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter valid over-quota price',
                            ),
                          ),
                        );
                        return;
                      }
                      product.hasQuota = true;
                      product.weekdayQuota = weekdayQuota;
                      product.weekendQuota = weekendQuota ?? weekdayQuota;
                      product.holidayQuota = holidayQuota ?? weekdayQuota;
                      product.overQuotaCostPrice = overQuotaPrice;
                    } else {
                      product.hasQuota = false;
                      product.weekdayQuota = null;
                      product.weekendQuota = null;
                      product.holidayQuota = null;
                      product.overQuotaCostPrice = null;
                    }

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final useMobileLayout = constraints.maxWidth < 480;

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
                      if (useMobileLayout) ...[
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              padding: product.imagePath != null && File(product.imagePath!).existsSync()
                                  ? EdgeInsets.zero
                                  : const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color:
                                    (isVoid ? Colors.grey : const Color(0xFF6366F1))
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      (isVoid ? Colors.grey : const Color(0xFF6366F1))
                                          .withValues(alpha: 0.2),
                                ),
                              ),
                              child: product.imagePath != null && File(product.imagePath!).existsSync()
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: Image.file(
                                        File(product.imagePath!),
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
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
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
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
                                if (!isVoid)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.restart_alt_rounded,
                                      size: 18,
                                    ),
                                    color: const Color(0xFFF59E0B),
                                    tooltip: 'Reset Stock',
                                    onPressed: () => _showResetStockDialog(
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
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              padding: product.imagePath != null && File(product.imagePath!).existsSync()
                                  ? EdgeInsets.zero
                                  : const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color:
                                    (isVoid ? Colors.grey : const Color(0xFF6366F1))
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      (isVoid ? Colors.grey : const Color(0xFF6366F1))
                                          .withValues(alpha: 0.2),
                                ),
                              ),
                              child: product.imagePath != null && File(product.imagePath!).existsSync()
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: Image.file(
                                        File(product.imagePath!),
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
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
                            const SizedBox(width: 16),
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
                                  if (!isVoid)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.restart_alt_rounded,
                                        size: 18,
                                      ),
                                      color: const Color(0xFFF59E0B),
                                      tooltip: 'Reset Stock',
                                      onPressed: () => _showResetStockDialog(
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
                      ],
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
      },
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

  void _showResetStockDialog(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) {
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    // Get current stock
    final availability = ref
        .read(walkInAvailabilityProvider(DateTime.now()))
        .value;
    final currentStock = availability?[product.id]?.physicalRemaining ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final target = double.tryParse(amountController.text);
          String previewText = 'Enter new stock level above.';
          if (target != null) {
            final diff = target - currentStock;
            if (diff == 0) {
              previewText = 'No adjustment needed (stock matches).';
            } else if (diff > 0) {
              previewText =
                  'This will add a correction of +${diff.toStringAsFixed(1)} units.';
            } else {
              previewText =
                  'This will add a correction of ${diff.toStringAsFixed(1)} units.';
            }
          }

          return Padding(
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
                  'RESET STOCK: ${product.name.toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 14,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Stock: ${currentStock.toStringAsFixed(1)} units',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  onChanged: (_) => setModalState(() {}),
                  decoration: InputDecoration(
                    labelText: 'New Stock Level',
                    helperText: previewText,
                    helperStyle: TextStyle(
                      color: target != null && target - currentStock != 0
                          ? const Color(0xFFF59E0B)
                          : Colors.white38,
                    ),
                    prefixIcon: const Icon(Icons.inventory_2_rounded),
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
                  'ADJUSTMENT DATE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFF59E0B),
                              onPrimary: Colors.white,
                              surface: Color(0xFF0F172A),
                              onSurface: Colors.white,
                            ),
                            dialogTheme: DialogThemeData(
                              backgroundColor: const Color(0xFF0F172A),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setModalState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('yyyy-MM-dd').format(selectedDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      final targetVal = double.tryParse(amountController.text);
                      if (targetVal == null || targetVal < 0) return;

                      final diff = targetVal - currentStock;
                      if (diff == 0) {
                        Navigator.pop(context);
                        return;
                      }

                      final adj = StockAdjustment()
                        ..productId = product.id
                        ..amount = diff
                        ..reason = 'correction'
                        ..date = selectedDate;

                      await ref
                          .read(stockAdjustmentRepositoryProvider)
                          .saveAdjustment(adj);

                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text(
                      'RESET STOCK',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SafetyStockRecommenderBody extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _SafetyStockRecommenderBody({required this.ref});

  @override
  ConsumerState<_SafetyStockRecommenderBody> createState() =>
      _SafetyStockRecommenderBodyState();
}

class _SafetyStockRecommenderBodyState
    extends ConsumerState<_SafetyStockRecommenderBody> {
  double _leadTimeDays = 3.0;
  bool _useDayOfWeekMode = false;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final allOrdersAsync = ref.watch(allOrdersProvider);
    final availabilityAsync = ref.watch(
      walkInAvailabilityProvider(DateTime.now()),
    );

    return Container(
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
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF10B981),
                size: 22,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'SMART SAFETY STOCK',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _useDayOfWeekMode
                ? 'Based on avg sales for ${["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][DateTime.now().weekday - 1]} over the last 90 days × lead time.'
                : 'Based on 14-day average daily sales velocity × lead time.',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 12),
          // Mode toggle
          Row(
            children: [
              _modeChip(
                'AVG VELOCITY',
                !_useDayOfWeekMode,
                () => setState(() => _useDayOfWeekMode = false),
              ),
              const SizedBox(width: 8),
              _modeChip(
                'DAY PATTERN',
                _useDayOfWeekMode,
                () => setState(() => _useDayOfWeekMode = true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Lead time slider
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                color: Colors.white30,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'LEAD TIME:',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_leadTimeDays.toStringAsFixed(0)} days',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF10B981),
              inactiveTrackColor: Colors.white10,
              thumbColor: const Color(0xFF10B981),
              overlayColor: const Color(0xFF10B981).withValues(alpha: 0.1),
              trackHeight: 3,
            ),
            child: Slider(
              value: _leadTimeDays,
              min: 1,
              max: 14,
              divisions: 13,
              onChanged: (v) => setState(() => _leadTimeDays = v),
            ),
          ),
          const SizedBox(height: 8),
          productsAsync.when(
            data: (products) => allOrdersAsync.when(
              data: (orders) => availabilityAsync.when(
                data: (availability) {
                  final cutoff = _useDayOfWeekMode
                      ? DateTime.now().subtract(const Duration(days: 90))
                      : DateTime.now().subtract(const Duration(days: 14));
                  final todayWeekday = DateTime.now().weekday; // 1=Mon..7=Sun
                  final activeProducts = products
                      .where((p) => !p.isVoid)
                      .toList();

                  // Compute velocity per product
                  final Map<int, double> velocity = {};
                  if (_useDayOfWeekMode) {
                    // Group by weekday: sum amounts sold on the same weekday
                    final Map<int, Map<int, double>> weekdaySales = {};
                    for (final o in orders) {
                      if (o.status != OrderStatus.sold) continue;
                      final saleDate = o.fulfilledAt ?? o.dueDate;
                      if (saleDate.isBefore(cutoff)) continue;
                      if (saleDate.weekday != todayWeekday) continue;
                      weekdaySales
                          .putIfAbsent(o.productId, () => {})
                          .update(
                            saleDate.weekday,
                            (v) => v + o.amount,
                            ifAbsent: () => o.amount,
                          );
                    }
                    // Count occurrences of todayWeekday in last 90 days
                    int weekdayCount = 0;
                    for (int d = 0; d < 90; d++) {
                      if (DateTime.now().subtract(Duration(days: d)).weekday ==
                          todayWeekday) {
                        weekdayCount++;
                      }
                    }
                    for (final p in activeProducts) {
                      final totalOnWeekday =
                          weekdaySales[p.id]?.values.fold(
                            0.0,
                            (a, b) => a + b,
                          ) ??
                          0.0;
                      velocity[p.id] = weekdayCount > 0
                          ? totalOnWeekday / weekdayCount
                          : 0.0;
                    }
                  } else {
                    for (final o in orders) {
                      if (o.status != OrderStatus.sold) continue;
                      final saleDate = o.fulfilledAt ?? o.dueDate;
                      if (saleDate.isAfter(cutoff)) {
                        velocity[o.productId] =
                            (velocity[o.productId] ?? 0.0) + o.amount;
                      }
                    }
                  }

                  final List<_SafetyStockEntry> entries = [];
                  for (final p in activeProducts) {
                    final dailyVelocity = (velocity[p.id] ?? 0.0) / 14.0;
                    final recommended = (dailyVelocity * _leadTimeDays)
                        .ceil()
                        .clamp(1, 9999);
                    entries.add(
                      _SafetyStockEntry(
                        product: p,
                        currentThreshold: p.minStockThreshold,
                        recommendedThreshold: recommended,
                        dailyVelocity: dailyVelocity,
                        currentStock:
                            availability[p.id]?.walkInAvailable ?? 0.0,
                      ),
                    );
                  }

                  // Sort: products needing biggest change first
                  entries.sort(
                    (a, b) => (b.recommendedThreshold - b.currentThreshold)
                        .abs()
                        .compareTo(
                          (a.recommendedThreshold - a.currentThreshold).abs(),
                        ),
                  );

                  if (entries.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No active products.',
                          style: TextStyle(color: Colors.white24),
                        ),
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.42,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: entries.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.white.withValues(alpha: 0.05),
                            height: 16,
                          ),
                          itemBuilder: (context, index) {
                            final e = entries[index];
                            final diff =
                                e.recommendedThreshold - e.currentThreshold;
                            final isIncrease = diff > 0;
                            final isDecrease = diff < 0;
                            final isOk = diff == 0;
                            final changeColor = isIncrease
                                ? const Color(0xFFF59E0B)
                                : isDecrease
                                ? const Color(0xFF818CF8)
                                : const Color(0xFF10B981);

                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Velocity: ${e.dailyVelocity.toStringAsFixed(1)}/day  •  Stock: ${e.currentStock.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.white30,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${e.currentThreshold}',
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          isIncrease
                                              ? Icons.arrow_forward_rounded
                                              : isDecrease
                                              ? Icons.arrow_back_rounded
                                              : Icons.check_rounded,
                                          size: 14,
                                          color: changeColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${e.recommendedThreshold}',
                                          style: TextStyle(
                                            color: changeColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      isOk
                                          ? 'Optimal'
                                          : isIncrease
                                          ? '+$diff (increase)'
                                          : '$diff (decrease)',
                                      style: TextStyle(
                                        color: changeColor.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!isOk) ...[
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () async {
                                      final updated = Product()
                                        ..id = e.product.id
                                        ..name = e.product.name
                                        ..sellingPrice = e.product.sellingPrice
                                        ..costPrice = e.product.costPrice
                                        ..minStockThreshold =
                                            e.recommendedThreshold
                                        ..supplierId = e.product.supplierId
                                        ..isVoid = e.product.isVoid;
                                      await ref
                                          .read(productRepositoryProvider)
                                          .saveProduct(updated);
                                      ref.invalidate(productsProvider);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '✓ ${e.product.name} threshold updated to ${e.recommendedThreshold}',
                                            ),
                                            backgroundColor: const Color(
                                              0xFF10B981,
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: changeColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: changeColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'APPLY',
                                        style: TextStyle(
                                          color: changeColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 9,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.bolt_rounded, size: 16),
                          label: const Text(
                            'APPLY ALL RECOMMENDATIONS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          onPressed: () async {
                            final toApply = entries
                                .where(
                                  (e) =>
                                      e.recommendedThreshold !=
                                      e.currentThreshold,
                                )
                                .toList();
                            for (final e in toApply) {
                              final updated = Product()
                                ..id = e.product.id
                                ..name = e.product.name
                                ..sellingPrice = e.product.sellingPrice
                                ..costPrice = e.product.costPrice
                                ..minStockThreshold = e.recommendedThreshold
                                ..supplierId = e.product.supplierId
                                ..isVoid = e.product.isVoid;
                              await ref
                                  .read(productRepositoryProvider)
                                  .saveProduct(updated);
                            }
                            ref.invalidate(productsProvider);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '✓ Updated ${toApply.length} product thresholds.',
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  ),
                ),
                error: (e, _) => const SizedBox.shrink(),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF10B981)),
                ),
              ),
              error: (e, _) => const SizedBox.shrink(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              ),
            ),
            error: (e, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF10B981).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF10B981)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: selected ? const Color(0xFF10B981) : Colors.white38,
          ),
        ),
      ),
    );
  }
}

class _SafetyStockEntry {
  final Product product;
  final int currentThreshold;
  final int recommendedThreshold;
  final double dailyVelocity;
  final double currentStock;

  _SafetyStockEntry({
    required this.product,
    required this.currentThreshold,
    required this.recommendedThreshold,
    required this.dailyVelocity,
    required this.currentStock,
  });
}

void _showHolidayManager(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.98),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => const _HolidayManagerSheet(),
  );
}

class _HolidayManagerSheet extends ConsumerWidget {
  const _HolidayManagerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(holidaysProvider);
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MANAGE HOLIDAYS',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    fontSize: 14,
                    color: Color(0xFF818CF8),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white38),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: holidaysAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Text(
                        'No custom holidays configured yet.',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final holiday = list[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat(
                                    'EEEE, MMM dd, yyyy',
                                  ).format(holiday.date),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                if (holiday.name != null &&
                                    holiday.name!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    holiday.name!,
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF0F172A),
                                    title: const Text('DELETE HOLIDAY?'),
                                    content: Text(
                                      'Are you sure you want to remove ${holiday.name ?? "this holiday"}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('CANCEL'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          'DELETE',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref
                                      .read(holidayRepositoryProvider)
                                      .deleteHoliday(holiday.id);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'ADD NEW HOLIDAY',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                onPressed: () => _addHoliday(context, ref),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _addHoliday(BuildContext context, WidgetRef ref) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Color(0xFF0F172A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    if (!context.mounted) return;

    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('HOLIDAY NAME'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Christmas, New Year (Optional)',
            hintStyle: TextStyle(color: Colors.white24),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('SKIP'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    final holiday = Holiday()
      ..date = selectedDate
      ..name = name;

    await ref.read(holidayRepositoryProvider).saveHoliday(holiday);
  }
}
