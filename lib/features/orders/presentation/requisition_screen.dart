import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/products/data/daily_stock_model.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/features/suppliers/presentation/supplier_list_screen.dart';

class RequisitionItem {
  final dynamic product;
  final double orderAmount;
  final double bufferAmount;

  RequisitionItem({
    required this.product,
    required this.orderAmount,
    required this.bufferAmount,
  });

  double get totalNeeded => orderAmount + bufferAmount;
}

class RequisitionScreen extends ConsumerStatefulWidget {
  const RequisitionScreen({super.key});

  @override
  ConsumerState<RequisitionScreen> createState() => _RequisitionScreenState();
}

class _RequisitionScreenState extends ConsumerState<RequisitionScreen> {
  final Map<int, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final productsAsync = ref.watch(productsProvider);
    final ordersAsync = ref.watch(ordersForDateProvider((date: tomorrow, includeVoided: false)));
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: productsAsync.when(
        data: (products) => ordersAsync.when(
          data: (orders) {
            // Calculate base needs
            final Map<int, double> preOrderTotals = {};
            for (var order in orders) {
              if (order.status == OrderStatus.pending && !order.isVoid) {
                preOrderTotals[order.productId] = (preOrderTotals[order.productId] ?? 0.0) + order.amount;
              }
            }

            final activeProducts = products.where((p) => !p.isVoid).toList();
            final items = activeProducts.map((p) {
              final preOrder = preOrderTotals[p.id] ?? 0.0;
              final suggested = preOrder + (preOrder * 0.1);
              
              if (!_controllers.containsKey(p.id)) {
                _controllers[p.id] = TextEditingController(
                  text: suggested > 0 ? suggested.toStringAsFixed(1) : '',
                );
              }
              
              return RequisitionItem(
                product: p,
                orderAmount: preOrder,
                bufferAmount: preOrder * 0.1,
              );
            }).toList();

            return CustomScrollView(
              slivers: [
                _buildAppBar(),
                _buildHeader(),
                _buildSupplierGroups(items, suppliersAsync.value ?? []),
                _buildPlaceOrderButton(activeProducts),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
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
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          'Review and adjust quantities to order from suppliers for tomorrow.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSupplierGroups(List<RequisitionItem> items, List<dynamic> suppliers) {
    final Map<int?, List<RequisitionItem>> grouped = {};
    for (var item in items) {
      final sid = item.product.supplierId;
      grouped[sid] ??= [];
      grouped[sid]!.add(item);
    }

    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final supplierId = grouped.keys.elementAt(index);
          final supplierItems = grouped[supplierId]!;
          final supplierName = suppliers.where((s) => s.id == supplierId).firstOrNull?.name ?? 'Unassigned Supplier';

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
              ...supplierItems.map((item) => _buildRequisitionCard(item)),
              const SizedBox(height: 24),
            ],
          );
        }, childCount: grouped.keys.length),
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
                if (item.orderAmount > 0) ...[
                  Text(
                    'Pre-orders: ${item.orderAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Buffer (10%): +${item.bufferAmount.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                ] else
                  Text(
                    'No pre-orders',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _controllers[item.product.id],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: Colors.white10),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(List<dynamic> activeProducts) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: const Color(0xFF38BDF8).withValues(alpha: 0.4),
            ),
            onPressed: () => _placeOrder(activeProducts),
            child: const Text(
              'PLACE ORDER TO SUPPLIERS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(List<dynamic> activeProducts) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final repo = ref.read(dailyStockRepositoryProvider);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      for (var p in activeProducts) {
        final text = _controllers[p.id]?.text.trim() ?? '';
        final amount = double.tryParse(text) ?? 0.0;
        
        if (amount > 0) {
          var stock = await repo.getStockForProduct(p.id, tomorrow);
          stock ??= DailyStock()
            ..productId = p.id
            ..date = tomorrow;
          
          stock.requestedQuantity = amount;
          await repo.saveDailyStock(stock);
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully for tomorrow!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }
}
