import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/products/data/daily_stock_model.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/suppliers/presentation/supplier_list_screen.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/dashboard/presentation/dashboard_providers.dart';

class DailyReceiveScreen extends ConsumerStatefulWidget {
  final int? preselectedProductId;
  const DailyReceiveScreen({super.key, this.preselectedProductId});

  @override
  ConsumerState<DailyReceiveScreen> createState() => _DailyReceiveScreenState();
}

class _DailyReceiveScreenState extends ConsumerState<DailyReceiveScreen> {
  final Map<int, TextEditingController> _controllers = {};
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  DateTime? _loadedDate;

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadedDate != _selectedDate) {
      for (var controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
      _loadedDate = _selectedDate;
    }
    final productsAsync = ref.watch(productsProvider);
    final stockAsync = ref.watch(dailyStockProvider(_selectedDate));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            body: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverAppBar.large(
                  backgroundColor: Colors.transparent,
                  title: const Text('RECEIVE STOCK'),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.05),
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
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 30),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                              );
                              _controllers.clear();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: productsAsync.when(
                    data: (products) => stockAsync.when(
                      data: (stocks) {
                        // Initialize or Update controllers
                        for (var p in products) {
                          final stock = stocks.firstWhere(
                            (s) => s.productId == p.id,
                            orElse: () => DailyStock(),
                          );
                          final val = stock.receivedQuantity > 0
                              ? stock.receivedQuantity.toStringAsFixed(0)
                              : '';
                          if (!_controllers.containsKey(p.id)) {
                            _controllers[p.id] = TextEditingController(
                              text: val,
                            );
                          } else if (_controllers[p.id]!.text != val &&
                              !FocusScope.of(context).hasFocus) {
                            _controllers[p.id]!.text = val;
                          }
                        }
                        return Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: 0.1),
                                    const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: Color(0xFF818CF8),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Input actual physical stock received on ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
                productsAsync.when(
                  data: (products) => stockAsync.when(
                    data: (stocks) {
                      final displayProducts = List<Product>.from(products);
                      if (widget.preselectedProductId != null) {
                        final idx = displayProducts.indexWhere(
                          (p) => p.id == widget.preselectedProductId,
                        );
                        if (idx != -1) {
                          final p = displayProducts.removeAt(idx);
                          displayProducts.insert(0, p);
                        }
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final product = displayProducts[index];
                            final stock = stocks
                                .where((s) => s.productId == product.id)
                                .firstOrNull;
                            final isPreselected =
                                product.id == widget.preselectedProductId;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _StockInputCard(
                                productName: product.name,
                                controller: _controllers[product.id]!,
                                requestedAmount:
                                    stock?.requestedQuantity ?? 0.0,
                                isHighlight: isPreselected,
                                onLongPress: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color(0xFF0F172A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                        side: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        'RESET ${product.name.toUpperCase()}?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          letterSpacing: 1,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      content: const Text(
                                        'This will wipe all stock records and void all orders for this product. Use this to fix negative stock issues.',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text(
                                            'CANCEL',
                                            style: TextStyle(
                                              color: Colors.white24,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                          ),
                                          child: const Text(
                                            'RESET HISTORY',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await ref
                                        .read(dailyStockRepositoryProvider)
                                        .resetProductHistory(product.id);
                                    await ref
                                        .read(orderRepositoryProvider)
                                        .resetProductHistory(product.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'History reset for ${product.name}',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          }, childCount: displayProducts.length),
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
                    error: (e, _) => SliverFillRemaining(
                      child: Center(child: Text('Error: $e')),
                    ),
                  ),
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(child: Text('Error: $e')),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: const Color(
                            0xFF6366F1,
                          ).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          final repo = ref.read(dailyStockRepositoryProvider);
                          final supplierRepo = ref.read(
                            supplierRepositoryProvider,
                          );
                          final dashboardRepo = ref.read(
                            dashboardRepositoryProvider,
                          );

                          for (var p in productsAsync.value ?? []) {
                            final text = _controllers[p.id]!.text.trim();
                            final amount = double.tryParse(text) ?? 0;

                            if (amount < 0) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Invalid amount for ${p.name}'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            var stock = await repo.getStockForProduct(
                              p.id,
                              _selectedDate,
                            );

                            final oldReceived = stock?.receivedQuantity ?? 0.0;
                            final delta = amount - oldReceived;

                            stock ??= DailyStock()
                              ..productId = p.id
                              ..date = _selectedDate;

                            stock.receivedQuantity = amount;
                            await repo.saveDailyStock(stock);

                            if (delta != 0 && p.supplierId != null) {
                              await supplierRepo.updateBalance(
                                p.supplierId!,
                                delta * p.costPrice,
                              );
                            }
                          }

                          await dashboardRepo.recalculateSupplierOrders(
                            _selectedDate,
                          );

                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Stock levels and supplier balances updated!',
                              ),
                              backgroundColor: Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          if (navigator.canPop()) {
                            navigator.pop();
                          }
                        },
                        child: const Text(
                          'SAVE DAILY STOCK',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockInputCard extends StatelessWidget {
  final String productName;
  final TextEditingController controller;
  final double requestedAmount;
  final VoidCallback? onLongPress;
  final bool isHighlight;

  const _StockInputCard({
    required this.productName,
    required this.controller,
    required this.requestedAmount,
    this.onLongPress,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHighlight
              ? [
                  const Color(0xFF6366F1).withValues(alpha: 0.15),
                  const Color(0xFF818CF8).withValues(alpha: 0.05),
                ]
              : [
                  Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFF818CF8).withValues(alpha: 0.6)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          width: isHighlight ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlight
                ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: isHighlight ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: onLongPress,
                  child: Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (requestedAmount > 0)
                  Text(
                    'Ordered: ${requestedAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: Colors.white10),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
