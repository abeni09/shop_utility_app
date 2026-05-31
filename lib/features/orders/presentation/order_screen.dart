import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/data/addon_model.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:shopsync/features/dashboard/presentation/ui_providers.dart';

class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  final Map<int, bool> _collapsedProducts = {};

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final showVoided = ref.watch(showVoidedOrdersProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -200) {
            ref.read(selectedDateProvider.notifier).state = selectedDate.add(
              const Duration(days: 1),
            );
          } else if (details.primaryVelocity! > 200) {
            ref.read(selectedDateProvider.notifier).state = selectedDate
                .subtract(const Duration(days: 1));
          }
        },
        child: Stack(
          children: [
            // Background Decorative Blobs
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.05),
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: () async {
                await ref.read(backupServiceProvider).forceSyncCheck();
                ref.invalidate(cloudSyncStatusProvider);
                ref.invalidate(localAheadProvider);
                ref.invalidate(ordersProvider);
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
                      title: Text(
                        'ORDERS: ${DateFormat('MMM dd').format(selectedDate).toUpperCase()}',
                      ),
                      actions: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: showVoided
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.2)
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.05),
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
                                        .read(showVoidedOrdersProvider.notifier)
                                        .state =
                                    !showVoided,
                            tooltip: 'Show Voided Orders',
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
                              Icons.calendar_month_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                ref.read(selectedDateProvider.notifier).state =
                                    date;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: _buildFilterBar(context, ref),
                      ),
                    ),
                    ordersAsync.when(
                      data: (_) {
                        final orders = ref.watch(filteredOrdersProvider);
                        final products =
                            ref.watch(productsProvider).value ?? [];
                        final width = MediaQuery.of(context).size.width;
                        final horizontalPadding = width > 1200
                            ? width * 0.1
                            : (width > 800 ? 48.0 : 24.0);
                        final crossAxisCount = width > 1000
                            ? 3
                            : (width > 600 ? 2 : 1);

                        if (orders.isEmpty) {
                          return const SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'No matching orders',
                                style: TextStyle(color: Colors.white38),
                              ),
                            ),
                          );
                        }

                        // Group orders by product
                        final Map<int, List<CustomerOrder>> groupedOrders = {};
                        for (var order in orders) {
                          groupedOrders
                              .putIfAbsent(order.productId, () => [])
                              .add(order);
                        }

                        return SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final productId = groupedOrders.keys.elementAt(
                                index,
                              );
                              final productOrders = groupedOrders[productId]!;
                              final product = products.firstWhere(
                                (p) => p.id == productId,
                                orElse: () =>
                                    Product()..name = 'Unknown Product',
                              );
                              final isCollapsed =
                                  _collapsedProducts[productId] ?? true;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Header Section
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _collapsedProducts[productId] =
                                            !isCollapsed;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 8,
                                      ),
                                      margin: const EdgeInsets.only(
                                        top: 16,
                                        bottom: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF6366F1,
                                              ).withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.inventory_2_rounded,
                                              color: Color(0xFF818CF8),
                                              size: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            product.name.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.5,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF6366F1,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFF6366F1,
                                                ).withValues(alpha: 0.2),
                                              ),
                                            ),
                                            child: Text(
                                              '${productOrders.length} ${productOrders.length == 1 ? "ORDER" : "ORDERS"}',
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF818CF8),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            isCollapsed
                                                ? Icons
                                                      .keyboard_arrow_right_rounded
                                                : Icons
                                                      .keyboard_arrow_down_rounded,
                                            color: Colors.white30,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Grid/List of Orders for this product
                                  if (!isCollapsed)
                                    crossAxisCount > 1
                                        ? GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount:
                                                      crossAxisCount,
                                                  mainAxisSpacing: 16,
                                                  crossAxisSpacing: 16,
                                                  mainAxisExtent: 420,
                                                ),
                                            itemCount: productOrders.length,
                                            itemBuilder: (context, idx) =>
                                                _OrderCard(
                                                  order: productOrders[idx],
                                                ),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: productOrders.length,
                                            itemBuilder: (context, idx) =>
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 16,
                                                      ),
                                                  child: _OrderCard(
                                                    order: productOrders[idx],
                                                  ),
                                                ),
                                          ),
                                ],
                              );
                            }, childCount: groupedOrders.length),
                          ),
                        );
                      },
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
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
                floatingActionButton: Padding(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: FloatingActionButton.extended(
                    onPressed: () => _onCreateOrder(context, ref),
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text(
                      'NEW ORDER',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(orderFilterProvider);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterChip(
              label: 'ACTIVE',
              isSelected: currentFilter == OrderFilter.active,
              onTap: () => ref.read(orderFilterProvider.notifier).state =
                  OrderFilter.active,
            ),
          ),
          Expanded(
            child: _FilterChip(
              label: 'COMPLETED',
              isSelected: currentFilter == OrderFilter.completed,
              onTap: () => ref.read(orderFilterProvider.notifier).state =
                  OrderFilter.completed,
            ),
          ),
          Expanded(
            child: _FilterChip(
              label: 'ALL',
              isSelected: currentFilter == OrderFilter.all,
              onTap: () => ref.read(orderFilterProvider.notifier).state =
                  OrderFilter.all,
            ),
          ),
        ],
      ),
    );
  }

  void _onCreateOrder(BuildContext context, WidgetRef ref) {
    _showOrderDialog(context, ref);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: isSelected ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }
}

void _showOrderDialog(
  BuildContext context,
  WidgetRef ref, [
  CustomerOrder? existing,
]) {
  final orderRepo = ref.read(orderRepositoryProvider);
  var products = ref.read(productsProvider).value ?? [];
  // Only show non-voided products
  products = products.where((p) => !p.isVoid).toList();
  // Ensure the existing product is in the list even if voided
  if (existing?.productId != null) {
    final existingProduct = (ref.read(productsProvider).value ?? [])
        .where((p) => p.id == existing!.productId)
        .firstOrNull;
    if (existingProduct != null &&
        !products.any((p) => p.id == existingProduct.id)) {
      products.add(existingProduct);
    }
  }

  if (products.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Please add products first!')));
    return;
  }

  int? selectedProductId = existing?.productId ?? products.first.id;
  final customerController = TextEditingController(
    text: existing?.customerName,
  );
  final amountController = TextEditingController(
    text: existing?.amount.toStringAsFixed(0),
  );
  final advanceController = TextEditingController(
    text: existing?.advancePayment.toStringAsFixed(0) ?? '0',
  );
  final phoneController = TextEditingController(text: existing?.phoneNumber);
  PaymentMethod selectedPayment = existing?.paymentMethod ?? PaymentMethod.cash;
  DateTime selectedDate = existing?.dueDate ?? ref.read(selectedDateProvider);
  bool isSaving = false;

  int? selectedAddonId = existing?.addonName != null ? 0 : 0;
  String? selectedAddonName = existing?.addonName;
  double? selectedAddonPrice = existing?.addonPrice;
  double? selectedAddonCost = existing?.addonCost;
  double addonAmount = existing?.addonAmount ?? 1.0;
  bool isAddonInitialized = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.98),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => Consumer(
      builder: (context, ref, child) {
        final addons = ref.watch(addonsProvider).value ?? [];

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              if (existing != null &&
                  existing.addonName != null &&
                  !isAddonInitialized) {
                final matched = addons
                    .where((a) => a.name == existing.addonName)
                    .firstOrNull;
                if (matched != null) {
                  selectedAddonId = matched.id;
                  selectedAddonName = matched.name;
                  selectedAddonPrice = matched.price;
                  selectedAddonCost = matched.cost;
                  isAddonInitialized = true;
                } else if (addons.isNotEmpty) {
                  selectedAddonId = -1;
                  isAddonInitialized = true;
                }
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null
                          ? 'NEW CUSTOMER ORDER'
                          : 'EDIT CUSTOMER ORDER',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        fontSize: 14,
                        color: Color(0xFF818CF8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<int>(
                      initialValue: selectedProductId,
                      dropdownColor: const Color(0xFF1E293B),
                      items: products
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedProductId = val),
                      decoration: _fieldDecoration(
                        'Product',
                        Icons.inventory_2_rounded,
                        context,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      customerController,
                      'Customer Name',
                      Icons.person_rounded,
                      context,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      phoneController,
                      'Phone Number (Optional)',
                      Icons.phone_rounded,
                      context,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            amountController,
                            'Amount',
                            Icons.numbers_rounded,
                            context,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            advanceController,
                            'Advance',
                            Icons.payments_rounded,
                            context,
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<PaymentMethod>(
                      initialValue: selectedPayment,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      items: PaymentMethod.values
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                p.name.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(
                        () => selectedPayment = val ?? selectedPayment,
                      ),
                      decoration: _fieldDecoration(
                        'Payment Method',
                        Icons.account_balance_wallet_rounded,
                        context,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: selectedAddonId,
                      dropdownColor: const Color(0xFF1E293B),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int>(
                          value: 0,
                          child: Text('NONE (NO ADD-ON)'),
                        ),
                        ...addons.map(
                          (a) => DropdownMenuItem<int>(
                            value: a.id,
                            child: Text(
                              '${a.name.toUpperCase()} (${a.price.toStringAsFixed(0)} ETB)',
                            ),
                          ),
                        ),
                        const DropdownMenuItem<int>(
                          value: -1,
                          child: Text(
                            '+ ADD CUSTOM ADD-ON',
                            style: TextStyle(
                              color: Color(0xFF818CF8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) async {
                        if (val == 0) {
                          setState(() {
                            selectedAddonId = 0;
                            selectedAddonName = null;
                            selectedAddonPrice = null;
                            selectedAddonCost = null;
                          });
                        } else if (val == -1) {
                          final result = await _showCustomAddonDialog(
                            context,
                            ref,
                          );
                          if (result != null) {
                            setState(() {
                              selectedAddonId = result.id;
                              selectedAddonName = result.name;
                              selectedAddonPrice = result.price;
                              selectedAddonCost = result.cost;
                            });
                          } else {
                            setState(() {
                              selectedAddonId = 0;
                              selectedAddonName = null;
                              selectedAddonPrice = null;
                              selectedAddonCost = null;
                            });
                          }
                        } else if (val != null) {
                          final selectedAddon = addons.firstWhere(
                            (a) => a.id == val,
                          );
                          setState(() {
                            selectedAddonId = val;
                            selectedAddonName = selectedAddon.name;
                            selectedAddonPrice = selectedAddon.price;
                            selectedAddonCost = selectedAddon.cost;
                          });
                        }
                      },
                      decoration: _fieldDecoration(
                        'Add-on (Optional)',
                        Icons.add_box_rounded,
                        context,
                      ),
                    ),
                    if (selectedAddonName != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedAddonName!.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: Colors.amberAccent,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Price: ${selectedAddonPrice?.toStringAsFixed(0)} ETB | Cost: ${selectedAddonCost?.toStringAsFixed(0)} ETB',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_rounded,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed: () {
                                      if (addonAmount > 1) {
                                        setState(() => addonAmount--);
                                      }
                                    },
                                  ),
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      addonAmount.toStringAsFixed(0),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed: () {
                                      setState(() => addonAmount++);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Due: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.indigoAccent,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.edit_rounded,
                        size: 20,
                        color: Colors.white24,
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 30),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                        );
                        if (date != null) setState(() => selectedDate = date);
                      },
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
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (customerController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter customer name',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final amount = double.tryParse(
                                  amountController.text,
                                );
                                final advance =
                                    double.tryParse(advanceController.text) ??
                                    0;
                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a valid amount',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (selectedProductId == null) return;
                                final product = products.firstWhere(
                                  (p) => p.id == selectedProductId,
                                );

                                final total =
                                    amount * product.sellingPrice +
                                    (selectedAddonName != null
                                        ? addonAmount *
                                              (selectedAddonPrice ?? 0.0)
                                        : 0.0);
                                if (advance > total) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Advance cannot exceed total price',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final order = existing ?? CustomerOrder();
                                order.productId = selectedProductId!;
                                order.customerName = customerController.text
                                    .trim();
                                order.phoneNumber =
                                    phoneController.text.trim().isEmpty
                                    ? null
                                    : phoneController.text.trim();
                                order.amount =
                                    double.tryParse(amountController.text) ??
                                    1.0;
                                order.advancePayment = advance;
                                order.paymentMethod = selectedPayment;
                                order.dueDate = selectedDate;
                                order.sellingPriceAtTime = product.sellingPrice;
                                order.costPriceAtTime = product.costPrice;

                                order.addonName = selectedAddonName;
                                order.addonPrice = selectedAddonPrice;
                                order.addonCost = selectedAddonCost;
                                order.addonAmount = selectedAddonName != null
                                    ? addonAmount
                                    : null;

                                if (existing == null) {
                                  order.status = OrderStatus.pending;
                                }

                                setState(() => isSaving = true);
                                try {
                                  await orderRepo.saveOrder(order);
                                } catch (e) {
                                  if (context.mounted) {
                                    setState(() => isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                  return;
                                }

                                if (context.mounted &&
                                    Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      content: Text(
                                        existing == null
                                            ? 'Order created successfully!'
                                            : 'Order updated successfully!',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                existing == null
                                    ? 'SAVE ORDER'
                                    : 'UPDATE ORDER',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

Future<Addon?> _showCustomAddonDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final costController = TextEditingController();

  return showDialog<Addon>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      title: const Text(
        'NEW CUSTOM ADD-ON',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 1.5,
          color: Color(0xFF818CF8),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Add-on Name',
                labelStyle: TextStyle(color: Colors.white38),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Selling Price (ETB)',
                labelStyle: TextStyle(color: Colors.white38),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cost Price (ETB)',
                labelStyle: TextStyle(color: Colors.white38),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text(
            'CANCEL',
            style: TextStyle(
              color: Colors.white24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = nameController.text.trim();
            final price = double.tryParse(priceController.text) ?? 0.0;
            final cost = double.tryParse(costController.text) ?? 0.0;
            if (name.isEmpty || price <= 0 || cost < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill all fields with valid data'),
                ),
              );
              return;
            }
            final newAddon = Addon()
              ..name = name
              ..price = price
              ..cost = cost;
            await ref.read(addonRepositoryProvider).saveAddon(newAddon);
            if (context.mounted) {
              Navigator.pop(context, newAddon);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'CREATE',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}

InputDecoration _fieldDecoration(
  String label,
  IconData icon,
  BuildContext context,
) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(
      icon,
      color: Theme.of(context).colorScheme.primary,
      size: 20,
    ),
    labelStyle: const TextStyle(
      color: Colors.white38,
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
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
    decoration: _fieldDecoration(label, icon, context),
  );
}

class _OrderCard extends ConsumerWidget {
  final CustomerOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync = ref.watch(
      walkInAvailabilityProvider(order.dueDate),
    );
    final availability = availabilityAsync.asData?.value ?? {};
    final status =
        availability[order.productId] ??
        (
          walkInAvailable: 0.0,
          physicalRemaining: 0.0,
          reserved: 0.0,
          totalReceived: 0.0,
          totalSold: 0.0,
        );

    final products = ref.watch(productsProvider).value ?? [];
    final product = products.firstWhere(
      (p) => p.id == order.productId,
      orElse: () => Product()..name = 'Unknown',
    );

    final isSold = order.status == OrderStatus.sold;
    final isVoid = order.isVoid;
    final total =
        order.amount * order.sellingPriceAtTime +
        (order.addonName != null
            ? (order.addonPrice ?? 0.0) * (order.addonAmount ?? 0.0)
            : 0.0);
    final balance = total - order.advancePayment;
    final progress = total > 0
        ? (order.advancePayment / total).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Opacity(
          opacity: isVoid ? 0.5 : 1.0,
          child: Column(
            children: [
              // HEADER SECTION
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isVoid
                                      ? Colors.redAccent
                                      : (isSold
                                            ? Colors.greenAccent
                                            : Colors.amberAccent),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isVoid
                                                  ? Colors.red
                                                  : (isSold
                                                        ? Colors.green
                                                        : Colors.amber))
                                              .withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                order.status.name.toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.customerName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (order.phoneNumber != null &&
                              order.phoneNumber!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final Uri launchUri = Uri(
                                  scheme: 'tel',
                                  path: order.phoneNumber,
                                );
                                if (await canLaunchUrl(launchUri)) {
                                  await launchUrl(launchUri);
                                }
                              },
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.phone_rounded,
                                    size: 12,
                                    color: Color(0xFF818CF8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    order.phoneNumber!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF818CF8),
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF818CF8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          total.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'TOTAL ETB',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.2),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // PRODUCT INFO BOX
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigoAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.indigoAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Qty: ${order.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'STK: ${status.physicalRemaining.toStringAsFixed(0)} (AVL: ${status.walkInAvailable.toStringAsFixed(0)})',
                            style: TextStyle(
                              color: status.physicalRemaining < order.amount
                                  ? Colors.redAccent
                                  : Colors.greenAccent.withValues(alpha: 0.5),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (order.addonName != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 12,
                                  color: Colors.amberAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+ ${order.addonName} (x${order.addonAmount?.toStringAsFixed(0)}): ${((order.addonAmount ?? 0.0) * (order.addonPrice ?? 0.0)).toStringAsFixed(0)} ETB',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildBadge(
                      order.paymentMethod.name.toUpperCase(),
                      const Color(0xFF6366F1),
                    ),
                  ],
                ),
              ),

              // FINANCIAL PROGRESS SECTION
              if (!isVoid)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PAYMENT PROGRESS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: 0.3),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: progress >= 1.0
                                  ? Colors.greenAccent
                                  : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            height: 6,
                            width:
                                MediaQuery.of(context).size.width *
                                0.7 *
                                progress,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPriceInfo(
                            'PAID',
                            order.advancePayment,
                            Colors.greenAccent,
                          ),
                          _buildPriceInfo(
                            'DUE',
                            balance,
                            balance > 0 ? Colors.orangeAccent : Colors.white24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // ACTION BAR
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                ),
                child: Row(
                  children: [
                    if (!isVoid) ...[
                      if (isSold)
                        _SoftAction(
                          label: 'REOPEN',
                          icon: Icons.undo_rounded,
                          color: Colors.white38,
                          onTap: () => ref
                              .read(orderRepositoryProvider)
                              .updateOrderStatus(order.id, OrderStatus.pending),
                        )
                      else
                        _SoftAction(
                          label: 'FULFILL',
                          icon: Icons.check_rounded,
                          color: Colors.greenAccent,
                          onTap: () async {
                            if (status.walkInAvailable < 0) {
                              String title = 'Stock Shortfall';
                              String message =
                                  'Fulfilling this order will exacerbate a stock shortfall for this product.';
                              Color titleColor = Colors.redAccent;

                              if (status.physicalRemaining >= 0) {
                                title = 'Dipping into Pre-orders';
                                message =
                                    'Fulfilling this will use stock that is technically reserved for other pre-orders (likely walk-in sales have already used some stock).';
                                titleColor = Colors.orangeAccent;
                              } else {
                                title = 'Physical Shortfall';
                                message =
                                    'You do not have enough physical stock to fulfill this order! You are short by ${status.physicalRemaining.abs().toStringAsFixed(1)} units.';
                              }

                              final proceed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF0F172A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(
                                        titleColor == Colors.redAccent
                                            ? Icons.error_outline_rounded
                                            : Icons.warning_amber_rounded,
                                        color: titleColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        title.toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          letterSpacing: 1.2,
                                          color: titleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    message,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.canPop(context)
                                          ? Navigator.pop(context, false)
                                          : null,
                                      child: const Text(
                                        'CANCEL',
                                        style: TextStyle(
                                          color: Colors.white24,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.canPop(context)
                                          ? Navigator.pop(context, true)
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: titleColor,
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shadowColor: titleColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'PROCEED',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (proceed != true) return;
                            }

                            ref
                                .read(orderRepositoryProvider)
                                .updateOrderStatus(order.id, OrderStatus.sold);
                          },
                        ),
                      const Spacer(),
                      _IconButton(
                        icon: Icons.edit_rounded,
                        onTap: () => _showOrderDialog(context, ref, order),
                      ),
                      const SizedBox(width: 8),
                      _IconButton(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        onTap: () => _showVoidOrderDialog(context, ref, order),
                      ),
                    ] else ...[
                      const Spacer(),
                      _SoftAction(
                        label: 'RESTORE',
                        icon: Icons.restore_rounded,
                        color: Colors.greenAccent,
                        onTap: () =>
                            _showRestoreOrderDialog(context, ref, order),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.2),
            letterSpacing: 1,
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)} ETB',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showRestoreOrderDialog(
    BuildContext context,
    WidgetRef ref,
    CustomerOrder order,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        title: const Text(
          'RESTORE ORDER?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
            color: Colors.greenAccent,
          ),
        ),
        content: const Text(
          'Bring this order back to your active list?',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.canPop(context) ? Navigator.pop(context) : null,
            child: const Text(
              'NO',
              style: TextStyle(
                color: Colors.white24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(orderRepositoryProvider).unvoidOrder(order.id);
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: const Text(
              'YES, RESTORE',
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

  void _showVoidOrderDialog(
    BuildContext context,
    WidgetRef ref,
    CustomerOrder order,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        title: const Text(
          'VOID ORDER?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
            color: Color(0xFFEF4444),
          ),
        ),
        content: const Text(
          'This will hide the order from your main list and void its impact on stock.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.canPop(context) ? Navigator.pop(context) : null,
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
              await ref.read(orderRepositoryProvider).voidOrder(order.id);
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: const Text(
              'VOID ORDER',
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
}

class _SoftAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SoftAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _IconButton({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 20, color: color ?? Colors.white38),
      ),
    );
  }
}

Widget _buildBadge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    ),
  );
}
