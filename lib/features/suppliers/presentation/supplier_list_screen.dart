import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/suppliers/data/supplier_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_settlement_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_repository.dart';
import 'package:shopsync/main.dart';
import 'package:shopsync/features/dashboard/presentation/ui_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shopsync/core/utils/receipt_share_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/features/products/data/product_model.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final backupService = ref.watch(backupServiceProvider);
  return SupplierRepository(dbService.isar, backupService);
});

final suppliersProvider = StreamProvider<List<Supplier>>((ref) {
  final repository = ref.watch(supplierRepositoryProvider);
  final showArchived = ref.watch(showArchivedSuppliersProvider);
  return repository.watchSuppliers(includeVoided: showArchived);
});

class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final showArchived = ref.watch(showArchivedSuppliersProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              await ref.read(backupServiceProvider).forceSyncCheck();
              ref.invalidate(cloudSyncStatusProvider);
              ref.invalidate(localAheadProvider);
            },
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            color: Theme.of(context).colorScheme.primary,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomInset: false,
              body: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverAppBar.large(
                    backgroundColor: Colors.transparent,
                    title: const Text('SUPPLIERS'),
                    actions: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: showArchived
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2)
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            showArchived
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: showArchived
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                          ),
                          onPressed: () =>
                              ref
                                      .read(
                                        showArchivedSuppliersProvider.notifier,
                                      )
                                      .state =
                                  !showArchived,
                          tooltip: 'Show Voided Suppliers',
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
                          icon: Icon(
                            Icons.bar_chart_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () =>
                              _showWeeklyReportDialog(context, ref),
                          tooltip: 'Weekly Report',
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
                            Icons.person_add_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => _showSupplierDialog(context, ref),
                        ),
                      ),
                    ],
                  ),

                  suppliersAsync.when(
                    data: (suppliers) {
                      final width = MediaQuery.of(context).size.width;
                      final horizontalPadding = width > 1200
                          ? width * 0.1
                          : (width > 800 ? 48.0 : 24.0);
                      final crossAxisCount = width > 1000
                          ? 3
                          : (width > 600 ? 2 : 1);

                      return suppliers.isEmpty
                          ? const SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  'No suppliers found',
                                  style: TextStyle(color: Colors.white38),
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
                                            mainAxisExtent: 240,
                                          ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) => _SupplierCard(
                                          supplier: suppliers[index],
                                        ),
                                        childCount: suppliers.length,
                                      ),
                                    )
                                  : SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: _SupplierCard(
                                            supplier: suppliers[index],
                                          ),
                                        ),
                                        childCount: suppliers.length,
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
                    error: (err, stack) => SliverFillRemaining(
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
          ),
        ],
      ),
    );
  }
}

Future<void> _showWeeklyReportDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  // Default: current week Mon–today
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  DateTime from = DateTime(monday.year, monday.month, monday.day);
  DateTime to = DateTime(now.year, now.month, now.day, 23, 59, 59);
  bool isGenerating = false;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'WEEKLY REPORT',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 14,
            color: Color(0xFF818CF8),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select date range for supplier dues and sales report.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: from,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) {
                        setState(() => from = DateTime(d.year, d.month, d.day));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FROM',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd').format(from),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white30,
                    size: 16,
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: to,
                        firstDate: from,
                        lastDate: DateTime.now(),
                      );
                      if (d != null) {
                        setState(
                          () =>
                              to = DateTime(d.year, d.month, d.day, 23, 59, 59),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TO',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd').format(to),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: isGenerating
                ? null
                : () async {
                    setState(() => isGenerating = true);
                    try {
                      await _generateWeeklyReport(context, ref, from, to);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        setState(() => isGenerating = false);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
            child: isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'GENERATE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _generateWeeklyReport(
  BuildContext context,
  WidgetRef ref,
  DateTime from,
  DateTime to,
) async {
  final supplierRepo = ref.read(supplierRepositoryProvider);
  final orderRepo = ref.read(orderRepositoryProvider);

  final suppliers = (await supplierRepo.getAllSuppliers())
      .where((s) => !s.isVoid)
      .toList();
  final settlements = await supplierRepo.getSettlementsInRange(from, to);
  final allOrders = await orderRepo.getAllOrdersInRange(from, to);
  final soldOrders = allOrders
      .where((o) => o.status == OrderStatus.sold)
      .toList();

  // Build list of days in range
  final days = <DateTime>[];
  var cur = DateTime(from.year, from.month, from.day);
  final lastDay = DateTime(to.year, to.month, to.day);
  while (!cur.isAfter(lastDay)) {
    days.add(cur);
    cur = cur.add(const Duration(days: 1));
  }

  final df = DateFormat('EEE, MMM dd');
  final rangeLabel =
      '${DateFormat('MMM dd').format(from)} – ${DateFormat('MMM dd yyyy').format(to)}';

  double revenueOnDay(DateTime day) {
    return soldOrders
        .where((o) => _isSameDay(o.fulfilledAt ?? o.dueDate, day))
        .fold(0.0, (s, o) => s + o.amount * o.sellingPriceAtTime);
  }

  double settlementsOnDayForSupplier(DateTime day, int supplierId) {
    return settlements
        .where((s) => s.supplierId == supplierId && _isSameDay(s.date, day))
        .fold(0.0, (s, e) => s + e.amount);
  }

  final pages = <pw.Widget>[];

  // ── Combined Summary Page ──────────────────────────────────────────────
  final combinedRows = days.map((day) {
    final rev = revenueOnDay(day);
    final dues = settlements
        .where((s) => _isSameDay(s.date, day))
        .fold(0.0, (s, e) => s + e.amount);
    return [df.format(day), rev.toStringAsFixed(2), dues.toStringAsFixed(2)];
  }).toList();
  final totalRev = soldOrders.fold(
    0.0,
    (s, o) => s + o.amount * o.sellingPriceAtTime,
  );
  final totalDues = settlements.fold(0.0, (s, e) => s + e.amount);
  combinedRows.add([
    'TOTAL',
    totalRev.toStringAsFixed(2),
    totalDues.toStringAsFixed(2),
  ]);

  pages.addAll([
    pw.Center(
      child: pw.Text(
        'SHOPSYNC — WEEKLY REPORT',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
      ),
    ),
    pw.Center(
      child: pw.Text(
        rangeLabel,
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    ),
    pw.SizedBox(height: 16),
    pw.Divider(thickness: 1.5),
    pw.Text(
      'ALL SUPPLIERS — COMBINED',
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 11,
        color: PdfColors.indigo700,
      ),
    ),
    pw.SizedBox(height: 8),
    pw.TableHelper.fromTextArray(
      headers: ['Date', 'Revenue (ETB)', 'Dues Paid (ETB)'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      data: combinedRows,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    ),
    pw.SizedBox(height: 24),
  ]);

  // ── Per Supplier Pages ─────────────────────────────────────────────────
  for (final supplier in suppliers) {
    final supplierSettlements = settlements
        .where((s) => s.supplierId == supplier.id)
        .toList();
    if (supplierSettlements.isEmpty) continue; // skip suppliers with no dues

    final supplierRows = days.map((day) {
      final rev = revenueOnDay(day);
      final dues = settlementsOnDayForSupplier(day, supplier.id);
      return [df.format(day), rev.toStringAsFixed(2), dues.toStringAsFixed(2)];
    }).toList();
    final supplierTotal = supplierSettlements.fold(0.0, (s, e) => s + e.amount);
    supplierRows.add([
      'TOTAL',
      totalRev.toStringAsFixed(2),
      supplierTotal.toStringAsFixed(2),
    ]);

    pages.addAll([
      pw.Divider(thickness: 0.5, color: PdfColors.grey400),
      pw.Text(
        supplier.name.toUpperCase(),
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
          color: PdfColors.teal700,
        ),
      ),
      if (supplier.account != null && supplier.account!.isNotEmpty)
        pw.Text(
          'Account: ${supplier.account}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: ['Date', 'Sales Revenue (ETB)', 'Dues Paid to Supplier (ETB)'],
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
        cellStyle: const pw.TextStyle(fontSize: 8),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.teal50),
        data: supplierRows,
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      ),
      pw.SizedBox(height: 20),
    ]);
  }

  pages.add(
    pw.Center(
      child: pw.Text(
        'Generated by ShopSync',
        style: pw.TextStyle(
          fontSize: 8,
          fontStyle: pw.FontStyle.italic,
          color: PdfColors.grey500,
        ),
      ),
    ),
  );

  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pages,
    ),
  );

  final dir = await getTemporaryDirectory();
  final fileName =
      'weekly_report_${DateFormat('yyyyMMdd').format(from)}_${DateFormat('yyyyMMdd').format(to)}.pdf';
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(await pdf.save());

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      subject: 'ShopSync Weekly Report — $rangeLabel',
      text: 'Weekly dues and sales report',
    ),
  );
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

void _showSupplierDialog(
  BuildContext context,
  WidgetRef ref, [
  Supplier? existing,
]) {
  final nameController = TextEditingController(text: existing?.name);
  final contactController = TextEditingController(text: existing?.contact);
  final accountController = TextEditingController(text: existing?.account);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.98),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existing == null ? 'NEW SUPPLIER' : 'EDIT SUPPLIER',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                fontSize: 14,
                color: Color(0xFF818CF8),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              nameController,
              'Supplier Name',
              Icons.person_rounded,
              context,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              contactController,
              'Phone Number',
              Icons.phone_rounded,
              context,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              accountController,
              'Bank Account Details (Optional)',
              Icons.account_balance_rounded,
              context,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter supplier name'),
                      ),
                    );
                    return;
                  }
                  if (contactController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter phone number'),
                      ),
                    );
                    return;
                  }

                  final supplier = existing ?? Supplier();
                  supplier.name = nameController.text.trim();
                  supplier.contact = contactController.text.trim();
                  supplier.account = accountController.text.trim().isEmpty
                      ? null
                      : accountController.text.trim();

                  await ref
                      .read(supplierRepositoryProvider)
                      .saveSupplier(supplier);

                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(
                  existing == null ? 'SAVE SUPPLIER' : 'UPDATE SUPPLIER',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

Widget _buildTextField(
  TextEditingController controller,
  String label,
  IconData icon,
  BuildContext context,
) {
  return TextField(
    controller: controller,
    style: const TextStyle(fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF818CF8), size: 20),
      labelStyle: const TextStyle(
        color: Colors.white38,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
      ),
    ),
  );
}

class _SupplierCard extends ConsumerWidget {
  final Supplier supplier;
  const _SupplierCard({required this.supplier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBalance = supplier.balance > 0;
    final isActive = supplier.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          if (hasBalance && isActive)
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.05),
              blurRadius: 30,
              spreadRadius: 5,
            ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isActive
                ? () => _showSettlementDialog(context, ref, supplier)
                : null,
            child: Opacity(
              opacity: isActive ? 1.0 : 0.6,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color:
                                (isActive
                                        ? const Color(0xFF6366F1)
                                        : Colors.white10)
                                    .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  (isActive
                                          ? const Color(0xFF6366F1)
                                          : Colors.white10)
                                      .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            isActive
                                ? Icons.local_shipping_rounded
                                : Icons.pause_circle_rounded,
                            color: isActive
                                ? const Color(0xFF818CF8)
                                : Colors.white24,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supplier.name.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      supplier.contact ?? 'No contact',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (supplier.contact != null &&
                                      supplier.contact!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        final Uri launchUri = Uri(
                                          scheme: 'tel',
                                          path: supplier.contact,
                                        );
                                        if (await canLaunchUrl(launchUri)) {
                                          await launchUrl(launchUri);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF818CF8,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.phone_in_talk_rounded,
                                          size: 14,
                                          color: Color(0xFF818CF8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (supplier.account != null &&
                                  supplier.account!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.account_balance_rounded,
                                      size: 12,
                                      color: Colors.white38,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        supplier.account!,
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Quick actions
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.history_rounded,
                                  size: 16,
                                ),
                                color: Colors.white30,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                onPressed: () => _showSettlementHistory(
                                  context,
                                  ref,
                                  supplier,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.description_rounded,
                                  size: 16,
                                ),
                                color: isActive
                                    ? const Color(0xFF818CF8)
                                    : Colors.white12,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                onPressed: isActive
                                    ? () => _showPurchaseOrderDialog(
                                        context,
                                        ref,
                                        supplier,
                                      )
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                color: Colors.white30,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                onPressed: () =>
                                    _showSupplierDialog(context, ref, supplier),
                              ),
                              IconButton(
                                icon: Icon(
                                  supplier.isVoid
                                      ? Icons.restore_rounded
                                      : Icons.delete_sweep_rounded,
                                  size: 16,
                                ),
                                color: supplier.isVoid
                                    ? Colors.greenAccent
                                    : Colors.redAccent.withValues(alpha: 0.3),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                onPressed: () => supplier.isVoid
                                    ? _showRestoreSupplierDialog(
                                        context,
                                        ref,
                                        supplier,
                                      )
                                    : _showVoidSupplierDialog(
                                        context,
                                        ref,
                                        supplier,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status Toggle
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.scale(
                                scale: 0.7,
                                child: Switch(
                                  value: isActive,
                                  onChanged: (val) async {
                                    final updated = Supplier()
                                      ..id = supplier.id
                                      ..name = supplier.name
                                      ..contact = supplier.contact
                                      ..balance = supplier.balance
                                      ..isActive = val;
                                    await ref
                                        .read(supplierRepositoryProvider)
                                        .saveSupplier(updated);
                                  },
                                  activeThumbColor: const Color(0xFF818CF8),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  isActive ? 'ACTIVE' : 'PAUSED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: isActive
                                        ? const Color(0xFF818CF8)
                                        : Colors.white24,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Balance Display
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (hasBalance
                                          ? Colors.redAccent
                                          : Colors.greenAccent)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    (hasBalance
                                            ? Colors.redAccent
                                            : Colors.greenAccent)
                                        .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'BALANCE:',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color:
                                        (hasBalance
                                                ? Colors.redAccent
                                                : Colors.greenAccent)
                                            .withValues(alpha: 0.5),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${supplier.balance.toStringAsFixed(0)} ETB',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: hasBalance
                                          ? Colors.redAccent
                                          : Colors.greenAccent,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
            ),
          ),
        ),
      ),
    );
  }

  void _showRestoreSupplierDialog(
    BuildContext context,
    WidgetRef ref,
    Supplier s,
  ) {
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
          'RESTORE SUPPLIER?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
            color: Colors.greenAccent,
          ),
        ),
        content: Text(
          'Do you want to bring "${s.name.replaceFirst('[VOID] ', '')}" back to your active list?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
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
              await ref.read(supplierRepositoryProvider).unvoidSupplier(s.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'RESTORE',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVoidSupplierDialog(
    BuildContext context,
    WidgetRef ref,
    Supplier s,
  ) {
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
          'VOID SUPPLIER?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
            color: Color(0xFFEF4444),
          ),
        ),
        content: const Text(
          'This will hide the supplier from your daily view. You can restore them later by toggling "Show Archived" in the top menu.',
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
              await ref.read(supplierRepositoryProvider).voidSupplier(s.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'VOID',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettlementDialog(
    BuildContext context,
    WidgetRef ref,
    Supplier supplier,
  ) {
    final amountController = TextEditingController();
    String? selectedImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.98),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'SETTLE: ${supplier.name.toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  fontSize: 14,
                  color: Color(0xFF818CF8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Current Debt:',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${supplier.balance.toStringAsFixed(0)} ETB',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (supplier.balance != 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        amountController.text = supplier.balance
                            .toStringAsFixed(0);
                      },
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                      label: const Text('SETTLE FULL BALANCE'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Payment Amount',
                  prefixText: 'ETB ',
                  prefixIcon: const Icon(
                    Icons.payments_rounded,
                    color: Color(0xFF818CF8),
                    size: 20,
                  ),
                  labelStyle: const TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFF6366F1),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'PROOF OF PAYMENT (OPTIONAL)',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (selectedImagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(selectedImagePath!),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        final appDir = await getApplicationDocumentsDirectory();
                        final localFile = File(
                          '${appDir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
                        );
                        await File(image.path).copy(localFile.path);

                        setDialogState(() {
                          selectedImagePath = localFile.path;
                        });
                      }
                    },
                    icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                    label: Text(
                      selectedImagePath == null
                          ? 'ATTACH RECEIPT'
                          : 'CHANGE RECEIPT',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  if (selectedImagePath != null) ...[
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          selectedImagePath = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter valid amount'),
                        ),
                      );
                      return;
                    }

                    if (amount > supplier.balance + 0.01) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Amount exceeds current balance'),
                        ),
                      );
                      return;
                    }

                    await ref
                        .read(supplierRepositoryProvider)
                        .updateBalance(supplier.id, -amount);

                    final settlement = SupplierSettlement()
                      ..supplierId = supplier.id
                      ..amount = amount
                      ..date = DateTime.now()
                      ..imagePath = selectedImagePath;

                    await ref
                        .read(supplierRepositoryProvider)
                        .recordSettlement(settlement);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment of ${amount.toStringAsFixed(0)} ETB recorded',
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded),
                      SizedBox(width: 12),
                      Text(
                        'CONFIRM PAYMENT',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettlementHistory(
    BuildContext context,
    WidgetRef ref,
    Supplier supplier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.98),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final repo = ref.read(supplierRepositoryProvider);
          return StreamBuilder<List<SupplierSettlement>>(
            stream: repo.watchSettlements(supplier.id),
            builder: (context, snapshot) {
              final settlements = snapshot.data ?? [];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SETTLEMENT HISTORY',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  fontSize: 14,
                                  color: Color(0xFF818CF8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                supplier.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: settlements.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 48,
                                    color: Colors.white24,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'NO SETTLEMENTS RECORDED YET',
                                    style: TextStyle(
                                      color: Colors.white30,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: settlements.length,
                              itemBuilder: (context, index) {
                                final settlement = settlements[index];
                                final df = DateFormat('MMM dd, yyyy - hh:mm a');
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Color(0xFF10B981),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${settlement.amount.toStringAsFixed(0)} ETB',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              df.format(settlement.date),
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (settlement.imagePath != null) ...[
                                        GestureDetector(
                                          onTap: () {
                                            _viewReceiptPhoto(
                                              context,
                                              settlement.imagePath!,
                                            );
                                          },
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.white10,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.file(
                                                File(settlement.imagePath!),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      IconButton(
                                        icon: const Icon(
                                          Icons.share_rounded,
                                          color: Colors.white30,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          ReceiptShareService.shareSettlementReceipt(
                                            settlement: settlement,
                                            supplier: supplier,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _viewReceiptPhoto(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPurchaseOrderDialog(
    BuildContext context,
    WidgetRef ref,
    Supplier supplier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.98),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final productsAsync = ref.watch(productsProvider);
          final availabilityAsync = ref.watch(
            walkInAvailabilityProvider(DateTime.now()),
          );

          return productsAsync.when(
            data: (products) => availabilityAsync.when(
              data: (availability) {
                final supplierProducts = products.where((p) {
                  if (p.isVoid || p.supplierId != supplier.id) return false;
                  final status = availability[p.id];
                  if (status == null) return false;
                  return status.walkInAvailable < p.minStockThreshold;
                }).toList();

                if (supplierProducts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFF10B981),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ALL ITEMS FULLY STOCKED',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No products from ${supplier.name} are currently below their minimum threshold.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CLOSE'),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _PurchaseOrderDialogBody(
                  supplier: supplier,
                  products: supplierProducts,
                  availability: availability,
                  ref: ref,
                );
              },
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error loading availability: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
            loading: () => const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error loading products: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PurchaseOrderDialogBody extends StatefulWidget {
  final Supplier supplier;
  final List<Product> products;
  final Map<int, StockStatus> availability;
  final WidgetRef ref;

  const _PurchaseOrderDialogBody({
    required this.supplier,
    required this.products,
    required this.availability,
    required this.ref,
  });

  @override
  State<_PurchaseOrderDialogBody> createState() =>
      _PurchaseOrderDialogBodyState();
}

class _PurchaseOrderDialogBodyState extends State<_PurchaseOrderDialogBody> {
  final Map<int, double> _orderQuantities = {};
  final Map<int, TextEditingController> _controllers = {};
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    for (var p in widget.products) {
      final status = widget.availability[p.id];
      final currentStock = status?.walkInAvailable ?? 0.0;
      final defaultQty = (p.minStockThreshold * 2 - currentStock).clamp(
        1.0,
        999.0,
      );
      _orderQuantities[p.id] = defaultQty;
      _controllers[p.id] = TextEditingController(
        text: defaultQty.toStringAsFixed(0),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _totalEstimatedCost {
    double total = 0.0;
    for (var p in widget.products) {
      final qty = _orderQuantities[p.id] ?? 0.0;
      total += qty * p.costPrice;
    }
    return total;
  }

  int get _totalItemsCount {
    int count = 0;
    for (var qty in _orderQuantities.values) {
      if (qty > 0) count++;
    }
    return count;
  }

  Future<void> _generateAndSharePDF() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'SHOPSYNC',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.indigo,
                            ),
                          ),
                          pw.Text(
                            'Supplier Purchase Order',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            'PO Number: PO-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 20),

                  pw.Text(
                    'TO SUPPLIER:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    widget.supplier.name.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (widget.supplier.contact != null &&
                      widget.supplier.contact!.isNotEmpty)
                    pw.Text(
                      'Phone: ${widget.supplier.contact}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (widget.supplier.account != null &&
                      widget.supplier.account!.isNotEmpty)
                    pw.Text(
                      'Account Details: ${widget.supplier.account}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  pw.SizedBox(height: 24),

                  pw.TableHelper.fromTextArray(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 0.5,
                    ),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.indigo,
                    ),
                    cellAlignment: pw.Alignment.centerLeft,
                    headerAlignment: pw.Alignment.centerLeft,
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FixedColumnWidth(80),
                      2: const pw.FixedColumnWidth(80),
                      3: const pw.FixedColumnWidth(80),
                      4: const pw.FixedColumnWidth(90),
                    },
                    headers: [
                      'Product Item',
                      'Unit Cost',
                      'Current Stock',
                      'Order Qty',
                      'Total Cost',
                    ],
                    data: widget.products
                        .where((p) => (_orderQuantities[p.id] ?? 0) > 0)
                        .map((p) {
                          final qty = _orderQuantities[p.id] ?? 0.0;
                          final status = widget.availability[p.id];
                          final currentStock = status?.walkInAvailable ?? 0.0;
                          final total = qty * p.costPrice;
                          return [
                            p.name,
                            'ETB ${p.costPrice.toStringAsFixed(0)}',
                            currentStock.toStringAsFixed(0),
                            qty.toStringAsFixed(0),
                            'ETB ${total.toStringAsFixed(0)}',
                          ];
                        })
                        .toList(),
                  ),
                  pw.SizedBox(height: 20),

                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Container(
                      width: 200,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Total Items:',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                              pw.Text(
                                '$_totalItemsCount',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Est. Total Cost:',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 11,
                                  color: PdfColors.indigo,
                                ),
                              ),
                              pw.Text(
                                'ETB ${_totalEstimatedCost.toStringAsFixed(0)}',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 11,
                                  color: PdfColors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Spacer(),

                  pw.Center(
                    child: pw.Text(
                      'Generated automatically by ShopSync. Thank you for your business.',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/PO_${widget.supplier.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Purchase Order from ShopSync for ${widget.supplier.name}',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.assignment_rounded,
                color: Color(0xFF818CF8),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'PO: ${widget.supplier.name.toUpperCase()}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'The following items are currently below their minimum safety thresholds. Adjust reorder quantities below.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.products.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.white.withValues(alpha: 0.05),
                height: 20,
              ),
              itemBuilder: (context, index) {
                final p = widget.products[index];
                final status = widget.availability[p.id];
                final currentStock = status?.walkInAvailable ?? 0.0;
                final qty = _orderQuantities[p.id] ?? 0.0;
                final cost = qty * p.costPrice;

                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Stock: ${currentStock.toStringAsFixed(0)} / Min: ${p.minStockThreshold}',
                                style: const TextStyle(
                                  color: Colors.white30,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '• Cost: ETB ${p.costPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white30,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              final currentVal = _orderQuantities[p.id] ?? 0.0;
                              final newVal = (currentVal - 1).clamp(0.0, 999.0);
                              _orderQuantities[p.id] = newVal;
                              _controllers[p.id]?.text = newVal.toStringAsFixed(
                                0,
                              );
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.remove,
                              size: 14,
                              color: Colors.white60,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 45,
                          child: TextField(
                            controller: _controllers[p.id],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 6),
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              final doubleVal = double.tryParse(val) ?? 0.0;
                              setState(() {
                                _orderQuantities[p.id] = doubleVal;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              final currentVal = _orderQuantities[p.id] ?? 0.0;
                              final newVal = (currentVal + 1).clamp(0.0, 999.0);
                              _orderQuantities[p.id] = newVal;
                              _controllers[p.id]?.text = newVal.toStringAsFixed(
                                0,
                              );
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 14,
                              color: Colors.white60,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 70,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'ETB ${cost.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: cost > 0
                                ? const Color(0xFF10B981)
                                : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_totalItemsCount products selected',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ESTIMATED TOTAL',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 9,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Text(
                  'ETB ${_totalEstimatedCost.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: (_totalItemsCount > 0 && !_isGenerating)
                  ? _generateAndSharePDF
                  : null,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.share_rounded, size: 16),
              label: Text(
                _isGenerating ? 'GENERATING PDF...' : 'GENERATE & SHARE PO',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
