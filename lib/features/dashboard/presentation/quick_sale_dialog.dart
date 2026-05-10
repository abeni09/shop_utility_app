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
  final Map<int, bool> _addBag = {};
  final TextEditingController _customerController = TextEditingController(text: 'Walk-in');
  int? _selectedBagId;

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var products = ref.watch(productsProvider).value ?? [];
    products = products.where((p) => !p.isVoid).toList();

    // Find all "Bag" products
    final bagProducts = products.where((p) {
      final name = p.name.toLowerCase();
      return name.contains('bag') || name.contains('festal');
    }).toList();

    // Initialize selected bag if not set
    if (_selectedBagId == null && bagProducts.isNotEmpty) {
      _selectedBagId = bagProducts.first.id;
    }

    final currentBag = bagProducts.where((p) => p.id == _selectedBagId).firstOrNull;

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
            TextField(
              controller: _customerController,
              decoration: InputDecoration(
                hintText: 'Customer Name (Optional)',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'QUICK SALE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 14,
                    color: Color(0xFF818CF8),
                  ),
                ),
                if (bagProducts.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedBagId,
                        dropdownColor: const Color(0xFF1E293B),
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white38),
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        onChanged: (val) => setState(() => _selectedBagId = val),
                        items: bagProducts.map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name.toUpperCase()),
                        )).toList(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              bagProducts.isNotEmpty 
                ? 'Bundle with ${currentBag?.name ?? "Bag"} to fulfill instantly.'
                : 'Select a product and quantity for instant fulfillment.',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
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
                        return _buildQuickSaleTile(product, currentBag, bagProducts);
                      },
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSaleTile(dynamic product, dynamic bagProduct, List<dynamic> allBagProducts) {
    final quantity = _quantities[product.id] ?? 1.0;
    final hasBag = _addBag[product.id] ?? false;
    final isAnyBag = allBagProducts.any((p) => p.id == product.id);

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
              if (!isAnyBag && bagProduct != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      Icons.shopping_bag_rounded,
                      color: hasBag ? const Color(0xFFFACC15) : Colors.white10,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _addBag[product.id] = !hasBag);
                    },
                    tooltip: 'Add Bag',
                  ),
                ),
              _IconButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  if (quantity > 1) {
                    setState(() => _quantities[product.id] = quantity - 1);
                  }
                },
              ),
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text(
                  quantity.toStringAsFixed(0),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
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
                onPressed: () => _processSale(product, quantity, hasBag ? bagProduct : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF818CF8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'SELL',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _processSale(dynamic product, double quantity, dynamic bagProduct) async {
    final now = DateTime.now();

    // 1. Process the main product sale
    final customerName = _customerController.text.trim();
    final totalPrice = quantity * product.sellingPrice;
    final order = CustomerOrder()
      ..productId = product.id
      ..customerName = customerName.isEmpty ? "Walk-in Customer" : customerName
      ..amount = quantity
      ..dueDate = now
      ..status = OrderStatus.sold
      ..paymentMethod = PaymentMethod.cash
      ..costPriceAtTime = product.costPrice
      ..sellingPriceAtTime = product.sellingPrice
      ..advancePayment = totalPrice
      ..fulfilledAt = now;

    print('DEBUG: QuickSale processing. Name: ${order.customerName}');
    await ref.read(orderRepositoryProvider).saveOrder(order);

    // 2. Process the bag sale if selected
    if (bagProduct != null) {
      final bagOrder = CustomerOrder()
        ..productId = bagProduct.id
        ..customerName = "Walk-in Customer"
        ..amount = 1.0
        ..dueDate = now
        ..status = OrderStatus.sold
        ..paymentMethod = PaymentMethod.cash
        ..costPriceAtTime = bagProduct.costPrice
        ..sellingPriceAtTime = bagProduct.sellingPrice
        ..advancePayment = bagProduct.sellingPrice
        ..fulfilledAt = now;

      await ref.read(orderRepositoryProvider).saveOrder(bagOrder);
    }

    if (mounted) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Sale processed: ${quantity.toStringAsFixed(0)} ${product.name}${bagProduct != null ? ' + Bag' : ''}',
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
