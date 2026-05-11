import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/features/orders/presentation/order_screen.dart';

final selectedSalesDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final dailySalesProvider = StreamProvider<List<CustomerOrder>>((ref) {
  final date = ref.watch(selectedSalesDateProvider);
  final repository = ref.watch(orderRepositoryProvider);

  // We want to watch ALL orders for this date that are SOLD and not VOID
  return repository.watchOrdersForDate(date, includeVoided: false).map((
    orders,
  ) {
    return orders.where((o) => o.status == OrderStatus.sold).toList();
  });
});

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedSalesDateProvider);
    final salesAsync = ref.watch(dailySalesProvider);
    final productsAsync = ref.watch(productsProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF020617)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.05),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar.large(
                  backgroundColor: Colors.transparent,
                  title: const Text('SALES HISTORY'),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          color: Color(0xFF818CF8),
                        ),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            ref.read(selectedSalesDateProvider.notifier).state =
                                date;
                          }
                        },
                      ),
                    ),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'EEEE, MMM dd yyyy',
                          ).format(selectedDate).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF818CF8),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),
                        salesAsync.when(
                          data: (sales) {
                            final totalRevenue = sales.fold<double>(
                              0,
                              (sum, item) =>
                                  sum + (item.amount * item.sellingPriceAtTime),
                            );
                            final totalProfit = sales.fold<double>(
                              0,
                              (sum, item) =>
                                  sum +
                                  (item.amount *
                                      (item.sellingPriceAtTime -
                                          item.costPriceAtTime)),
                            );

                            return Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    'REVENUE',
                                    '${totalRevenue.toStringAsFixed(0)}',
                                    const Color(0xFF10B981),
                                    Icons.payments_rounded,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'PROFIT',
                                    '${totalProfit.toStringAsFixed(0)}',
                                    const Color(0xFF818CF8),
                                    Icons.trending_up_rounded,
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'TRANSACTIONS',
                          style: TextStyle(
                            letterSpacing: 2.5,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                salesAsync.when(
                  data: (sales) {
                    final width = MediaQuery.of(context).size.width;
                    final horizontalPadding = width > 1200 ? width * 0.1 : (width > 800 ? 48.0 : 24.0);
                    final crossAxisCount = width > 1000 ? 3 : (width > 600 ? 2 : 1);

                    return sales.isEmpty
                        ? const SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'No sales recorded for this date.',
                                style: TextStyle(color: Colors.white24),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            sliver: crossAxisCount > 1
                                ? SliverGrid(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      mainAxisExtent: 140,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final sale = sales[index];
                                        return productsAsync.when(
                                          data: (products) {
                                            final product = products.firstWhere(
                                              (p) => p.id == sale.productId,
                                              orElse: () => Product()..name = 'Unknown',
                                            );
                                            return _SaleTile(sale: sale, productName: product.name);
                                          },
                                          loading: () => const SizedBox.shrink(),
                                          error: (_, __) => const SizedBox.shrink(),
                                        );
                                      },
                                      childCount: sales.length,
                                    ),
                                  )
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final sale = sales[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: productsAsync.when(
                                            data: (products) {
                                              final product = products.firstWhere(
                                                (p) => p.id == sale.productId,
                                                orElse: () => Product()..name = 'Unknown',
                                              );
                                              return _SaleTile(sale: sale, productName: product.name);
                                            },
                                            loading: () => const SizedBox.shrink(),
                                            error: (_, __) => const SizedBox.shrink(),
                                          ),
                                        );
                                      },
                                      childCount: sales.length,
                                    ),
                                  ),
                          );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  error: (err, __) => SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildSummaryCard(
  String label,
  String value,
  Color color,
  IconData icon,
) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.02)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: color.withValues(alpha: 0.1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            Icon(icon, color: color.withValues(alpha: 0.3), size: 16),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'ETB',
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.4),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SaleTile extends ConsumerWidget {
  final CustomerOrder sale;
  final String productName;

  const _SaleTile({required this.sale, required this.productName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenue = sale.amount * sale.sellingPriceAtTime;
    final profit =
        sale.amount * (sale.sellingPriceAtTime - sale.costPriceAtTime);

    return InkWell(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            title: const Text(
              'VOID TRANSACTION?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.5,
                color: Color(0xFFEF4444),
              ),
            ),
            content: const Text(
              'This will move the transaction to voided status and remove it from profit calculations.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(
                    color: Colors.white24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(orderRepositoryProvider).voidOrder(sale.id!);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'VOID SALE',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.05),
              Colors.white.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${sale.amount.toStringAsFixed(0)} × $productName',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${revenue.toStringAsFixed(0)} ETB',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '+${profit.toStringAsFixed(0)} profit',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
