import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/orders/data/requisition_service.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';

final requisitionServiceProvider = Provider<RequisitionService>((ref) {
  return RequisitionService(
    orderRepo: ref.watch(orderRepositoryProvider),
    productRepo: ref.watch(productRepositoryProvider),
  );
});

final tomorrowRequisitionProvider = FutureProvider<List<RequisitionItem>>((
  ref,
) async {
  return ref.watch(requisitionServiceProvider).calculateTomorrowRequisition();
});

class RequisitionScreen extends ConsumerWidget {
  const RequisitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requisitionAsync = ref.watch(tomorrowRequisitionProvider);
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evening Order List'),
        // title: Text('For: ${DateFormat('EEEE, MMM dd').format(tomorrow)}'),
      ),
      body: requisitionAsync.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('No orders recorded for tomorrow yet.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Orders: ${item.orderAmount} ${item.product.unit}',
                                ),
                                Text(
                                  'Buffer (10%): ${item.bufferAmount.toStringAsFixed(1)} ${item.product.unit}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'TOTAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  item.totalNeeded.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
