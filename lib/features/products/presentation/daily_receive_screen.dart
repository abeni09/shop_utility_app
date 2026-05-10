import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/products/data/daily_stock_model.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/features/suppliers/presentation/supplier_list_screen.dart';
import 'package:shopsync/features/dashboard/presentation/dashboard_providers.dart';

class DailyReceiveScreen extends ConsumerStatefulWidget {
  const DailyReceiveScreen({super.key});

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

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final stockAsync = ref.watch(dailyStockProvider(_selectedDate));

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text('RECEIVE STOCK'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, size: 20),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = DateTime(date.year, date.month, date.day);
                });
              }
            },
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) => stockAsync.when(
          data: (stocks) {
            // Initialize or Update controllers to match current date/stocks
            for (var p in products) {
              final stock = stocks.firstWhere(
                (s) => s.productId == p.id,
                orElse: () => DailyStock(),
              );

              final val = stock.receivedQuantity > 0
                  ? stock.receivedQuantity.toStringAsFixed(0)
                  : '';

              if (!_controllers.containsKey(p.id)) {
                _controllers[p.id] = TextEditingController(text: val);
              } else {
                // If the user changed the date, update the controller text
                // only if the user isn't currently typing (or just always update if we want sync)
                if (_controllers[p.id]!.text != val &&
                    !FocusScope.of(context).hasFocus) {
                  _controllers[p.id]!.text = val;
                }
              }
            }

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white.withValues(alpha: 0.02),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.indigoAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Input actual physical stock received on ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final stock = stocks
                          .where((s) => s.productId == product.id)
                          .firstOrNull;
                      return _StockInputCard(
                        productName: product.name,
                        controller: _controllers[product.id]!,
                        requestedAmount: stock?.requestedQuantity ?? 0.0,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        final repo = ref.read(dailyStockRepositoryProvider);
                        final supplierRepo = ref.read(
                          supplierRepositoryProvider,
                        );
                        final dashboardRepo = ref.read(
                          dashboardRepositoryProvider,
                        );

                        for (var p in products) {
                          final text = _controllers[p.id]!.text.trim();
                          final amount = double.tryParse(text) ?? 0;

                          if (amount < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
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

                          // Update supplier balance if quantity changed
                          if (delta != 0 && p.supplierId != null) {
                            await supplierRepo.updateBalance(
                              p.supplierId!,
                              delta * p.costPrice,
                            );
                          }
                        }

                        // Update daily log stats
                        await dashboardRepo.recalculateSupplierOrders(
                          _selectedDate,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Stock levels and supplier balances updated!',
                            ),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'SAVE DAILY STOCK',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StockInputCard extends StatelessWidget {
  final String productName;
  final TextEditingController controller;
  final double requestedAmount;

  const _StockInputCard({
    required this.productName,
    required this.controller,
    required this.requestedAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
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
