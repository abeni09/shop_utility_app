import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/core/utils/receipt_share_service.dart';
import 'dart:ui';

class ReceivingReportScreen extends ConsumerStatefulWidget {
  const ReceivingReportScreen({super.key});

  @override
  ConsumerState<ReceivingReportScreen> createState() =>
      _ReceivingReportScreenState();
}

class _ReceivingReportScreenState extends ConsumerState<ReceivingReportScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  final Map<int, bool> _collapsedProducts = {};
  bool _groupBySupplier = true;
  final Map<String, bool> _collapsedSuppliers = {};

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(
      receivingReportProvider((start: _dateRange.start, end: _dateRange.end)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'RECEIVING REPORT',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        actions: [
          reportAsync.maybeWhen(
            data: (items) => IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              tooltip: 'Share PDF Report',
              onPressed: items.isEmpty
                  ? null
                  : () async {
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Generating PDF report...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        await ReceiptShareService.shareReceivingReport(
                          start: _dateRange.start,
                          end: _dateRange.end,
                          items: items,
                          groupBySupplier: _groupBySupplier,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to share report: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: _GlowCircle(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: _GlowCircle(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildDateSelector(context),
                _buildGroupToggle(),
                Expanded(
                  child: reportAsync.when(
                    data: (items) => _buildReportContent(items),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF818CF8),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final df = DateFormat('MMM dd, yyyy');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDateRangePicker(
            context: context,
            initialDateRange: _dateRange,
            firstDate: DateTime(2023),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF10B981),
                    onPrimary: Colors.white,
                    surface: Color(0xFF0F172A),
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() => _dateRange = picked);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '${df.format(_dateRange.start)} - ${df.format(_dateRange.end)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Icon(Icons.expand_more_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          const Text(
            'GROUP BY',
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
                  'BY ITEM',
                  !_groupBySupplier,
                  () => setState(() => _groupBySupplier = false),
                ),
                _toggleChip(
                  'BY SUPPLIER',
                  _groupBySupplier,
                  () => setState(() => _groupBySupplier = true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildReportContent(List<ReceivingReportItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'NO STOCK RECEIVED IN THIS PERIOD',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final totalUnits = items.fold<double>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final totalCost = items.fold<double>(
      0,
      (sum, item) => sum + item.totalCost,
    );

    if (_groupBySupplier) {
      final Map<String, List<ReceivingReportItem>> groupedBySupplier = {};
      for (var item in items) {
        groupedBySupplier.putIfAbsent(item.supplierName, () => []).add(item);
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'TOTAL UNITS RECEIVED',
                    value: totalUnits.toStringAsFixed(1),
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    label: 'TOTAL COST OF STOCK',
                    value: '\$${totalCost.toStringAsFixed(2)}',
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: groupedBySupplier.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final supplierName = groupedBySupplier.keys.elementAt(index);
                final supplierItems = groupedBySupplier[supplierName]!;
                final isCollapsed = _collapsedSuppliers[supplierName] ?? true;

                final groupTotalUnits = supplierItems.fold<double>(
                  0,
                  (sum, i) => sum + i.quantity,
                );
                final groupTotalCost = supplierItems.fold<double>(
                  0,
                  (sum, i) => sum + i.totalCost,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _collapsedSuppliers[supplierName] = !isCollapsed;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.business_rounded,
                                color: Color(0xFF34D399),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supplierName.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Received: ${groupTotalUnits.toStringAsFixed(1)} units • Cost: \$${groupTotalCost.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isCollapsed
                                  ? Icons.keyboard_arrow_right_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: Colors.white38,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isCollapsed)
                      ...supplierItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _ReportItemRow(
                            item: item,
                            hideSupplier: true,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      );
    }

    // Group items by product
    final Map<int, List<ReceivingReportItem>> groupedItems = {};
    for (var item in items) {
      groupedItems.putIfAbsent(item.productId, () => []).add(item);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'TOTAL UNITS RECEIVED',
                  value: totalUnits.toStringAsFixed(1),
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  label: 'TOTAL COST OF STOCK',
                  value: '\$${totalCost.toStringAsFixed(2)}',
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            itemCount: groupedItems.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final productId = groupedItems.keys.elementAt(index);
              final productItems = groupedItems[productId]!;
              final productName = productItems.first.productName;
              final isCollapsed = _collapsedProducts[productId] ?? true;

              final groupTotalUnits = productItems.fold<double>(
                0,
                (sum, i) => sum + i.quantity,
              );
              final groupTotalCost = productItems.fold<double>(
                0,
                (sum, i) => sum + i.totalCost,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _collapsedProducts[productId] = !isCollapsed;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: Color(0xFF818CF8),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Received: ${groupTotalUnits.toStringAsFixed(1)} units • Cost: \$${groupTotalCost.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isCollapsed
                                ? Icons.keyboard_arrow_right_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isCollapsed)
                    ...productItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _ReportItemRow(item: item),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportItemRow extends StatelessWidget {
  final ReceivingReportItem item;
  final bool hideSupplier;

  const _ReportItemRow({
    required this.item,
    this.hideSupplier = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.call_received_rounded,
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
                  item.productName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!hideSupplier) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Supplier: ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        item.supplierName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(item.date),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+\$${item.totalCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.quantity.toStringAsFixed(1)} x \$${item.costPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;

  const _GlowCircle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
