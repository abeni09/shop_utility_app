import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/products/data/daily_stock_model.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';

class DailyReceiveScreen extends ConsumerStatefulWidget {
  const DailyReceiveScreen({super.key});

  @override
  ConsumerState<DailyReceiveScreen> createState() => _DailyReceiveScreenState();
}

class _DailyReceiveScreenState extends ConsumerState<DailyReceiveScreen> {
  final Map<int, TextEditingController> _controllers = {};
  DateTime _selectedDate = DateTime.now();

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
                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) => stockAsync.when(
          data: (stocks) {
            // Initialize controllers
            for (var p in products) {
              if (!_controllers.containsKey(p.id)) {
                final stock = stocks.firstWhere(
                  (s) => s.productId == p.id,
                  orElse: () => DailyStock(),
                );
                _controllers[p.id] = TextEditingController(
                  text: stock.receivedQuantity > 0
                      ? stock.receivedQuantity.toStringAsFixed(0)
                      : '',
                );
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
                      return _StockInputCard(
                        productName: product.name,
                        controller: _controllers[product.id]!,
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
                        for (var p in products) {
                          final amount =
                              double.tryParse(_controllers[p.id]!.text) ?? 0;

                          var stock = await repo.getStockForProduct(
                            p.id,
                            _selectedDate,
                          );

                          stock ??= DailyStock()
                            ..productId = p.id
                            ..date = _selectedDate;

                          stock.receivedQuantity = amount;
                          await repo.saveDailyStock(stock);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stock levels updated!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                          Navigator.pop(context);
                        }
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

  const _StockInputCard({required this.productName, required this.controller});

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
            child: Text(
              productName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
