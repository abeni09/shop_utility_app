import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/dashboard/data/daily_log_model.dart';
import 'package:shopsync/features/dashboard/presentation/dashboard_providers.dart';

class FinancialWeeklyChart extends ConsumerStatefulWidget {
  const FinancialWeeklyChart({super.key});

  @override
  ConsumerState<FinancialWeeklyChart> createState() =>
      _FinancialWeeklyChartState();
}

class _FinancialWeeklyChartState extends ConsumerState<FinancialWeeklyChart> {
  late DateTimeRange _dateRange;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    final start = today.subtract(const Duration(days: 6));
    _dateRange = DateTimeRange(start: start, end: today);
  }

  @override
  Widget build(BuildContext context) {
    final start = _dateRange.start;
    final end = _dateRange.end;
    final logsAsync = ref.watch(dailyLogsProvider((start: start, end: end)));

    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FINANCIAL TREND',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _LegendItem(
                          color: const Color(0xFF6366F1),
                          label: 'Sales',
                        ),
                        const SizedBox(width: 12),
                        _LegendItem(
                          color: const Color(0xFFEF4444),
                          label: 'Expenses',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    initialDateRange: _dateRange,
                    firstDate: DateTime(2025),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF6366F1),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF818CF8),
                        size: 12,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('MMM d').format(_dateRange.start)} - ${DateFormat('MMM d').format(_dateRange.end)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                final Map<String, DailyLog> logsMap = {
                  for (var log in logs)
                    DateFormat('yyyy-MM-dd').format(log.date): log,
                };

                final int dayCount =
                    _dateRange.end.difference(_dateRange.start).inDays + 1;
                final List<DailyLog> weekLogs = List.generate(dayCount, (i) {
                  final date = _dateRange.start.add(Duration(days: i));
                  final dateStr = DateFormat('yyyy-MM-dd').format(date);
                  return logsMap[dateStr] ?? (DailyLog()..date = date);
                });

                if (weekLogs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No transaction history',
                      style: TextStyle(color: Colors.white24, fontSize: 13),
                    ),
                  );
                }

                double maxVal = 100.0;
                for (var log in weekLogs) {
                  if (log.totalSales > maxVal) maxVal = log.totalSales;
                  if (log.totalSupplierOrders > maxVal) {
                    maxVal = log.totalSupplierOrders;
                  }
                }
                // Give some padding above the highest point
                maxVal = maxVal * 1.15;

                final salesSpots = weekLogs.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.totalSales);
                }).toList();
                if (salesSpots.length == 1) {
                  salesSpots.add(FlSpot(1.0, salesSpots[0].y));
                }

                final expenseSpots = weekLogs.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.totalSupplierOrders);
                }).toList();
                if (expenseSpots.length == 1) {
                  expenseSpots.add(FlSpot(1.0, expenseSpots[0].y));
                }

                final double maxXVal = weekLogs.length > 1
                    ? (weekLogs.length - 1).toDouble()
                    : 1.0;

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxVal / 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withValues(alpha: 0.05),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: maxVal / 4,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            if (value == maxVal) return const SizedBox.shrink();
                            return Text(
                              value >= 1000
                                  ? '${(value / 1000).toStringAsFixed(1)}k'
                                  : value.toStringAsFixed(0),
                              style: const TextStyle(
                                color: Colors.white30,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= weekLogs.length) {
                              return const SizedBox.shrink();
                            }

                            final int interval = weekLogs.length <= 7
                                ? 1
                                : (weekLogs.length / 5).ceil();

                            if (idx % interval != 0) {
                              return const SizedBox.shrink();
                            }

                            final date = weekLogs[idx].date;
                            final text = weekLogs.length <= 7
                                ? DateFormat('E').format(date).toUpperCase()
                                : DateFormat(
                                    'd MMM',
                                  ).format(date).toUpperCase();

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.white30,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: maxXVal,
                    minY: 0,
                    maxY: maxVal,
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) =>
                            const Color(0xFF1E293B).withValues(alpha: 0.9),
                        tooltipBorderRadius: BorderRadius.circular(12),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((barSpot) {
                            final isSales = barSpot.barIndex == 0;
                            return LineTooltipItem(
                              '${isSales ? "Sales" : "Expenses"}: ${barSpot.y.toStringAsFixed(2)}',
                              TextStyle(
                                color: isSales
                                    ? const Color(0xFF818CF8)
                                    : const Color(0xFFF87171),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: salesSpots,
                        isCurved: true,
                        color: const Color(0xFF6366F1),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF6366F1).withValues(alpha: 0.15),
                              const Color(0xFF6366F1).withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                      LineChartBarData(
                        spots: expenseSpots,
                        isCurved: true,
                        color: const Color(0xFFEF4444),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFEF4444).withValues(alpha: 0.15),
                              const Color(0xFFEF4444).withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF818CF8)),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error loading chart: $err',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
