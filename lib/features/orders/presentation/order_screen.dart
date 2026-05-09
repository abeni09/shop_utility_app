import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';

class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Orders: ${DateFormat('MMM dd').format(selectedDate)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                ref.read(selectedDateProvider.notifier).state = date;
              }
            },
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) => orders.isEmpty
            ? const Center(child: Text('No orders for this date'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _OrderCard(order: order);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOrderDialog(context, ref),
        child: const Icon(Icons.add_shopping_cart),
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Customer Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedProductId,
                  items: products
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => selectedProductId = val),
                  decoration: const InputDecoration(labelText: 'Product'),
                ),
                TextField(
                  controller: customerController,
                  decoration: const InputDecoration(labelText: 'Customer Name'),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<PaymentMethod>(
                  initialValue: selectedPayment,
                  items: PaymentMethod.values
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => selectedPayment = val!),
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                  ),
                ),
                ListTile(
                  title: Text(
                    'Due: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                  ),
                  trailing: const Icon(Icons.calendar_month),
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
              child: const Text('Create Order'),
            ),
          ],
        ),
      ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSold
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          order.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${order.amount} x ${product.name}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildBadge(
                  order.paymentMethod.name.toUpperCase(),
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildBadge(
                  order.status.name.toUpperCase(),
                  isSold ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ],
        ),
        trailing: isSold
            ? IconButton(
                icon: const Icon(Icons.undo, color: Colors.grey),
                onPressed: () => ref
                    .read(orderRepositoryProvider)
                    .updateOrderStatus(order.id, OrderStatus.pending),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => ref
                    .read(orderRepositoryProvider)
                    .updateOrderStatus(order.id, OrderStatus.sold),
                child: const Text('FULFILL'),
              ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
