import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final ordersAsync = ref.watch(
      ordersForDateProvider((date: _selectedDate, includeVoided: false)),
    );
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
                preOrderTotals[order.productId] =
                    (preOrderTotals[order.productId] ?? 0.0) + order.amount;
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

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    _buildHeader(),
                    _buildSupplierGroups(items, suppliersAsync.value ?? []),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
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
    final isToday = _selectedDate.day == DateTime.now().day;
    final isTomorrow = _selectedDate.day == DateTime.now().day + 1;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ORDER QUANTITIES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF818CF8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review needs for ${isToday ? "today" : isTomorrow ? "tomorrow" : DateFormat('MMM dd').format(_selectedDate)}',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
                // Date Selector
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 14)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate =
                            DateTime(date.year, date.month, date.day);
                        _controllers.clear();
                      });
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isTomorrow
                            ? const Color(0xFF818CF8).withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 16,
                          color: isTomorrow
                              ? const Color(0xFF818CF8)
                              : Colors.amberAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isToday
                              ? 'TODAY'
                              : isTomorrow
                                  ? 'TOMORROW'
                                  : DateFormat('MMM dd').format(_selectedDate),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: isTomorrow
                                ? const Color(0xFF818CF8)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierGroups(
    List<RequisitionItem> items,
    List<dynamic> suppliers,
  ) {
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
          final supplierName =
              suppliers.where((s) => s.id == supplierId).firstOrNull?.name ??
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
                  borderSide: const BorderSide(
                    color: Color(0xFF38BDF8),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(List<dynamic> activeProducts) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _placeOrder(activeProducts),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF38BDF8),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: const Text(
            'PLACE ORDER TO SUPPLIERS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(List<dynamic> products) async {
    final repo = ref.read(dailyStockRepositoryProvider);

    try {
      for (var p in products) {
        final amount = double.tryParse(_controllers[p.id]?.text ?? '0') ?? 0.0;
        if (amount > 0) {
          DailyStock? stock = await repo.getStockForProduct(
            p.id,
            _selectedDate,
          );

          stock ??= DailyStock()
            ..productId = p.id
            ..date = _selectedDate;

          stock.requestedQuantity = amount;
          stock.supplierId = p.supplierId;
          await repo.saveDailyStock(stock);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order placed successfully for ${DateFormat('MMM dd').format(_selectedDate)}!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
