import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';

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
              ordersAsync.when(
                data: (orders) => orders.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No orders for this date',
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
                            final order = orders[index];
                            return _OrderCard(order: order);
                          }, childCount: orders.length),
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

  void _onCreateOrder(BuildContext context, WidgetRef ref) {
    _showOrderDialog(context, ref);
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
    if (existingProduct != null && !products.any((p) => p.id == existingProduct.id)) {
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
  final phoneController = TextEditingController(
    text: existing?.phoneNumber,
  );
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
                'Phone Number',
                Icons.phone_rounded,
                isNumber: true,
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
                    order.phoneNumber = phoneController.text.trim().isEmpty ? null : phoneController.text.trim();
                    order.amount = amount;
                    order.advancePayment = advance;
                    order.paymentMethod = selectedPayment;
                    order.dueDate = selectedDate;
                    order.sellingPriceAtTime = product.sellingPrice;
                    order.costPriceAtTime = product.costPrice;
                    // If new order, status is pending
                    if (existing == null) {
                      order.status = OrderStatus.pending;
                    }

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
    final products = ref.watch(productsProvider).value ?? [];
    final product = products.firstWhere(
      (p) => p.id == order.productId,
      orElse: () => Product()..name = 'Unknown',
    );

    final isSold = order.status == OrderStatus.sold;
    final isVoid = order.isVoid;
    final balance = (order.amount * order.sellingPriceAtTime) - order.advancePayment;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isVoid
              ? Colors.white.withValues(alpha: 0.05)
              : (isSold
                  ? Colors.greenAccent.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.08)),
        ),
        boxShadow: [
          if (!isVoid)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Opacity(
          opacity: isVoid ? 0.4 : 1.0,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isVoid
                              ? [Colors.white10, Colors.white10]
                              : (isSold
                                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                  : [const Color(0xFF818CF8), const Color(0xFF6366F1)]),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (!isVoid)
                            BoxShadow(
                              color: (isSold ? Colors.green : Colors.indigo)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Icon(
                        isVoid
                            ? Icons.auto_delete_rounded
                            : (isSold
                                ? Icons.check_circle_rounded
                                : Icons.receipt_long_rounded),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${order.amount.toStringAsFixed(0)} × ${product.name}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          (order.amount * order.sellingPriceAtTime).toStringAsFixed(0),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: -1,
                          ),
                        ),
                        const Text(
                          'TOTAL ETB',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white24,
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isVoid && (order.advancePayment > 0 || isSold))
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniInfo('ADVANCE', '${order.advancePayment.toStringAsFixed(0)} ETB', Colors.greenAccent),
                      _buildMiniInfo('BALANCE', '${balance.toStringAsFixed(0)} ETB', balance > 0 ? Colors.orangeAccent : Colors.white24),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Row(
                  children: [
                    if (!isVoid) ...[
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildBadge(
                              order.paymentMethod.name.toUpperCase(),
                              const Color(0xFF60A5FA),
                            ),
                            const SizedBox(width: 8),
                            _buildBadge(
                              order.status.name.toUpperCase(),
                              isSold ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      _buildBadge('VOIDED', Colors.redAccent),
                    const Spacer(),
                    if (!isVoid) ...[
                      if (isSold)
                        _ActionButton(
                          icon: Icons.undo_rounded,
                          label: 'UNDO',
                          color: Colors.white24,
                          onTap: () => ref
                              .read(orderRepositoryProvider)
                              .updateOrderStatus(order.id, OrderStatus.pending),
                        )
                      else
                        _ActionButton(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'FULFILL',
                          color: const Color(0xFF10B981),
                          onTap: () => ref
                              .read(orderRepositoryProvider)
                              .updateOrderStatus(order.id, OrderStatus.sold),
                          filled: true,
                        ),
                      const SizedBox(width: 12),
                      _CircleAction(
                        icon: Icons.edit_rounded,
                        onTap: () => _showOrderDialog(context, ref, order),
                      ),
                      const SizedBox(width: 8),
                      _CircleAction(
                        icon: Icons.delete_sweep_rounded,
                        color: Colors.redAccent.withValues(alpha: 0.4),
                        onTap: () => _showVoidOrderDialog(context, ref, order),
                      ),
                    ] else
                      _CircleAction(
                        icon: Icons.restore_rounded,
                        color: Colors.greenAccent,
                        onTap: () => _showRestoreOrderDialog(context, ref, order),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white24),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  void _showRestoreOrderDialog(BuildContext context, WidgetRef ref, CustomerOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('RESTORE ORDER?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        content: const Text('Do you want to bring this order back into your active list?', style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              await ref.read(orderRepositoryProvider).unvoidOrder(order.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('RESTORE', style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  void _showVoidOrderDialog(BuildContext context, WidgetRef ref, CustomerOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('VOID ORDER?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        content: const Text('This will hide the order from your daily list. You can restore it later.', style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              await ref.read(orderRepositoryProvider).voidOrder(order.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('VOID', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: filled ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: filled ? Colors.white : color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _CircleAction({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: (color ?? Colors.white).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 18, color: color ?? Colors.white38),
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
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
    ),
  );
}

