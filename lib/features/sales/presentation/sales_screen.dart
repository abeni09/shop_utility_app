import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/features/products/data/stock_adjustment_model.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/main.dart';
import 'package:isar/isar.dart';
import 'package:shopsync/core/utils/receipt_share_service.dart';

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

final allTimeSalesProvider = StreamProvider<List<CustomerOrder>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.isar.customerOrders
      .filter()
      .statusEqualTo(OrderStatus.sold)
      .isVoidEqualTo(false)
      .watch(fireImmediately: true);
});

final dailyAdjustmentsProvider = StreamProvider<List<StockAdjustment>>((ref) {
  final date = ref.watch(selectedSalesDateProvider);
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = startOfDay
      .add(const Duration(days: 1))
      .subtract(const Duration(milliseconds: 1));

  final dbService = ref.watch(databaseServiceProvider);
  return dbService.isar.stockAdjustments
      .filter()
      .dateBetween(startOfDay, endOfDay)
      .amountLessThan(0)
      .watch(fireImmediately: true);
});

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedSalesDateProvider);
    final salesAsync = ref.watch(dailySalesProvider);
    final adjustmentsAsync = ref.watch(dailyAdjustmentsProvider);
    final productsAsync = ref.watch(productsProvider);
    final dailyStockAsync = ref.watch(dailyStockProvider(selectedDate));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar.large(
                  backgroundColor: Colors.transparent,
                  title: const Text('SALES HISTORY'),
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF6366F1),
                    indicatorWeight: 2.5,
                    labelColor: const Color(0xFF818CF8),
                    unselectedLabelColor: Colors.white30,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                    tabs: const [
                      Tab(text: 'LOGS'),
                      Tab(text: 'ANALYSIS'),
                    ],
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                          color: Color(0xFFEF4444),
                        ),
                        onPressed: () => _showRecordLossDialog(context, ref),
                        tooltip: 'Record Loss',
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.calendar_today_rounded,
                          color: Theme.of(context).colorScheme.primary,
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
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              salesAsync.when(
                                data: (sales) {
                                  final totalRevenue = sales.fold<double>(
                                    0,
                                    (sum, item) =>
                                        sum +
                                        (item.amount * item.sellingPriceAtTime),
                                  );
                                  return _buildSummaryCard(
                                    'REVENUE',
                                    totalRevenue.toStringAsFixed(0),
                                    const Color(0xFF10B981),
                                    Icons.payments_rounded,
                                  );
                                },
                                loading: () => _buildSummaryCard(
                                  'REVENUE',
                                  '...',
                                  Colors.grey,
                                  Icons.payments_rounded,
                                ),
                                error: (_, _) => _buildSummaryCard(
                                  'REVENUE',
                                  'ERR',
                                  Colors.redAccent,
                                  Icons.payments_rounded,
                                ),
                              ),
                              const SizedBox(width: 16),
                              salesAsync.when(
                                data: (sales) {
                                  return adjustmentsAsync.when(
                                    data: (adjustments) => productsAsync.when(
                                      data: (products) {
                                        final totalProfitFromSales = sales
                                            .fold<double>(
                                              0,
                                              (sum, item) =>
                                                  sum +
                                                  (item.amount *
                                                      (item.sellingPriceAtTime -
                                                          item.costPriceAtTime)),
                                            );

                                        double totalLoss = 0.0;
                                        for (var adj in adjustments) {
                                          final p = products.firstWhere(
                                            (prod) => prod.id == adj.productId,
                                            orElse: () => Product(),
                                          );
                                          totalLoss +=
                                              adj.amount.abs() * p.costPrice;
                                        }

                                        final netProfit =
                                            totalProfitFromSales - totalLoss;
                                        return _buildSummaryCard(
                                          'NET PROFIT',
                                          netProfit.toStringAsFixed(0),
                                          const Color(0xFF818CF8),
                                          Icons.trending_up_rounded,
                                        );
                                      },
                                      loading: () => _buildSummaryCard(
                                        'NET PROFIT',
                                        '...',
                                        Colors.grey,
                                        Icons.trending_up_rounded,
                                      ),
                                      error: (_, _) => _buildSummaryCard(
                                        'NET PROFIT',
                                        'ERR',
                                        Colors.redAccent,
                                        Icons.trending_up_rounded,
                                      ),
                                    ),
                                    loading: () => _buildSummaryCard(
                                      'NET PROFIT',
                                      '...',
                                      Colors.grey,
                                      Icons.trending_up_rounded,
                                    ),
                                    error: (_, _) => _buildSummaryCard(
                                      'NET PROFIT',
                                      'ERR',
                                      Colors.redAccent,
                                      Icons.trending_up_rounded,
                                    ),
                                  );
                                },
                                loading: () => _buildSummaryCard(
                                  'NET PROFIT',
                                  '...',
                                  Colors.grey,
                                  Icons.trending_up_rounded,
                                ),
                                error: (_, _) => _buildSummaryCard(
                                  'NET PROFIT',
                                  'ERR',
                                  Colors.redAccent,
                                  Icons.trending_up_rounded,
                                ),
                              ),
                              const SizedBox(width: 16),
                              adjustmentsAsync.when(
                                data: (adjustments) => productsAsync.when(
                                  data: (products) {
                                    double totalLoss = 0.0;
                                    for (var adj in adjustments) {
                                      final p = products.firstWhere(
                                        (prod) => prod.id == adj.productId,
                                        orElse: () => Product(),
                                      );
                                      totalLoss +=
                                          adj.amount.abs() * p.costPrice;
                                    }
                                    return _buildSummaryCard(
                                      'LOSSES',
                                      totalLoss.toStringAsFixed(0),
                                      const Color(0xFFEF4444),
                                      Icons.trending_down_rounded,
                                    );
                                  },
                                  loading: () => _buildSummaryCard(
                                    'LOSSES',
                                    '...',
                                    Colors.grey,
                                    Icons.trending_down_rounded,
                                  ),
                                  error: (_, _) => _buildSummaryCard(
                                    'LOSSES',
                                    'ERR',
                                    Colors.redAccent,
                                    Icons.trending_down_rounded,
                                  ),
                                ),
                                loading: () => _buildSummaryCard(
                                  'LOSSES',
                                  '...',
                                  Colors.grey,
                                  Icons.trending_down_rounded,
                                ),
                                error: (_, _) => _buildSummaryCard(
                                  'LOSSES',
                                  'ERR',
                                  Colors.redAccent,
                                  Icons.trending_down_rounded,
                                ),
                              ),
                              const SizedBox(width: 16),
                              dailyStockAsync.when(
                                data: (stocks) => productsAsync.when(
                                  data: (products) {
                                    double totalStockReceivedCost = 0.0;
                                    for (var stock in stocks) {
                                      final p = products.firstWhere(
                                        (prod) => prod.id == stock.productId,
                                        orElse: () => Product(),
                                      );
                                      totalStockReceivedCost +=
                                          stock.receivedQuantity * p.costPrice;
                                    }
                                    return _buildSummaryCard(
                                      'STOCK RECEIVED',
                                      totalStockReceivedCost.toStringAsFixed(0),
                                      const Color(0xFFF59E0B),
                                      Icons.local_shipping_rounded,
                                    );
                                  },
                                  loading: () => _buildSummaryCard(
                                    'STOCK RECEIVED',
                                    '...',
                                    Colors.grey,
                                    Icons.local_shipping_rounded,
                                  ),
                                  error: (_, _) => _buildSummaryCard(
                                    'STOCK RECEIVED',
                                    'ERR',
                                    Colors.redAccent,
                                    Icons.local_shipping_rounded,
                                  ),
                                ),
                                loading: () => _buildSummaryCard(
                                  'STOCK RECEIVED',
                                  '...',
                                  Colors.grey,
                                  Icons.local_shipping_rounded,
                                ),
                                error: (_, _) => _buildSummaryCard(
                                  'STOCK RECEIVED',
                                  'ERR',
                                  Colors.redAccent,
                                  Icons.local_shipping_rounded,
                                ),
                              ),
                            ],
                          ),
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
                    final horizontalPadding = width > 1200
                        ? width * 0.1
                        : (width > 800 ? 48.0 : 24.0);
                    final crossAxisCount = width > 1000
                        ? 3
                        : (width > 600 ? 2 : 1);

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
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            sliver: crossAxisCount > 1
                                ? SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          mainAxisSpacing: 16,
                                          crossAxisSpacing: 16,
                                          mainAxisExtent: 140,
                                        ),
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final sale = sales[index];
                                      return productsAsync.when(
                                        data: (products) {
                                          final product = products.firstWhere(
                                            (p) => p.id == sale.productId,
                                            orElse: () =>
                                                Product()..name = 'Unknown',
                                          );
                                          return _SaleTile(
                                            sale: sale,
                                            productName: product.name,
                                          );
                                        },
                                        loading: () => const SizedBox.shrink(),
                                        error: (_, _) =>
                                            const SizedBox.shrink(),
                                      );
                                    }, childCount: sales.length),
                                  )
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final sale = sales[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: productsAsync.when(
                                          data: (products) {
                                            final product = products.firstWhere(
                                              (p) => p.id == sale.productId,
                                              orElse: () =>
                                                  Product()..name = 'Unknown',
                                            );
                                            return _SaleTile(
                                              sale: sale,
                                              productName: product.name,
                                            );
                                          },
                                          loading: () =>
                                              const SizedBox.shrink(),
                                          error: (_, _) =>
                                              const SizedBox.shrink(),
                                        ),
                                      );
                                    }, childCount: sales.length),
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
                  error: (err, _) => SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Text(
                      'INVENTORY LOSSES',
                      style: TextStyle(
                        letterSpacing: 2.5,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),

                adjustmentsAsync.when(
                  data: (adjustments) {
                    final width = MediaQuery.of(context).size.width;
                    final horizontalPadding = width > 1200
                        ? width * 0.1
                        : (width > 800 ? 48.0 : 24.0);
                    final crossAxisCount = width > 1000
                        ? 3
                        : (width > 600 ? 2 : 1);

                    return adjustments.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No inventory losses recorded for this date.',
                                  style: TextStyle(
                                    color: Colors.white24,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            sliver: crossAxisCount > 1
                                ? SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          mainAxisSpacing: 16,
                                          crossAxisSpacing: 16,
                                          mainAxisExtent: 140,
                                        ),
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final adj = adjustments[index];
                                      return productsAsync.when(
                                        data: (products) {
                                          final product = products.firstWhere(
                                            (p) => p.id == adj.productId,
                                            orElse: () =>
                                                Product()..name = 'Unknown',
                                          );
                                          return _LossTile(
                                            adjustment: adj,
                                            productName: product.name,
                                            costPrice: product.costPrice,
                                          );
                                        },
                                        loading: () => const SizedBox.shrink(),
                                        error: (_, _) =>
                                            const SizedBox.shrink(),
                                      );
                                    }, childCount: adjustments.length),
                                  )
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final adj = adjustments[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: productsAsync.when(
                                          data: (products) {
                                            final product = products.firstWhere(
                                              (p) => p.id == adj.productId,
                                              orElse: () =>
                                                  Product()..name = 'Unknown',
                                            );
                                            return _LossTile(
                                              adjustment: adj,
                                              productName: product.name,
                                              costPrice: product.costPrice,
                                            );
                                          },
                                          loading: () =>
                                              const SizedBox.shrink(),
                                          error: (_, _) =>
                                              const SizedBox.shrink(),
                                        ),
                                      );
                                    }, childCount: adjustments.length),
                                  ),
                          );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  error: (err, _) => SliverToBoxAdapter(
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
          // Analysis tab overlay
          if (_tabController.index == 1)
            Positioned.fill(
              child: _SalesAnalysisTab(
                selectedDate: selectedDate,
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
    width: 160,
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

  void _showShareMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SHARE RECEIPT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 12,
                color: Color(0xFF818CF8),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.text_fields_rounded,
                color: Colors.white70,
              ),
              title: const Text(
                'Share as Text Message',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ReceiptShareService.shareTextReceipt(
                  order: sale,
                  productName: productName,
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white70,
              ),
              title: const Text(
                'Share as PDF Document',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ReceiptShareService.sharePdfReceipt(
                  order: sale,
                  productName: productName,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
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
                  await ref.read(orderRepositoryProvider).voidOrder(sale.id);
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
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              Colors.white.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
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
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.share_rounded,
                color: Colors.white30,
                size: 18,
              ),
              tooltip: 'Share Receipt',
              onPressed: () => _showShareMenu(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _LossTile extends ConsumerWidget {
  final StockAdjustment adjustment;
  final String productName;
  final double costPrice;

  const _LossTile({
    required this.adjustment,
    required this.productName,
    required this.costPrice,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lossCost = adjustment.amount.abs() * costPrice;
    final isDamage = adjustment.reason.toLowerCase() == 'damage';

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
              'DELETE RECORDED LOSS?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.5,
                color: Color(0xFFEF4444),
              ),
            ),
            content: const Text(
              'This will permanently delete this loss record and restore the quantity to inventory.',
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
                  await ref
                      .read(stockAdjustmentRepositoryProvider)
                      .deleteAdjustment(adjustment.id);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'DELETE',
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEF4444).withValues(alpha: 0.03),
              Colors.white.withValues(alpha: 0.01),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          ),
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
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDamage
                    ? Icons.broken_image_rounded
                    : Icons.person_remove_rounded,
                color: const Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adjustment.reason.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.0,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${adjustment.amount.abs().toStringAsFixed(1)} units lost',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '-${lossCost.toStringAsFixed(0)} ETB',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFFEF4444),
                  ),
                ),
                Text(
                  '@ \$${costPrice.toStringAsFixed(2)} cost',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
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

void _showRecordLossDialog(BuildContext context, WidgetRef ref) {
  final productsAsync = ref.read(productsProvider);
  final products = productsAsync.value ?? [];

  int? selectedProductId;
  String selectedReason = 'Damage';
  final quantityController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            title: const Text(
              'RECORD INVENTORY LOSS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.5,
                color: Color(0xFFEF4444),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRODUCT',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedProductId,
                      dropdownColor: const Color(0xFF0F172A),
                      isExpanded: true,
                      hint: const Text(
                        'Select Product',
                        style: TextStyle(color: Colors.white30, fontSize: 14),
                      ),
                      items: products.map((p) {
                        return DropdownMenuItem<int>(
                          value: p.id,
                          child: Text(
                            p.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => selectedProductId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'LOSS REASON',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedReason,
                      dropdownColor: const Color(0xFF0F172A),
                      isExpanded: true,
                      items: ['Damage', 'Self-Consumption'].map((r) {
                        return DropdownMenuItem<String>(
                          value: r,
                          child: Text(
                            r,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => selectedReason = val ?? 'Damage'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'QUANTITY LOST',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. 5',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFEF4444)),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(
                    color: Colors.white30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final qty = double.tryParse(quantityController.text);
                  if (selectedProductId == null || qty == null || qty <= 0) {
                    return;
                  }

                  final adj = StockAdjustment()
                    ..productId = selectedProductId!
                    ..date = ref.read(selectedSalesDateProvider)
                    ..amount = -qty
                    ..reason = selectedReason.toLowerCase();

                  await ref
                      .read(stockAdjustmentRepositoryProvider)
                      .saveAdjustment(adj);

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'RECORD',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

// ─── Analysis Tab ──────────────────────────────────────────────────────────────

class _SalesAnalysisTab extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  const _SalesAnalysisTab({required this.selectedDate});

  @override
  ConsumerState<_SalesAnalysisTab> createState() => _SalesAnalysisTabState();
}

class _SalesAnalysisTabState extends ConsumerState<_SalesAnalysisTab> {
  bool _showAllTime = false;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final allTimeAsync = ref.watch(allTimeSalesProvider);
    final dailyAsync = ref.watch(dailySalesProvider);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Top spacer to match SliverAppBar.large height
          SizedBox(height: MediaQuery.of(context).padding.top + 160),
          // Toggle Row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                const Text(
                  'PROFITABILITY',
                  style: TextStyle(
                    color: Colors.white24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _toggleChip('TODAY', !_showAllTime, () => setState(() => _showAllTime = false)),
                      _toggleChip('ALL TIME', _showAllTime, () => setState(() => _showAllTime = true)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final salesAsync = _showAllTime ? allTimeAsync : dailyAsync;
                return salesAsync.when(
                  data: (orders) {
                    // Build per-product profitability data
                    final Map<int, _ProductProfitData> profitMap = {};
                    for (final o in orders) {
                      if (_showAllTime || _isSameDay(o.fulfilledAt ?? o.dueDate, widget.selectedDate)) {
                        profitMap.putIfAbsent(o.productId, () => _ProductProfitData());
                        final data = profitMap[o.productId]!;
                        data.revenue += o.amount * o.sellingPriceAtTime;
                        data.cogs += o.amount * o.costPriceAtTime;
                        data.unitsSold += o.amount;
                      }
                    }

                    // Merge with product info and compute margin
                    final List<_ProductMarginEntry> entries = [];
                    for (final p in products) {
                      if (p.isVoid) continue;
                      final data = profitMap[p.id];
                      if (data == null || data.unitsSold == 0) continue;
                      final grossProfit = data.revenue - data.cogs;
                      final margin = data.revenue > 0 ? (grossProfit / data.revenue) * 100 : 0.0;
                      entries.add(_ProductMarginEntry(
                        product: p,
                        revenue: data.revenue,
                        grossProfit: grossProfit,
                        marginPct: margin,
                        unitsSold: data.unitsSold,
                      ));
                    }

                    // Sort by gross profit descending
                    entries.sort((a, b) => b.grossProfit.compareTo(a.grossProfit));

                    if (entries.isEmpty) {
                      return const Center(
                        child: Text(
                          'No sales data to analyze.',
                          style: TextStyle(color: Colors.white24),
                        ),
                      );
                    }

                    final maxRevenue = entries.fold(0.0, (m, e) => m > e.revenue ? m : e.revenue);

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _ProductMarginTile(
                          entry: entries[index],
                          rank: index + 1,
                          maxRevenue: maxRevenue,
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
                  error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _toggleChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white30,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class _ProductProfitData {
  double revenue = 0.0;
  double cogs = 0.0;
  double unitsSold = 0.0;
}

class _ProductMarginEntry {
  final Product product;
  final double revenue;
  final double grossProfit;
  final double marginPct;
  final double unitsSold;
  _ProductMarginEntry({
    required this.product,
    required this.revenue,
    required this.grossProfit,
    required this.marginPct,
    required this.unitsSold,
  });
}

class _ProductMarginTile extends StatelessWidget {
  final _ProductMarginEntry entry;
  final int rank;
  final double maxRevenue;

  const _ProductMarginTile({
    required this.entry,
    required this.rank,
    required this.maxRevenue,
  });

  Color get _marginColor {
    if (entry.marginPct >= 30) return const Color(0xFF10B981);
    if (entry.marginPct >= 15) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get _marginLabel {
    if (entry.marginPct >= 30) return 'HIGH';
    if (entry.marginPct >= 15) return 'MED';
    return 'LOW';
  }

  @override
  Widget build(BuildContext context) {
    final barFraction = maxRevenue > 0 ? (entry.revenue / maxRevenue).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _marginColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: _marginColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _marginColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_marginLabel ${entry.marginPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _marginColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Revenue bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barFraction,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(_marginColor.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statChip(Icons.payments_rounded, 'ETB ${entry.revenue.toStringAsFixed(0)}', Colors.white54, 'Revenue'),
              const SizedBox(width: 12),
              _statChip(Icons.trending_up_rounded, 'ETB ${entry.grossProfit.toStringAsFixed(0)}', const Color(0xFF10B981), 'Profit'),
              const SizedBox(width: 12),
              _statChip(Icons.shopping_basket_rounded, '${entry.unitsSold.toStringAsFixed(0)} units', Colors.white38, 'Sold'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
