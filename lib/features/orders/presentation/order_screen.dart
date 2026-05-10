import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:shopsync/features/dashboard/presentation/ui_providers.dart';

class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final showVoided = ref.watch(showVoidedOrdersProvider);

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
          ref.invalidate(ordersProvider);
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
                title: Text(
                  'ORDERS: ${DateFormat('MMM dd').format(selectedDate).toUpperCase()}',
                ),
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
                      onPressed: () =>
                          ref.read(showVoidedOrdersProvider.notifier).state =
                              !showVoided,
                      tooltip: 'Show Voided Orders',
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
                        Icons.calendar_month_rounded,
                        color: Color(0xFF818CF8),
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
                          ref.read(selectedDateProvider.notifier).state = date;
                        }
                      },
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: _buildFilterBar(context, ref),
                ),
              ),
              ordersAsync.when(
                data: (_) {
                  final orders = ref.watch(filteredOrdersProvider);
                  return orders.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No matching orders',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final order = orders[index];
                              return _OrderCard(order: order);
                            }, childCount: orders.length),
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
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: FloatingActionButton.extended(
              onPressed: () => _onCreateOrder(context, ref),
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text(
                'NEW ORDER',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(orderFilterProvider);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
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
      child: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'NEW CUSTOMER ORDER' : 'EDIT CUSTOMER ORDER',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 14,
                  color: Colors.indigoAccent,
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<int>(
                value: selectedProductId,
                dropdownColor: const Color(0xFF1E293B),
                items: products
                    .map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedProductId = val),
                decoration: _fieldDecoration(
                  'Product',
                  Icons.inventory_2_rounded,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                customerController,
                'Customer Name',
                Icons.person_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                phoneController,
                'Phone Number (Optional)',
                Icons.phone_rounded,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      amountController,
                      'Amount',
                      Icons.numbers_rounded,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      advanceController,
                      'Advance',
                      Icons.payments_rounded,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                value: selectedPayment,
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
                onChanged: (val) =>
                    setState(() => selectedPayment = val ?? selectedPayment),
                decoration: _fieldDecoration(
                  'Payment Method',
                  Icons.account_balance_wallet_rounded,
                ),
              ),
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
                    lastDate: DateTime.now().add(const Duration(days: 90)),
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
                  onPressed: () async {
                    if (customerController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter customer name'),
                        ),
                      );
                      return;
                    }
                    final amount = double.tryParse(amountController.text);
                    final advance =
                        double.tryParse(advanceController.text) ?? 0;
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                        ),
                      );
                      return;
                    }

                    if (selectedProductId == null) return;
                    final product = products.firstWhere(
                      (p) => p.id == selectedProductId,
                    );

                    final total = amount * product.sellingPrice;
                    if (advance > total) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Advance cannot exceed total price'),
                        ),
                      );
                      return;
                    }

                    final order = existing ?? CustomerOrder();
                    order.productId = selectedProductId!;
                    order.customerName = customerController.text.trim();
                    order.phoneNumber = phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim();
                    order.amount =
                        double.tryParse(amountController.text) ?? 1.0;
                    order.advancePayment = advance;
                    order.paymentMethod = selectedPayment;
                    order.dueDate = selectedDate;
                    order.sellingPriceAtTime = product.sellingPrice;
                    order.costPriceAtTime = product.costPrice;
                    // If new order, status is pending
                    if (existing == null) {
                      order.status = OrderStatus.pending;
                    }

                    print(
                      'DEBUG: Dialog saving order. Name: ${order.customerName}, Status: ${order.status}',
                    );
                    await ref.read(orderRepositoryProvider).saveOrder(order);

                    if (context.mounted) {
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
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    existing == null ? 'SAVE ORDER' : 'UPDATE ORDER',
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

InputDecoration _fieldDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.03),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    labelStyle: const TextStyle(fontSize: 14, color: Colors.white38),
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
    decoration: _fieldDecoration(label, icon),
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
    final remaining = availability[order.productId] ?? 0.0;

    final products = ref.watch(productsProvider).value ?? [];
    final product = products.firstWhere(
      (p) => p.id == order.productId,
      orElse: () => Product()..name = 'Unknown',
    );

    final isSold = order.status == OrderStatus.sold;
    final isVoid = order.isVoid;
    final total = order.amount * order.sellingPriceAtTime;
    final balance = total - order.advancePayment;
    final progress = total > 0
        ? (order.advancePayment / total).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
                                  color: Colors.white.withValues(alpha: 0.4),
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
                        const Text(
                          'TOTAL ETB',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white24,
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
                  color: Colors.white.withValues(alpha: 0.03),
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
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
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
                            if (remaining < 0) {
                              final proceed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E293B),
                                  title: const Text(
                                    'Stock Shortfall',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  content: Text(
                                    'Fulfilling this order will exacerbate a stock shortfall of ${remaining.abs().toStringAsFixed(1)} units for this product. Proceed anyway?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text(
                                        'CANCEL',
                                        style: TextStyle(color: Colors.white38),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
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
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          'RESTORE?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('Bring this order back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(orderRepositoryProvider).unvoidOrder(order.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'YES, RESTORE',
              style: TextStyle(color: Colors.greenAccent),
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
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          'VOID ORDER?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('This will hide it from the main list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(orderRepositoryProvider).voidOrder(order.id);
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
