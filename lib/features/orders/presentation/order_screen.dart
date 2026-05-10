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
              onPressed: () => _showCreateOrderDialog(context, ref),
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

  void _showCreateOrderDialog(BuildContext context, WidgetRef ref) {
    final products = ref.read(productsProvider).value ?? [];
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add products first!')),
      );
      return;
    }

    int? selectedProductId = products.first.id;
    final customerController = TextEditingController();
    final amountController = TextEditingController();
    PaymentMethod selectedPayment = PaymentMethod.cash;
    DateTime selectedDate = ref.read(selectedDateProvider);

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
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NEW CUSTOMER ORDER',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 14,
                  color: Colors.indigoAccent,
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<int>(
                initialValue: selectedProductId,
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
                    child: DropdownButtonFormField<PaymentMethod>(
                      initialValue: selectedPayment,
                      dropdownColor: const Color(0xFF1E293B),
                      items: PaymentMethod.values
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedPayment = val!),
                      decoration: _fieldDecoration(
                        'Payment',
                        Icons.payments_rounded,
                      ),
                    ),
                  ),
                ],
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
                    firstDate: DateTime.now(),
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
                    final product = products.firstWhere(
                      (p) => p.id == selectedProductId,
                    );
                    final order = CustomerOrder()
                      ..productId = selectedProductId!
                      ..customerName = customerController.text
                      ..amount = double.tryParse(amountController.text) ?? 1.0
                      ..dueDate = selectedDate
                      ..status = OrderStatus.pending
                      ..paymentMethod = selectedPayment
                      ..costPriceAtTime = product.costPrice
                      ..sellingPriceAtTime = product.sellingPrice;

                    await ref.read(orderRepositoryProvider).saveOrder(order);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'CREATE ORDER',
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isVoid
            ? Colors.white.withValues(alpha: 0.01)
            : (isSold
                  ? Colors.green.withValues(alpha: 0.03)
                  : Colors.white.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isVoid
              ? Colors.white.withValues(alpha: 0.02)
              : (isSold
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Opacity(
        opacity: isVoid ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          (isVoid
                                  ? Colors.white24
                                  : (isSold ? Colors.green : Colors.indigo))
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isVoid
                          ? Icons.auto_delete_rounded
                          : (isSold
                                ? Icons.check_circle_rounded
                                : Icons.pending_actions_rounded),
                      color: isVoid
                          ? Colors.white24
                          : (isSold
                                ? Colors.greenAccent
                                : const Color(0xFF818CF8)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName + (isVoid ? ' [VOID]' : ''),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${order.amount} × ${product.name}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TOTAL',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white24,
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        (order.amount * order.sellingPriceAtTime)
                            .toStringAsFixed(0),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (!isVoid) ...[
                    _buildBadge(
                      order.paymentMethod.name.toUpperCase(),
                      Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(
                      order.status.name.toUpperCase(),
                      isSold ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                  ] else
                    _buildBadge('VOIDED', Colors.redAccent),
                  const Spacer(),
                  if (!isVoid) ...[
                    if (isSold)
                      TextButton.icon(
                        onPressed: () => ref
                            .read(orderRepositoryProvider)
                            .updateOrderStatus(order.id, OrderStatus.pending),
                        icon: const Icon(
                          Icons.undo_rounded,
                          size: 16,
                          color: Colors.white24,
                        ),
                        label: const Text(
                          'UNDO',
                          style: TextStyle(
                            color: Colors.white24,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                        ),
                        onPressed: () => ref
                            .read(orderRepositoryProvider)
                            .updateOrderStatus(order.id, OrderStatus.sold),
                        child: const Text(
                          'FULFILL',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () =>
                          _showVoidOrderDialog(context, ref, order),
                      icon: const Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.white24,
                        size: 20,
                      ),
                      tooltip: 'Void Order',
                    ),
                  ] else
                    IconButton(
                      onPressed: () =>
                          _showRestoreOrderDialog(context, ref, order),
                      icon: const Icon(
                        Icons.restore_rounded,
                        color: Colors.greenAccent,
                        size: 20,
                      ),
                      tooltip: 'Restore Order',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        title: const Text(
          'RESTORE ORDER?',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        content: const Text(
          'Do you want to bring this order back into your active list and calculations?',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(orderRepositoryProvider).unvoidOrder(order.id);
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

  void _showVoidOrderDialog(
    BuildContext context,
    WidgetRef ref,
    CustomerOrder order,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'VOID ORDER?',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        content: const Text(
          'This will hide the order from your daily list. You can restore it later by toggling "Show Archived" in the top menu.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
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
