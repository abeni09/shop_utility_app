import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/orders/data/requisition_service.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/features/suppliers/presentation/supplier_list_screen.dart';

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
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'NIGHTLY REQUISITION',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2,
                  color: Color(0xFF38BDF8),
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1E293B),
                      const Color(0xFF0F172A).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Consolidated list of items needed for tomorrow\'s fulfillment, grouped by supplier.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          requisitionAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No orders recorded for tomorrow.',
                      style: TextStyle(color: Colors.white24),
                    ),
                  ),
                );
              }

              // Group items by supplier
              final Map<int?, List<RequisitionItem>> grouped = {};
              for (var item in items) {
                final sid = item.product.supplierId;
                grouped[sid] ??= [];
                grouped[sid]!.add(item);
              }

              final suppliers = suppliersAsync.value ?? [];

              return SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final supplierId = grouped.keys.elementAt(index);
                    final supplierItems = grouped[supplierId]!;
                    final supplierName =
                        suppliers
                            .where((s) => s.id == supplierId)
                            .firstOrNull
                            ?.name ??
                        'Unassigned Supplier';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 12),
                          child: Text(
                            supplierName.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF818CF8),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        ...supplierItems.map(
                          (item) => _buildRequisitionCard(item),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }, childCount: grouped.keys.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),
        ],
      ),
    );
  }

  Widget _buildRequisitionCard(RequisitionItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current Orders: ${item.orderAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Safety Buffer (10%): +${item.bufferAmount.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  item.totalNeeded.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
