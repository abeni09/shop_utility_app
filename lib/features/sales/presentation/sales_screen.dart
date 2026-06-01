import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/features/products/data/stock_adjustment_model.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/features/products/data/daily_stock_model.dart';
import 'package:shopsync/main.dart';
import 'package:isar/isar.dart';
import 'package:shopsync/core/utils/receipt_share_service.dart';
import 'package:shopsync/features/expenses/data/expense_model.dart';
import 'package:shopsync/features/expenses/presentation/expense_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shopsync/features/suppliers/presentation/supplier_list_screen.dart';
import 'package:shopsync/features/suppliers/data/supplier_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_settlement_model.dart';

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

final walletDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 7)),
    end: DateTime(now.year, now.month, now.day),
  );
});

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    final expensesAsync = ref.watch(expensesStreamProvider);
    final expensesOnDate = ref.watch(expensesOnDateProvider(selectedDate));
    final totalExpenses = expensesOnDate.fold<double>(
      0.0,
      (sum, e) => sum + e.amount,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -200) {
            ref.read(selectedSalesDateProvider.notifier).state = selectedDate
                .add(const Duration(days: 1));
          } else if (details.primaryVelocity! > 200) {
            ref.read(selectedSalesDateProvider.notifier).state = selectedDate
                .subtract(const Duration(days: 1));
          }
        },
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
                        Tab(text: 'EXPENSES'),
                        Tab(text: 'ANALYSIS'),
                        Tab(text: 'WALLET'),
                      ],
                    ),
                    actions: [
                      if (_tabController.index == 0) ...[
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
                              Icons.receipt_long_rounded,
                              color: Color(0xFF10B981),
                            ),
                            onPressed: () => _shareDailyLedger(
                              context,
                              ref,
                              selectedDate,
                              salesAsync.value ?? [],
                              adjustmentsAsync.value ?? [],
                              productsAsync.value ?? [],
                            ),
                            tooltip: 'Share Daily Ledger',
                          ),
                        ),
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
                            onPressed: () =>
                                _showRecordLossDialog(context, ref),
                            tooltip: 'Record Loss',
                          ),
                        ),
                      ],
                      if (_tabController.index == 1)
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
                              Icons.add_circle_outline_rounded,
                              color: Color(0xFFF59E0B),
                            ),
                            onPressed: () => _showAddExpenseDialog(
                              context,
                              ref,
                              selectedDate,
                            ),
                            tooltip: 'Add Expense',
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
                              ref
                                      .read(selectedSalesDateProvider.notifier)
                                      .state =
                                  date;
                            }
                          },
                          tooltip: 'Select Date',
                        ),
                      ),
                    ],
                  ),

                  if (_tabController.index == 0) ...[
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
                            // 2-column summary cards grid
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final cardWidth =
                                    (constraints.maxWidth - 12) / 2;
                                Widget card(
                                  String label,
                                  String value,
                                  Color color,
                                  IconData icon,
                                ) => SizedBox(
                                  width: cardWidth,
                                  child: _buildSummaryCard(
                                    label,
                                    value,
                                    color,
                                    icon,
                                  ),
                                );

                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    salesAsync.when(
                                      data: (sales) {
                                        final totalRevenue = sales.fold<double>(
                                          0,
                                          (sum, item) =>
                                              sum +
                                              (item.amount *
                                                  item.sellingPriceAtTime),
                                        );
                                        return card(
                                          'REVENUE',
                                          totalRevenue.toStringAsFixed(0),
                                          const Color(0xFF10B981),
                                          Icons.payments_rounded,
                                        );
                                      },
                                      loading: () => card(
                                        'REVENUE',
                                        '...',
                                        Colors.grey,
                                        Icons.payments_rounded,
                                      ),
                                      error: (_, _) => card(
                                        'REVENUE',
                                        'ERR',
                                        Colors.redAccent,
                                        Icons.payments_rounded,
                                      ),
                                    ),
                                    salesAsync.when(
                                      data: (sales) => adjustmentsAsync.when(
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
                                                (prod) =>
                                                    prod.id == adj.productId,
                                                orElse: () => Product(),
                                              );
                                              totalLoss +=
                                                  adj.amount.abs() *
                                                  p.costPrice;
                                            }
                                            final operatingProfit =
                                                totalProfitFromSales -
                                                totalLoss -
                                                totalExpenses;
                                            return card(
                                              'OPERATING PROFIT',
                                              operatingProfit.toStringAsFixed(
                                                0,
                                              ),
                                              const Color(0xFF818CF8),
                                              Icons.trending_up_rounded,
                                            );
                                          },
                                          loading: () => card(
                                            'OPERATING PROFIT',
                                            '...',
                                            Colors.grey,
                                            Icons.trending_up_rounded,
                                          ),
                                          error: (_, _) => card(
                                            'OPERATING PROFIT',
                                            'ERR',
                                            Colors.redAccent,
                                            Icons.trending_up_rounded,
                                          ),
                                        ),
                                        loading: () => card(
                                          'OPERATING PROFIT',
                                          '...',
                                          Colors.grey,
                                          Icons.trending_up_rounded,
                                        ),
                                        error: (_, _) => card(
                                          'OPERATING PROFIT',
                                          'ERR',
                                          Colors.redAccent,
                                          Icons.trending_up_rounded,
                                        ),
                                      ),
                                      loading: () => card(
                                        'OPERATING PROFIT',
                                        '...',
                                        Colors.grey,
                                        Icons.trending_up_rounded,
                                      ),
                                      error: (_, _) => card(
                                        'OPERATING PROFIT',
                                        'ERR',
                                        Colors.redAccent,
                                        Icons.trending_up_rounded,
                                      ),
                                    ),
                                    expensesAsync.when(
                                      data: (_) => card(
                                        'EXPENSES',
                                        totalExpenses.toStringAsFixed(0),
                                        const Color(0xFFF59E0B),
                                        Icons.receipt_rounded,
                                      ),
                                      loading: () => card(
                                        'EXPENSES',
                                        '...',
                                        Colors.grey,
                                        Icons.receipt_rounded,
                                      ),
                                      error: (_, _) => card(
                                        'EXPENSES',
                                        'ERR',
                                        Colors.redAccent,
                                        Icons.receipt_rounded,
                                      ),
                                    ),
                                    adjustmentsAsync.when(
                                      data: (adjustments) => productsAsync.when(
                                        data: (products) {
                                          double totalLoss = 0.0;
                                          for (var adj in adjustments) {
                                            final p = products.firstWhere(
                                              (prod) =>
                                                  prod.id == adj.productId,
                                              orElse: () => Product(),
                                            );
                                            totalLoss +=
                                                adj.amount.abs() * p.costPrice;
                                          }
                                          return card(
                                            'LOSSES',
                                            totalLoss.toStringAsFixed(0),
                                            const Color(0xFFEF4444),
                                            Icons.trending_down_rounded,
                                          );
                                        },
                                        loading: () => card(
                                          'LOSSES',
                                          '...',
                                          Colors.grey,
                                          Icons.trending_down_rounded,
                                        ),
                                        error: (_, _) => card(
                                          'LOSSES',
                                          'ERR',
                                          Colors.redAccent,
                                          Icons.trending_down_rounded,
                                        ),
                                      ),
                                      loading: () => card(
                                        'LOSSES',
                                        '...',
                                        Colors.grey,
                                        Icons.trending_down_rounded,
                                      ),
                                      error: (_, _) => card(
                                        'LOSSES',
                                        'ERR',
                                        Colors.redAccent,
                                        Icons.trending_down_rounded,
                                      ),
                                    ),
                                    dailyStockAsync.when(
                                      data: (stocks) => productsAsync.when(
                                        data: (products) {
                                          double totalStockReceivedCost = 0.0;
                                          for (var stock in stocks) {
                                            final p = products.firstWhere(
                                              (prod) =>
                                                  prod.id == stock.productId,
                                              orElse: () => Product(),
                                            );
                                            totalStockReceivedCost +=
                                                stock.receivedQuantity *
                                                p.costPrice;
                                          }
                                          return card(
                                            'STOCK RECEIVED',
                                            totalStockReceivedCost
                                                .toStringAsFixed(0),
                                            const Color(0xFFF59E0B),
                                            Icons.local_shipping_rounded,
                                          );
                                        },
                                        loading: () => card(
                                          'STOCK RECEIVED',
                                          '...',
                                          Colors.grey,
                                          Icons.local_shipping_rounded,
                                        ),
                                        error: (_, _) => card(
                                          'STOCK RECEIVED',
                                          'ERR',
                                          Colors.redAccent,
                                          Icons.local_shipping_rounded,
                                        ),
                                      ),
                                      loading: () => card(
                                        'STOCK RECEIVED',
                                        '...',
                                        Colors.grey,
                                        Icons.local_shipping_rounded,
                                      ),
                                      error: (_, _) => card(
                                        'STOCK RECEIVED',
                                        'ERR',
                                        Colors.redAccent,
                                        Icons.local_shipping_rounded,
                                      ),
                                    ),
                                  ],
                                );
                              },
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
                                              final product = products
                                                  .firstWhere(
                                                    (p) =>
                                                        p.id == sale.productId,
                                                    orElse: () =>
                                                        Product()
                                                          ..name = 'Unknown',
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
                                                final product = products
                                                    .firstWhere(
                                                      (p) =>
                                                          p.id ==
                                                          sale.productId,
                                                      orElse: () =>
                                                          Product()
                                                            ..name = 'Unknown',
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
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
                                              final product = products
                                                  .firstWhere(
                                                    (p) =>
                                                        p.id == adj.productId,
                                                    orElse: () =>
                                                        Product()
                                                          ..name = 'Unknown',
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
                                                final product = products
                                                    .firstWhere(
                                                      (p) =>
                                                          p.id == adj.productId,
                                                      orElse: () =>
                                                          Product()
                                                            ..name = 'Unknown',
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
                  ] else if (_tabController.index == 1) ...[
                    // EXPENSES tab
                    _buildExpensesSliver(
                      context,
                      ref,
                      selectedDate,
                      expensesOnDate,
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ] else if (_tabController.index == 2) ...[
                    // ANALYSIS tab
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: _SalesAnalysisTab(selectedDate: selectedDate),
                    ),
                  ] else ...[
                    // WALLET tab
                    _buildWalletSliver(context, ref),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSliver(BuildContext context, WidgetRef ref) {
    final walletDataAsync = ref.watch(walletDataProvider);
    final productsAsync = ref.watch(productsProvider);

    return walletDataAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF818CF8)),
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
      data: (wallet) {
        final products = productsAsync.value ?? [];
        final totalSales = wallet.totalSales;
        final cashCollected = wallet.cashCollected;
        final creditReceivables = wallet.creditReceivables;
        final totalExpenses = wallet.totalExpenses;
        final supplierSettlements = wallet.getSupplierSettlements();
        final totalLosses = wallet.getLossesCost(products);
        final supplierDuesIncurred = wallet.getSupplierDuesIncurred(products);
        final unsoldStockValue = wallet.getUnsoldReceivedStockValue(products);

        final netCashPosition =
            cashCollected - totalExpenses - supplierSettlements;
        final netProfit =
            totalSales - wallet.cogs - totalExpenses - totalLosses;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildWalletDateRangeHeader(context, ref, wallet.range),
              const SizedBox(height: 24),
              _buildWalletOverview(
                totalSales,
                cashCollected,
                creditReceivables,
                totalExpenses,
                totalLosses,
                supplierSettlements,
                supplierDuesIncurred,
                unsoldStockValue,
                onUnsoldStockTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF1E1E38),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    builder: (context) {
                      final receivedStocks = wallet.dailyStocks
                          .where((ds) => ds.receivedQuantity > 0)
                          .toList();
                      final unsoldItemsList = <Widget>[];

                      for (var ds in receivedStocks) {
                        final prod = products.firstWhere(
                          (p) => p.id == ds.productId,
                          orElse: () => Product()
                            ..name = 'Unknown Product'
                            ..costPrice = 0.0,
                        );
                        final soldInPeriod = wallet.orders
                            .where((o) => o.productId == ds.productId)
                            .fold(0.0, (sum, o) => sum + o.amount);
                        final unsoldQty = (ds.receivedQuantity - soldInPeriod)
                            .clamp(0.0, double.infinity);

                        if (unsoldQty > 0) {
                          final suppliers =
                              ref.read(suppliersProvider).value ?? [];
                          final supName = prod.supplierId != null
                              ? suppliers
                                    .firstWhere(
                                      (sup) => sup.id == prod.supplierId,
                                      orElse: () => Supplier()
                                        ..name = 'Supplier #${prod.supplierId}',
                                    )
                                    .name
                              : 'No Supplier';

                          unsoldItemsList.add(
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF06B6D4,
                                    ).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_rounded,
                                    color: Color(0xFF06B6D4),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  prod.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  'Unsold: ${unsoldQty.toStringAsFixed(0)} / ${ds.receivedQuantity.toStringAsFixed(0)} rec. • $supName',
                                  style: const TextStyle(
                                    color: Colors.white30,
                                    fontSize: 11,
                                  ),
                                ),
                                trailing: Text(
                                  'ETB ${(unsoldQty * prod.costPrice).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Color(0xFF06B6D4),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      }

                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'UNSOLD RECEIVED STOCK',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF06B6D4,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'ETB ${unsoldStockValue.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Color(0xFF06B6D4),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Value of inventory received in this range that remains unsold on the shelves.',
                                style: TextStyle(
                                  color: Colors.white30,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (unsoldItemsList.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Text(
                                      'No unsold received stock found.',
                                      style: TextStyle(
                                        color: Colors.white24,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Flexible(
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: unsoldItemsList,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildWalletNetPositions(netCashPosition, netProfit),
              const SizedBox(height: 32),
              _buildWalletDetailsSection(context, ref, wallet, products),
              const SizedBox(height: 120),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildWalletDateRangeHeader(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange range,
  ) {
    final df = DateFormat('MMM dd, yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WALKING WALLET PERIOD',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${df.format(range.start)} - ${df.format(range.end)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
                initialDateRange: range,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF6366F1),
                        onPrimary: Colors.white,
                        surface: Color(0xFF1E1E38),
                        onSurface: Colors.white,
                      ),
                      dialogBackgroundColor: const Color(0xFF1E1E38),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                ref.read(walletDateRangeProvider.notifier).state = picked;
              }
            },
            icon: const Icon(Icons.date_range_rounded, size: 16),
            label: const Text(
              'CHANGE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletOverview(
    double sales,
    double cash,
    double credit,
    double expenses,
    double losses,
    double settlements,
    double duesIncurred,
    double unsoldStock, {
    VoidCallback? onUnsoldStockTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        Widget kpiCard(
          String label,
          String value,
          Color color,
          IconData icon, {
          VoidCallback? onTap,
        }) {
          return SizedBox(
            width: cardWidth,
            child: Card(
              margin: EdgeInsets.zero,
              color: color.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: color.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: color.withValues(alpha: 0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            icon,
                            color: color.withValues(alpha: 0.6),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ETB ${double.parse(value).toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (onTap != null)
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: color.withValues(alpha: 0.6),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            kpiCard(
              'TOTAL SALES',
              sales.toString(),
              const Color(0xFF3B82F6),
              Icons.trending_up_rounded,
            ),
            kpiCard(
              'CASH COLLECTED',
              cash.toString(),
              const Color(0xFF10B981),
              Icons.account_balance_wallet_rounded,
            ),
            kpiCard(
              'CREDIT ORDERS',
              credit.toString(),
              const Color(0xFFF59E0B),
              Icons.credit_card_rounded,
            ),
            kpiCard(
              'EXPENSES (OPEX)',
              expenses.toString(),
              const Color(0xFFF97316),
              Icons.money_off_rounded,
            ),
            kpiCard(
              'INVENTORY LOSSES',
              losses.toString(),
              const Color(0xFFEF4444),
              Icons.remove_shopping_cart_rounded,
            ),
            kpiCard(
              'DUES INCURRED',
              duesIncurred.toString(),
              const Color(0xFFEC4899),
              Icons.local_shipping_rounded,
            ),
            kpiCard(
              'UNSOLD STOCK',
              unsoldStock.toString(),
              const Color(0xFF06B6D4),
              Icons.inventory_2_rounded,
              onTap: onUnsoldStockTap,
            ),
            kpiCard(
              'DUES SETTLED',
              settlements.toString(),
              const Color(0xFF8B5CF6),
              Icons.handshake_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _buildWalletNetPositions(double netCash, double netProfit) {
    Widget positionCard({
      required String title,
      required String subtitle,
      required double val,
      required Color color,
      required IconData icon,
    }) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.01),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${val >= 0 ? "+" : ""}ETB ${val.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: val >= 0
                          ? const Color(0xFF34D399)
                          : const Color(0xFFF87171),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        positionCard(
          title: 'NET CASH POSITION',
          subtitle: 'Liquidity changes (Collected Cash - Expenses - Dues paid)',
          val: netCash,
          color: const Color(0xFF34D399),
          icon: Icons.swap_horizontal_circle_rounded,
        ),
        const SizedBox(height: 16),
        positionCard(
          title: 'TRUE NET PROFIT',
          subtitle:
              'Accounting performance (Sales - Expenses - Product Losses)',
          val: netProfit,
          color: const Color(0xFF60A5FA),
          icon: Icons.analytics_rounded,
        ),
      ],
    );
  }

  Widget _buildWalletDetailsSection(
    BuildContext context,
    WidgetRef ref,
    WalletData wallet,
    List<Product> products,
  ) {
    final receivedStocks = wallet.dailyStocks
        .where((ds) => ds.receivedQuantity > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DETAILED LEDGER BREAKDOWN',
          style: TextStyle(
            color: Colors.white30,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildWalletExpansionCard(
          title: 'OPERATIONAL EXPENSES',
          count: wallet.expenses.length,
          color: const Color(0xFFF97316),
          icon: Icons.money_off_rounded,
          children: wallet.expenses.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No expenses recorded in this period.',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    ),
                  ),
                ]
              : wallet.expenses.map((inst) {
                  final df = DateFormat('MMM dd, yyyy');
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      inst.expense.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      '${df.format(inst.date)} • ${inst.expense.recurrence.name.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Text(
                      '-ETB ${inst.expense.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFFF87171),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
        ),
        const SizedBox(height: 16),
        _buildWalletExpansionCard(
          title: 'INVENTORY LOSSES (AT COST)',
          count: wallet.losses.length,
          color: const Color(0xFFEF4444),
          icon: Icons.remove_shopping_cart_rounded,
          children: wallet.losses.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No inventory losses recorded in this period.',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    ),
                  ),
                ]
              : wallet.losses.map((adj) {
                  final df = DateFormat('MMM dd, yyyy');
                  final prod = products.firstWhere(
                    (p) => p.id == adj.productId,
                    orElse: () => Product()
                      ..name = 'Unknown Product'
                      ..costPrice = 0.0,
                  );
                  final cost = adj.amount.abs() * prod.costPrice;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      prod.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      '${df.format(adj.date)} • ${adj.amount.abs().toStringAsFixed(0)} units lost (${adj.reason.toUpperCase()})',
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Text(
                      '-ETB ${cost.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFFF87171),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
        ),
        const SizedBox(height: 16),
        _buildWalletExpansionCard(
          title: 'SUPPLIER DUES INCURRED (Daily Receives)',
          count: receivedStocks.length,
          color: const Color(0xFFEC4899),
          icon: Icons.local_shipping_rounded,
          children: receivedStocks.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No stock receives recorded in this period.',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    ),
                  ),
                ]
              : receivedStocks.map((ds) {
                  final df = DateFormat('MMM dd, yyyy');
                  final prod = products.firstWhere(
                    (p) => p.id == ds.productId,
                    orElse: () => Product()
                      ..name = 'Unknown Product'
                      ..costPrice = 0.0,
                  );
                  final cost = ds.receivedQuantity * prod.costPrice;
                  final suppliers = ref.watch(suppliersProvider).value ?? [];
                  final supName = prod.supplierId != null
                      ? suppliers
                            .firstWhere(
                              (sup) => sup.id == prod.supplierId,
                              orElse: () =>
                                  Supplier()
                                    ..name = 'Supplier #${prod.supplierId}',
                            )
                            .name
                      : 'No Supplier';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      prod.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      'Received: ${ds.receivedQuantity.toStringAsFixed(0)} units • Supplier: $supName • ${df.format(ds.date)}',
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Text(
                      '+ETB ${cost.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFFEC4899),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
        ),
        const SizedBox(height: 16),
        _buildWalletExpansionCard(
          title: 'SUPPLIER DUES SETTLED',
          count: wallet.settlements.length,
          color: const Color(0xFF8B5CF6),
          icon: Icons.handshake_rounded,
          children: wallet.settlements.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No supplier settlements paid in this period.',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    ),
                  ),
                ]
              : wallet.settlements.map((s) {
                  final df = DateFormat('MMM dd, yyyy');
                  final suppliers = ref.watch(suppliersProvider).value ?? [];
                  final supName = suppliers
                      .firstWhere(
                        (sup) => sup.id == s.supplierId,
                        orElse: () =>
                            Supplier()..name = 'Supplier #${s.supplierId}',
                      )
                      .name;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      supName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      'Settlement Date: ${df.format(s.date)}',
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Text(
                      '-ETB ${s.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
        ),
      ],
    );
  }

  Widget _buildWalletExpansionCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: color,
          iconColor: color,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          subtitle: Text(
            '$count entries',
            style: const TextStyle(color: Colors.white30, fontSize: 11),
          ),
          children: [
            Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesSliver(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    List<Expense> expenses,
  ) {
    if (expenses.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_rounded, size: 64, color: Colors.white10),
              SizedBox(height: 16),
              Text(
                'No expenses recorded for this date.',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap the "+" icon in the top right to log an expense.',
                style: TextStyle(color: Colors.white12, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 1200
        ? width * 0.1
        : (width > 800 ? 48.0 : 24.0);
    final crossAxisCount = width > 1000 ? 3 : (width > 600 ? 2 : 1);

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16,
      ),
      sliver: crossAxisCount > 1
          ? SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 100,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildExpenseCard(context, ref, expenses[index]),
                childCount: expenses.length,
              ),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildExpenseCard(context, ref, expenses[index]),
                ),
                childCount: expenses.length,
              ),
            ),
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) {
    String recurrenceText = '';
    switch (expense.recurrence) {
      case ExpenseRecurrence.none:
        recurrenceText = 'One-time';
        break;
      case ExpenseRecurrence.daily:
        recurrenceText = 'Daily';
        break;
      case ExpenseRecurrence.weekly:
        final weekdayName = DateFormat('EEEE').format(expense.date);
        recurrenceText = 'Weekly on ${weekdayName}s';
        break;
      case ExpenseRecurrence.monthly:
        recurrenceText = 'Monthly on day ${expense.date.day}';
        break;
      case ExpenseRecurrence.yearly:
        final monthDay = DateFormat('MMM dd').format(expense.date);
        recurrenceText = 'Yearly on $monthDay';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  expense.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  recurrenceText,
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'ETB ${expense.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A2E),
                  title: const Text(
                    'Delete Expense',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    'Are you sure you want to delete "${expense.description}"?',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white30),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    TextButton(
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref
                    .read(expenseRepositoryProvider)
                    .deleteExpense(expense.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense deleted successfully'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    ExpenseRecurrence selectedRecurrence = ExpenseRecurrence.none;
    DateTime pickedDate = selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131324),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'RECORD OPERATIONAL EXPENSE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: descriptionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: const TextStyle(color: Colors.white30),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.white10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount (ETB)',
                          labelStyle: const TextStyle(color: Colors.white30),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.white10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: pickedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              pickedDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Date: ${DateFormat('yyyy-MM-dd').format(pickedDate)}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white30,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'RECURRENCE',
                        style: TextStyle(
                          color: Colors.white30,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ExpenseRecurrence>(
                            value: selectedRecurrence,
                            dropdownColor: const Color(0xFF131324),
                            style: const TextStyle(color: Colors.white),
                            isExpanded: true,
                            items: ExpenseRecurrence.values.map((recurrence) {
                              String label = '';
                              switch (recurrence) {
                                case ExpenseRecurrence.none:
                                  label = 'One-time';
                                  break;
                                case ExpenseRecurrence.daily:
                                  label = 'Daily';
                                  break;
                                case ExpenseRecurrence.weekly:
                                  label = 'Weekly';
                                  break;
                                case ExpenseRecurrence.monthly:
                                  label = 'Monthly';
                                  break;
                                case ExpenseRecurrence.yearly:
                                  label = 'Yearly';
                                  break;
                              }
                              return DropdownMenuItem<ExpenseRecurrence>(
                                value: recurrence,
                                child: Text(label),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedRecurrence = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.white30),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text(
                    'SAVE',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newExpense = Expense()
                        ..description = descriptionController.text.trim()
                        ..amount = double.parse(amountController.text)
                        ..date = pickedDate
                        ..recurrence = selectedRecurrence
                        ..lastUpdated = DateTime.now();

                      await ref
                          .read(expenseRepositoryProvider)
                          .saveExpense(newExpense);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Expense recorded successfully'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
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
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
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

Future<void> _shareDailyLedger(
  BuildContext context,
  WidgetRef ref,
  DateTime date,
  List<CustomerOrder> sales,
  List<StockAdjustment> adjustments,
  List<Product> products,
) async {
  if (sales.isEmpty && adjustments.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No transactions to share for this day.')),
    );
    return;
  }
  try {
    await ReceiptShareService.shareDailyLedger(
      date: date,
      sales: sales,
      adjustments: adjustments,
      products: products,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating ledger: $e')));
    }
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

    return Column(
      children: [
        // Toggle Row
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
                    _toggleChip(
                      'TODAY',
                      !_showAllTime,
                      () => setState(() => _showAllTime = false),
                    ),
                    _toggleChip(
                      'ALL TIME',
                      _showAllTime,
                      () => setState(() => _showAllTime = true),
                    ),
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
                    if (_showAllTime ||
                        _isSameDay(
                          o.fulfilledAt ?? o.dueDate,
                          widget.selectedDate,
                        )) {
                      profitMap.putIfAbsent(
                        o.productId,
                        () => _ProductProfitData(),
                      );
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
                    final margin = data.revenue > 0
                        ? (grossProfit / data.revenue) * 100
                        : 0.0;
                    entries.add(
                      _ProductMarginEntry(
                        product: p,
                        revenue: data.revenue,
                        grossProfit: grossProfit,
                        marginPct: margin,
                        unitsSold: data.unitsSold,
                      ),
                    );
                  }

                  // Sort by gross profit descending
                  entries.sort(
                    (a, b) => b.grossProfit.compareTo(a.grossProfit),
                  );

                  // Calculate cash collected vs outstanding credit
                  double cashCollected = 0.0;
                  double outstandingCredit = 0.0;
                  for (final o in orders) {
                    if (_showAllTime ||
                        _isSameDay(
                          o.fulfilledAt ?? o.dueDate,
                          widget.selectedDate,
                        )) {
                      final addonValue = o.addonName != null
                          ? (o.addonPrice ?? 0.0) * (o.addonAmount ?? 0.0)
                          : 0.0;
                      final totalOrderValue =
                          o.amount * o.sellingPriceAtTime + addonValue;
                      if (o.paymentMethod == PaymentMethod.credit) {
                        cashCollected += o.advancePayment;
                        outstandingCredit +=
                            (totalOrderValue - o.advancePayment);
                      } else {
                        cashCollected += totalOrderValue;
                      }
                    }
                  }

                  final maxRevenue = entries.fold(
                    0.0,
                    (m, e) => m > e.revenue ? m : e.revenue,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cash Flow & Customer Credit card
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1E1E38), Color(0xFF131324)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'REAL CASH FLOW & CUSTOMER CREDIT',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Cash Collected',
                                            style: TextStyle(
                                              color: Colors.white30,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ETB ${cashCollected.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white10,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Outstanding Credit',
                                            style: TextStyle(
                                              color: Colors.white30,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ETB ${outstandingCredit.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (outstandingCredit > 0) ...[
                              const SizedBox(height: 16),
                              Divider(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _showCreditCustomersSheet(
                                    context,
                                    ref,
                                    widget.selectedDate,
                                    _showAllTime,
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF818CF8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.people_alt_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'VIEW CREDIT CUSTOMERS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'PRODUCT PERFORMANCE',
                          style: TextStyle(
                            color: Colors.white24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (entries.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No sales data to analyze.',
                              style: TextStyle(color: Colors.white24),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: entries.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _ProductMarginTile(
                                entry: entries[index],
                                rank: index + 1,
                                maxRevenue: maxRevenue,
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
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

  void _showCreditCustomersSheet(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    bool showAllTime,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.98),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, _) {
                final creditOrdersAsync = ref.watch(
                  outstandingCreditOrdersProvider,
                );
                final productsAsync = ref.watch(productsProvider);

                return Column(
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people_alt_rounded,
                            color: Color(0xFF818CF8),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            showAllTime
                                ? 'ALL OUTSTANDING CREDIT'
                                : 'CREDIT DUE TODAY',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    Expanded(
                      child: creditOrdersAsync.when(
                        data: (allCredit) {
                          final creditOrders = allCredit
                              .where((o) {
                                if (showAllTime) return true;
                                return _isSameDay(
                                  o.fulfilledAt ?? o.dueDate,
                                  selectedDate,
                                );
                              })
                              .where((o) {
                                final total =
                                    o.amount * o.sellingPriceAtTime +
                                    (o.addonName != null
                                        ? (o.addonPrice ?? 0.0) *
                                              (o.addonAmount ?? 0.0)
                                        : 0.0);
                                return (total - o.advancePayment) > 0.01;
                              })
                              .toList();

                          if (creditOrders.isEmpty) {
                            return const Center(
                              child: Text(
                                'No outstanding credit orders found.',
                                style: TextStyle(
                                  color: Colors.white30,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }

                          final products = productsAsync.value ?? [];

                          return ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(24),
                            itemCount: creditOrders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final order = creditOrders[index];
                              final total =
                                  order.amount * order.sellingPriceAtTime +
                                  (order.addonName != null
                                      ? (order.addonPrice ?? 0.0) *
                                            (order.addonAmount ?? 0.0)
                                      : 0.0);
                              final balance = total - order.advancePayment;
                              final product = products.firstWhere(
                                (p) => p.id == order.productId,
                                orElse: () =>
                                    Product()..name = 'Unknown Product',
                              );

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            order.customerName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (order.phoneNumber != null &&
                                            order.phoneNumber!.isNotEmpty)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.phone_rounded,
                                              color: Color(0xFF10B981),
                                              size: 20,
                                            ),
                                            onPressed: () async {
                                              final Uri launchUri = Uri(
                                                scheme: 'tel',
                                                path: order.phoneNumber,
                                              );
                                              if (await canLaunchUrl(
                                                launchUri,
                                              )) {
                                                await launchUrl(launchUri);
                                              }
                                            },
                                          ),
                                      ],
                                    ),
                                    if (order.phoneNumber != null &&
                                        order.phoneNumber!.isNotEmpty) ...[
                                      Text(
                                        order.phoneNumber!,
                                        style: const TextStyle(
                                          color: Colors.white30,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    Text(
                                      'Items: ${order.amount.toStringAsFixed(0)}x ${product.name}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (order.addonName != null)
                                      Text(
                                        'Addon: ${order.addonAmount?.toStringAsFixed(0)}x ${order.addonName}',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Due Date: ${_formatDate(order.dueDate)}',
                                          style: const TextStyle(
                                            color: Colors.white30,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          'Balance: ETB ${balance.toStringAsFixed(0)} / ${total.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: Color(0xFFEF4444),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(color: Colors.white10),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              _recordPartialPayment(
                                                context,
                                                ref,
                                                order,
                                                balance,
                                              ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF818CF8,
                                            ),
                                          ),
                                          child: const Text(
                                            'RECORD PAYMENT',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () => _settleCreditOrder(
                                            context,
                                            ref,
                                            order,
                                            balance,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF10B981,
                                            ),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'FULL SETTLE',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(
                          child: Text(
                            'Error: $err',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _settleCreditOrder(
    BuildContext context,
    WidgetRef ref,
    CustomerOrder order,
    double balance,
  ) async {
    final PaymentMethod? method = await showDialog<PaymentMethod>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E38),
        title: const Text(
          'SETTLE BALANCE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        content: const Text(
          'Select the payment method used to settle the outstanding balance:',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, PaymentMethod.cash),
            child: const Text(
              'CASH',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, PaymentMethod.mobile),
            child: const Text(
              'MOBILE',
              style: TextStyle(
                color: Color(0xFF818CF8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white24),
            ),
          ),
        ],
      ),
    );

    if (method == null) return;

    try {
      final total =
          order.amount * order.sellingPriceAtTime +
          (order.addonName != null
              ? (order.addonPrice ?? 0.0) * (order.addonAmount ?? 0.0)
              : 0.0);
      order.paymentMethod = method;
      order.advancePayment = total;

      await ref.read(orderRepositoryProvider).saveOrder(order);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order for ${order.customerName} successfully settled via ${method.name.toUpperCase()}!',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _recordPartialPayment(
    BuildContext context,
    WidgetRef ref,
    CustomerOrder order,
    double balance,
  ) async {
    final controller = TextEditingController();
    final double? amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E38),
        title: const Text(
          'RECORD PAYMENT',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remaining balance: ETB ${balance.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Paid Amount',
                labelStyle: const TextStyle(color: Colors.white30),
                prefixText: 'ETB ',
                prefixStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white10),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF818CF8)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0 && val <= balance) {
                Navigator.pop(context, val);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enter a valid amount between 0 and ${balance.toStringAsFixed(0)}',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text(
              'SUBMIT',
              style: TextStyle(
                color: Color(0xFF818CF8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white24),
            ),
          ),
        ],
      ),
    );

    if (amount == null) return;

    try {
      order.advancePayment += amount;

      final total =
          order.amount * order.sellingPriceAtTime +
          (order.addonName != null
              ? (order.addonPrice ?? 0.0) * (order.addonAmount ?? 0.0)
              : 0.0);
      if (order.advancePayment >= total) {
        if (!context.mounted) return;
        final PaymentMethod? method = await showDialog<PaymentMethod>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E38),
            title: const Text(
              'FULLY SETTLED',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
            content: const Text(
              'The order is now fully paid. Select final payment method:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, PaymentMethod.cash),
                child: const Text(
                  'CASH',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, PaymentMethod.mobile),
                child: const Text(
                  'MOBILE',
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
        if (method != null) {
          order.paymentMethod = method;
        }
        order.advancePayment = total;
      }

      await ref.read(orderRepositoryProvider).saveOrder(order);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment of ETB ${amount.toStringAsFixed(0)} recorded for ${order.customerName}!',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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
    final barFraction = maxRevenue > 0
        ? (entry.revenue / maxRevenue).clamp(0.0, 1.0)
        : 0.0;

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
              valueColor: AlwaysStoppedAnimation<Color>(
                _marginColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statChip(
                Icons.payments_rounded,
                'ETB ${entry.revenue.toStringAsFixed(0)}',
                Colors.white54,
                'Revenue',
              ),
              const SizedBox(width: 12),
              _statChip(
                Icons.trending_up_rounded,
                'ETB ${entry.grossProfit.toStringAsFixed(0)}',
                const Color(0xFF10B981),
                'Profit',
              ),
              const SizedBox(width: 12),
              _statChip(
                Icons.shopping_basket_rounded,
                '${entry.unitsSold.toStringAsFixed(0)} units',
                Colors.white38,
                'Sold',
              ),
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

class ExpenseInstance {
  final Expense expense;
  final DateTime date;
  ExpenseInstance({required this.expense, required this.date});
}

final allSettlementsProvider = StreamProvider<List<SupplierSettlement>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.isar.supplierSettlements.where().watch(
    fireImmediately: true,
  );
});

final allAdjustmentsProvider = StreamProvider<List<StockAdjustment>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.isar.stockAdjustments.where().watch(fireImmediately: true);
});

class ReceivedStockItem {
  final DailyStock dailyStock;
  final double unsoldAtEnd;
  final double unsoldCurrently;

  ReceivedStockItem({
    required this.dailyStock,
    required this.unsoldAtEnd,
    required this.unsoldCurrently,
  });
}

class WalletData {
  final DateTimeRange range;
  final List<CustomerOrder> orders;
  final List<ExpenseInstance> expenses;
  final List<StockAdjustment> losses;
  final List<SupplierSettlement> settlements;
  final List<ReceivedStockItem> receivedStockItems;

  WalletData({
    required this.range,
    required this.orders,
    required this.expenses,
    required this.losses,
    required this.settlements,
    required this.receivedStockItems,
  });

  double get totalSales => orders.fold(0.0, (sum, o) {
    final totalOrderValue =
        o.amount * o.sellingPriceAtTime +
        (o.addonName != null
            ? (o.addonPrice ?? 0.0) * (o.addonAmount ?? 0.0)
            : 0.0);
    return sum + totalOrderValue;
  });

  double get cashCollected => orders.fold(0.0, (sum, o) {
    final totalOrderValue =
        o.amount * o.sellingPriceAtTime +
        (o.addonName != null
            ? (o.addonPrice ?? 0.0) * (o.addonAmount ?? 0.0)
            : 0.0);
    if (o.paymentMethod == PaymentMethod.credit) {
      return sum + o.advancePayment;
    } else {
      return sum + totalOrderValue;
    }
  });

  double get creditReceivables => orders.fold(0.0, (sum, o) {
    final totalOrderValue =
        o.amount * o.sellingPriceAtTime +
        (o.addonName != null
            ? (o.addonPrice ?? 0.0) * (o.addonAmount ?? 0.0)
            : 0.0);
    if (o.paymentMethod == PaymentMethod.credit) {
      return sum + (totalOrderValue - o.advancePayment);
    } else {
      return sum;
    }
  });

  double get totalExpenses =>
      expenses.fold(0.0, (sum, e) => sum + e.expense.amount);

  double getSupplierSettlements() {
    return settlements.fold(0.0, (sum, s) => sum + s.amount);
  }

  double getLossesCost(List<Product> products) {
    double total = 0.0;
    for (var adj in losses) {
      final prod = products.firstWhere(
        (p) => p.id == adj.productId,
        orElse: () => Product()..costPrice = 0.0,
      );
      total += adj.amount.abs() * prod.costPrice;
    }
    return total;
  }

  double getSupplierDuesIncurred(List<Product> products) {
    double total = 0.0;
    for (var item in receivedStockItems) {
      final ds = item.dailyStock;
      if (ds.receivedQuantity > 0) {
        final prod = products.firstWhere(
          (p) => p.id == ds.productId,
          orElse: () => Product()..costPrice = 0.0,
        );
        total += ds.receivedQuantity * prod.costPrice;
      }
    }
    return total;
  }

  double get cogs => orders.fold(0.0, (sum, o) {
    final baseCost = o.amount * o.costPriceAtTime;
    final addonCostVal = o.addonName != null
        ? (o.addonCost ?? 0.0) * (o.addonAmount ?? 0.0)
        : 0.0;
    return sum + baseCost + addonCostVal;
  });

  double getUnsoldReceivedStockValue(List<Product> products) {
    double total = 0.0;
    for (var item in receivedStockItems) {
      final ds = item.dailyStock;
      if (ds.receivedQuantity > 0) {
        final prod = products.firstWhere(
          (p) => p.id == ds.productId,
          orElse: () => Product()..costPrice = 0.0,
        );
        total += item.unsoldAtEnd * prod.costPrice;
      }
    }
    return total;
  }
}

final walletDataProvider = Provider<AsyncValue<WalletData>>((ref) {
  final range = ref.watch(walletDateRangeProvider);
  final ordersAsync = ref.watch(allTimeSalesProvider);
  final expensesAsync = ref.watch(expensesStreamProvider);
  final lossesAsync = ref.watch(allAdjustmentsProvider);
  final settlementsAsync = ref.watch(allSettlementsProvider);
  final dailyStocksAsync = ref.watch(allDailyStockProvider);

  if (ordersAsync.isLoading ||
      expensesAsync.isLoading ||
      lossesAsync.isLoading ||
      settlementsAsync.isLoading ||
      dailyStocksAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (ordersAsync.hasError ||
      expensesAsync.hasError ||
      lossesAsync.hasError ||
      settlementsAsync.hasError ||
      dailyStocksAsync.hasError) {
    final error =
        ordersAsync.error ??
        expensesAsync.error ??
        lossesAsync.error ??
        settlementsAsync.error ??
        dailyStocksAsync.error;
    return AsyncValue.error(error!, StackTrace.current);
  }

  final allOrders = ordersAsync.value ?? [];
  final allExpenses = expensesAsync.value ?? [];
  final allLosses = lossesAsync.value ?? [];
  final allSettlements = settlementsAsync.value ?? [];
  final allDailyStocks = dailyStocksAsync.value ?? [];

  final startOfDay = DateTime(
    range.start.year,
    range.start.month,
    range.start.day,
  );
  final endOfDay = DateTime(
    range.end.year,
    range.end.month,
    range.end.day,
    23,
    59,
    59,
    999,
  );

  final rangeOrders = allOrders
      .where(
        (o) =>
            o.dueDate.isAfter(
              startOfDay.subtract(const Duration(milliseconds: 1)),
            ) &&
            o.dueDate.isBefore(endOfDay.add(const Duration(milliseconds: 1))),
      )
      .toList();
  final rangeLosses = allLosses
      .where(
        (adj) =>
            adj.amount < 0 &&
            adj.date.isAfter(
              startOfDay.subtract(const Duration(milliseconds: 1)),
            ) &&
            adj.date.isBefore(endOfDay.add(const Duration(milliseconds: 1))),
      )
      .toList();
  final rangeSettlements = allSettlements
      .where(
        (s) =>
            s.date.isAfter(
              startOfDay.subtract(const Duration(milliseconds: 1)),
            ) &&
            s.date.isBefore(endOfDay.add(const Duration(milliseconds: 1))),
      )
      .toList();
  final rangeDailyStocks = allDailyStocks
      .where(
        (ds) =>
            ds.date.isAfter(
              startOfDay.subtract(const Duration(milliseconds: 1)),
            ) &&
            ds.date.isBefore(endOfDay.add(const Duration(milliseconds: 1))),
      )
      .toList();

  final rangeExpenses = <ExpenseInstance>[];
  for (
    var d = startOfDay;
    !d.isAfter(endOfDay);
    d = d.add(const Duration(days: 1))
  ) {
    final activeOnDay = allExpenses.where((expense) {
      final expDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      final target = DateTime(d.year, d.month, d.day);
      if (target.isBefore(expDate)) return false;
      switch (expense.recurrence) {
        case ExpenseRecurrence.none:
          return target.year == expDate.year &&
              target.month == expDate.month &&
              target.day == expDate.day;
        case ExpenseRecurrence.daily:
          return true;
        case ExpenseRecurrence.weekly:
          return target.weekday == expDate.weekday;
        case ExpenseRecurrence.monthly:
          return target.day == expDate.day;
        case ExpenseRecurrence.yearly:
          return target.day == expDate.day && target.month == expDate.month;
      }
    }).toList();

    for (var e in activeOnDay) {
      rangeExpenses.add(ExpenseInstance(expense: e, date: d));
    }
  }

  return AsyncValue.data(
    WalletData(
      range: range,
      orders: rangeOrders,
      expenses: rangeExpenses,
      losses: rangeLosses,
      settlements: rangeSettlements,
      dailyStocks: rangeDailyStocks,
    ),
  );
});
