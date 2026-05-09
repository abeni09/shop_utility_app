import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';

class QuickSaleDialog extends ConsumerWidget {
  const QuickSaleDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider).value ?? [];

    return AlertDialog(
      title: const Text('Quick Walk-in Sale'),
      content: SizedBox(
        width: double.maxFinite,
        child: products.isEmpty
            ? const Text('No products available. Add some in the Stock tab first!')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('${product.sellingPrice} ETB / ${product.unit}'),
                    trailing: const Icon(Icons.add_shopping_cart, color: Colors.cyan),
                    onTap: () async {
                      // Create an immediately fulfilled order for a "Walk-in"
                      final order = CustomerOrder()
                        ..productId = product.id
                        ..customerName = "Walk-in Customer"
                        ..amount = 1.0
                        ..dueDate = DateTime.now()
                        ..status = OrderStatus.sold
                        ..paymentMethod = PaymentMethod.cash
                        ..costPriceAtTime = product.costPrice
                        ..sellingPriceAtTime = product.sellingPrice
                        ..fulfilledAt = DateTime.now();

                      await ref.read(orderRepositoryProvider).saveOrder(order);
                      // Recalculate profit is handled by the repository logic
                      if (context.mounted) Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sold 1 ${product.name}!')),
                      );
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
