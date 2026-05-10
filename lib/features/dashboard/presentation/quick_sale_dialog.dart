import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';

// class QuickSaleDialog extends ConsumerWidget {
//   const QuickSaleDialog({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final products = ref.watch(productsProvider).value ?? [];

class QuickSaleDialog extends ConsumerStatefulWidget {
  const QuickSaleDialog({super.key});

  @override
  ConsumerState<QuickSaleDialog> createState() => _QuickSaleDialogState();
}

class _QuickSaleDialogState extends ConsumerState<QuickSaleDialog> {
  final Map<int, double> _quantities = {};

  @override
  Widget build(BuildContext context) {
    var products = ref.watch(productsProvider).value ?? [];
    products = products.where((p) => !p.isVoid).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'QUICK SALE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 14,
                color: Color(0xFF818CF8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select a product and quantity for instant fulfillment.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: products.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No products in stock.',
                          style: TextStyle(color: Colors.white24),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _buildQuickSaleTile(product);
                      },
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSaleTile(dynamic product) {
    final quantity = _quantities[product.id] ?? 1.0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  Text(
                    '${product.sellingPrice} ETB/unit',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _IconButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  if (quantity > 1) {
                    setState(() => _quantities[product.id] = quantity - 1);
                  }
                },
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  quantity.toStringAsFixed(0),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              _IconButton(
                icon: Icons.add_rounded,
                onTap: () {
                  setState(() => _quantities[product.id] = quantity + 1);
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _processSale(product, quantity),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF818CF8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'SELL',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _processSale(dynamic product, double quantity) async {
    final order = CustomerOrder()
      ..productId = product.id
      ..customerName = "Walk-in Customer"
      ..amount = quantity
      ..dueDate = DateTime.now()
      ..status = OrderStatus.sold
      ..paymentMethod = PaymentMethod.cash
      ..costPriceAtTime = product.costPrice
      ..sellingPriceAtTime = product.sellingPrice
      ..fulfilledAt = DateTime.now();

    await ref.read(orderRepositoryProvider).saveOrder(order);

    if (mounted) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Instant Sale: ${quantity.toStringAsFixed(0)} ${product.name}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}

//   }
// }
