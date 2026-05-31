import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shopsync/features/dashboard/data/daily_log_model.dart';
import 'package:shopsync/features/dashboard/presentation/dashboard_providers.dart';
import 'package:shopsync/features/suppliers/presentation/supplier_list_screen.dart';
import 'package:shopsync/features/products/presentation/receiving_report_screen.dart';
import 'dart:ui';

class FinancialReportScreen extends ConsumerStatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  ConsumerState<FinancialReportScreen> createState() =>
      _FinancialReportScreenState();
}

class _FinancialReportScreenState extends ConsumerState<FinancialReportScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(customDateProfitProvider(
      (start: _dateRange.start, end: _dateRange.end),
    ));

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('FINANCIAL INSIGHTS'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981)),
            tooltip: 'Receiving Report',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReceivingReportScreen()),
            ),
          ),
          const SizedBox(width: 16),
        ],
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
            child: _GlowCircle(color: const Color(0xFF6366F1).withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: _GlowCircle(color: const Color(0xFF10B981).withValues(alpha: 0.1)),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildDateSelector(context),
                Expanded(
                  child: reportAsync.when(
                    data: (data) => _buildReportContent(data),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Color(0xFF818CF8)),
                    ),
                    error: (err, _) => Center(
                      child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
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
      padding: const EdgeInsets.all(24.0),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Color(0xFF818CF8), size: 20),
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

  Widget _buildReportContent(Map<String, double> data) {
    final sales = data['sales'] ?? 0;
    final profit = data['profit'] ?? 0;
    final margin = sales > 0 ? (profit / sales) * 100 : 0.0;

    final dailyLogsAsync = ref.watch(dailyLogsProvider(
      (start: _dateRange.start, end: _dateRange.end),
    ));

    final suppliersAsync = ref.watch(suppliersProvider);
    final suppliers = suppliersAsync.value ?? [];
    final totalDueToSuppliers = suppliers
        .where((s) => s.isActive && !s.isVoid)
        .fold<double>(0.0, (sum, s) => sum + s.balance);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 16),
        _buildChartSection(dailyLogsAsync),
        const SizedBox(height: 32),
        _StatCard(
          label: 'TOTAL REVENUE',
          value: sales.toStringAsFixed(2),
          icon: Icons.payments_rounded,
          color: const Color(0xFF6366F1),
        ),
        const SizedBox(height: 16),
        _StatCard(
          label: 'NET PROFIT',
          value: profit.toStringAsFixed(2),
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 16),
        _StatCard(
          label: 'PROFIT MARGIN',
          value: '${margin.toStringAsFixed(1)}%',
          icon: Icons.pie_chart_rounded,
          color: Colors.orangeAccent,
        ),
        const SizedBox(height: 16),
        _StatCard(
          label: 'TOTAL DUE TO SUPPLIERS',
          value: totalDueToSuppliers.toStringAsFixed(2),
          icon: Icons.account_balance_wallet_rounded,
          color: Colors.redAccent,
        ),
        const SizedBox(height: 40),
        const Text(
          'SUMMARY',
          style: TextStyle(
            color: Colors.white38,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _SummaryRow(
                label: 'Avg. Daily Profit',
                value: (profit / (_dateRange.duration.inDays + 1))
                    .toStringAsFixed(2),
              ),
              const Divider(height: 32, color: Colors.white10),
              _SummaryRow(
                label: 'Performance',
                value: margin > 20
                    ? 'Excellent'
                    : (margin > 10 ? 'Good' : 'Needs Review'),
                valueColor: margin > 20
                    ? const Color(0xFF10B981)
                    : Colors.orangeAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildChartSection(AsyncValue<List<DailyLog>> logsAsync) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'No data for selected range',
                style: TextStyle(color: Colors.white24),
              ),
            );
          }

          final spots = logs.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value.totalProfit);
          }).toList();

          return LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF818CF8),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF818CF8).withValues(alpha: 0.3),
                        const Color(0xFF818CF8).withValues(alpha: 0.0),
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
        error: (err, _) => const Center(
          child: Icon(Icons.error_outline, color: Colors.redAccent),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
