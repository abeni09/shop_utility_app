import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_settlement_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_model.dart';
import 'package:shopsync/features/products/data/stock_adjustment_model.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/expenses/data/expense_model.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';

class ReceiptShareService {
  static String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  static String _generateTextReceipt({
    required CustomerOrder order,
    required String productName,
  }) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final totalBase = order.amount * order.sellingPriceAtTime;
    final totalAddon = (order.addonAmount ?? 0.0) * (order.addonPrice ?? 0.0);
    final totalAmount = totalBase + totalAddon;
    final balanceDue = totalAmount - order.advancePayment;

    final buffer = StringBuffer();
    buffer.writeln('==================================');
    buffer.writeln('            SHOP SYNC            ');
    buffer.writeln('         DIGITAL RECEIPT         ');
    buffer.writeln('==================================');
    buffer.writeln('Date:      ${df.format(order.dueDate)}');
    buffer.writeln('Receipt #: ${order.id}');
    buffer.writeln('Customer:  ${order.customerName}');
    if (order.phoneNumber != null && order.phoneNumber!.isNotEmpty) {
      buffer.writeln('Phone:     ${order.phoneNumber}');
    }
    buffer.writeln('Status:    ${order.status.name.toUpperCase()}');
    buffer.writeln('----------------------------------');
    buffer.writeln('Item:      $productName');
    buffer.writeln('Qty:       ${order.amount.toStringAsFixed(0)}');
    buffer.writeln('Price:     ${_formatCurrency(order.sellingPriceAtTime)}');
    buffer.writeln('Subtotal:  ${_formatCurrency(totalBase)}');

    if (order.addonName != null && order.addonName!.isNotEmpty) {
      buffer.writeln('----------------------------------');
      buffer.writeln('Add-on:    ${order.addonName}');
      buffer.writeln('Add-on Qty:${order.addonAmount?.toStringAsFixed(0)}');
      buffer.writeln('Add-on Prc:${_formatCurrency(order.addonPrice ?? 0.0)}');
      buffer.writeln('Add-on Sub:${_formatCurrency(totalAddon)}');
    }

    buffer.writeln('==================================');
    buffer.writeln('TOTAL:     ${_formatCurrency(totalAmount)}');
    buffer.writeln('Paid Adv:  ${_formatCurrency(order.advancePayment)}');
    buffer.writeln('Balance:   ${_formatCurrency(balanceDue)}');
    buffer.writeln('Payment:   ${order.paymentMethod.name.toUpperCase()}');
    buffer.writeln('================================--');
    buffer.writeln('    Thank you for shopping!      ');
    buffer.writeln('==================================');

    return buffer.toString();
  }

  static Future<void> shareTextReceipt({
    required CustomerOrder order,
    required String productName,
  }) async {
    final text = _generateTextReceipt(order: order, productName: productName);
    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'ShopSync Receipt #${order.id}'),
    );
  }

  static Future<void> sharePdfReceipt({
    required CustomerOrder order,
    required String productName,
  }) async {
    final pdf = pw.Document();
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final totalBase = order.amount * order.sellingPriceAtTime;
    final totalAddon = (order.addonAmount ?? 0.0) * (order.addonPrice ?? 0.0);
    final totalAmount = totalBase + totalAddon;
    final balanceDue = totalAmount - order.advancePayment;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'SHOP SYNC',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'OFFICIAL INVOICE',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.Text(
                  'Date: ${df.format(order.dueDate)}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  'Receipt #: ${order.id}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  'Customer: ${order.customerName}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                if (order.phoneNumber != null && order.phoneNumber!.isNotEmpty)
                  pw.Text(
                    'Phone: ${order.phoneNumber}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                pw.Text(
                  'Status: ${order.status.name.toUpperCase()}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Divider(thickness: 1, color: PdfColors.grey400),

                // Item table
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Item Description',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                    pw.Text(
                      'Total',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '$productName (x${order.amount.toStringAsFixed(0)})',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      _formatCurrency(totalBase),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
                if (order.addonName != null && order.addonName!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '+ ${order.addonName} (x${order.addonAmount?.toStringAsFixed(0)})',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        _formatCurrency(totalAddon),
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],

                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL AMOUNT:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                    pw.Text(
                      _formatCurrency(totalAmount),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Advance Paid:',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      _formatCurrency(order.advancePayment),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Balance Due:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8,
                        color: PdfColors.red900,
                      ),
                    ),
                    pw.Text(
                      _formatCurrency(balanceDue),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8,
                        color: PdfColors.red900,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Payment Method: ${order.paymentMethod.name.toUpperCase()}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/receipt_${order.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Here is your receipt from ShopSync.',
        subject: 'ShopSync Receipt #${order.id}',
      ),
    );
  }

  static Future<void> shareSettlementReceipt({
    required SupplierSettlement settlement,
    required Supplier supplier,
  }) async {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final buffer = StringBuffer();
    buffer.writeln('==================================');
    buffer.writeln('            SHOP SYNC            ');
    buffer.writeln('       SUPPLIER SETTLEMENT       ');
    buffer.writeln('==================================');
    buffer.writeln('Date:       ${df.format(settlement.date)}');
    buffer.writeln('Supplier:   ${supplier.name}');
    if (supplier.account != null && supplier.account!.isNotEmpty) {
      buffer.writeln('Bank Acc:   ${supplier.account}');
    }
    buffer.writeln('Settled Amt:${_formatCurrency(settlement.amount)}');
    buffer.writeln('==================================');
    buffer.writeln('Settlement processed successfully.');
    buffer.writeln('==================================');

    if (settlement.imagePath != null && settlement.imagePath!.isNotEmpty) {
      final file = File(settlement.imagePath!);
      if (await file.exists()) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: buffer.toString(),
            subject: 'Settlement Proof - ${supplier.name}',
          ),
        );
        return;
      }
    }

    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: 'Settlement Details - ${supplier.name}',
      ),
    );
  }

  static Future<void> shareDailyLedger({
    required DateTime date,
    required List<CustomerOrder> sales,
    required List<StockAdjustment> adjustments,
    required List<Product> products,
    required List<Expense> expenses,
  }) async {
    final df = DateFormat('yyyy-MM-dd');
    final dtf = DateFormat('HH:mm');
    final dateLabel = df.format(date);

    // Compute totals
    final totalRevenue = sales.fold<double>(
      0,
      (s, o) => s + o.amount * o.sellingPriceAtTime,
    );
    final totalCogs = sales.fold<double>(
      0,
      (s, o) => s + o.amount * o.costPriceAtTime,
    );
    final grossProfit = totalRevenue - totalCogs;

    double totalLoss = 0.0;
    for (final adj in adjustments) {
      final p = products.firstWhere(
        (pr) => pr.id == adj.productId,
        orElse: () => Product(),
      );
      totalLoss += adj.amount.abs() * p.costPrice;
    }

    final totalExpenses = expenses.fold<double>(
      0,
      (s, e) => s + e.amount,
    );
    final netProfit = grossProfit - totalLoss - totalExpenses;

    String productNameFor(int productId) {
      return products
          .firstWhere(
            (p) => p.id == productId,
            orElse: () => Product()..name = 'Unknown',
          )
          .name;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => [
          // Header
          pw.Center(
            child: pw.Text(
              'SHOPSYNC — DAILY LEDGER',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
            ),
          ),
          pw.Center(
            child: pw.Text(
              dateLabel,
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1.5),
          // Summary
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _summaryBox('REVENUE', totalRevenue, PdfColors.green800),
              _summaryBox(
                'GROSS PROFIT',
                grossProfit,
                grossProfit >= 0 ? PdfColors.indigo700 : PdfColors.red700,
              ),
              _summaryBox('EXPENSES', totalExpenses, PdfColors.orange800),
              _summaryBox('LOSSES', totalLoss, PdfColors.red700),
              _summaryBox(
                'NET',
                netProfit,
                netProfit >= 0 ? PdfColors.teal700 : PdfColors.red900,
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Text(
            'TRANSACTIONS (${sales.length})',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Time', 'Customer', 'Product', 'Qty', 'Price', 'Total'],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            data: sales
                .map(
                  (o) => [
                    dtf.format(o.fulfilledAt ?? o.dueDate),
                    o.customerName.isEmpty ? '-' : o.customerName,
                    productNameFor(o.productId),
                    o.amount.toStringAsFixed(0),
                    o.sellingPriceAtTime.toStringAsFixed(2),
                    (o.amount * o.sellingPriceAtTime).toStringAsFixed(2),
                  ],
                )
                .toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
          if (expenses.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.Text(
              'OPERATIONAL EXPENSES (${expenses.length})',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.orange800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Description', 'Recurrence', 'Amount'],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange50),
              data: expenses.map((e) {
                return [
                  e.description,
                  e.recurrence.name.toUpperCase(),
                  e.amount.toStringAsFixed(2),
                ];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
          ],
          if (adjustments.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.Text(
              'INVENTORY LOSSES (${adjustments.length})',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.red700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Product', 'Qty Lost', 'Cost/Unit', 'Loss Value'],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.red50),
              data: adjustments.map((adj) {
                final p = products.firstWhere(
                  (pr) => pr.id == adj.productId,
                  orElse: () => Product()..name = 'Unknown',
                );
                return [
                  p.name,
                  adj.amount.abs().toStringAsFixed(0),
                  p.costPrice.toStringAsFixed(2),
                  (adj.amount.abs() * p.costPrice).toStringAsFixed(2),
                ];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
          ],
          pw.SizedBox(height: 20),
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
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ledger_$dateLabel.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'ShopSync Daily Ledger — $dateLabel',
        text: 'Daily ledger for $dateLabel',
      ),
    );
  }

  static Future<void> shareReceivingReport({
    required DateTime start,
    required DateTime end,
    required List<ReceivingReportItem> items,
    required bool groupBySupplier,
  }) async {
    final df = DateFormat('yyyy-MM-dd');
    final startLabel = df.format(start);
    final endLabel = df.format(end);
    final periodLabel = '$startLabel to $endLabel';

    final totalUnits = items.fold<double>(0, (sum, i) => sum + i.quantity);
    final totalCost = items.fold<double>(0, (sum, i) => sum + i.totalCost);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          final List<pw.Widget> content = [
            // Header
            pw.Center(
              child: pw.Text(
                'SHOPSYNC — RECEIVING REPORT',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Period: $periodLabel',
                style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1.5),
            // Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _summaryBox('TOTAL UNITS RECEIVED', totalUnits, PdfColors.teal800),
                pw.SizedBox(width: 20),
                _summaryBox('TOTAL COST OF STOCK', totalCost, PdfColors.indigo800),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
          ];

          if (groupBySupplier) {
            // Group items by supplierName
            final Map<String, List<ReceivingReportItem>> groupedBySupplier = {};
            for (var item in items) {
              groupedBySupplier.putIfAbsent(item.supplierName, () => []).add(item);
            }

            content.add(
              pw.Text(
                'RECEIVED STOCK BY SUPPLIER (${groupedBySupplier.length} Suppliers)',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            );
            content.add(pw.SizedBox(height: 8));

            for (var supplierName in groupedBySupplier.keys) {
              final supplierItems = groupedBySupplier[supplierName]!;
              final supplierTotalUnits = supplierItems.fold<double>(0, (sum, i) => sum + i.quantity);
              final supplierTotalCost = supplierItems.fold<double>(0, (sum, i) => sum + i.totalCost);

              content.addAll([
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        supplierName.toUpperCase(),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                      ),
                      pw.Text(
                        'Received: ${supplierTotalUnits.toStringAsFixed(1)} units • Cost: \$${supplierTotalCost.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.TableHelper.fromTextArray(
                  headers: ['Date', 'Item Description', 'Qty', 'Cost/Unit', 'Total Cost'],
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 7,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 7),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                  data: supplierItems
                      .map(
                        (i) => [
                          df.format(i.date),
                          i.productName,
                          i.quantity.toStringAsFixed(1),
                          i.costPrice.toStringAsFixed(2),
                          i.totalCost.toStringAsFixed(2),
                        ],
                      )
                      .toList(),
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                ),
              ]);
            }
          } else {
            // Group items by product name
            final Map<String, List<ReceivingReportItem>> groupedByProduct = {};
            for (var item in items) {
              groupedByProduct.putIfAbsent(item.productName, () => []).add(item);
            }

            content.add(
              pw.Text(
                'RECEIVED STOCK BY INVENTORY ITEM (${groupedByProduct.length} Items)',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            );
            content.add(pw.SizedBox(height: 8));

            for (var productName in groupedByProduct.keys) {
              final productItems = groupedByProduct[productName]!;
              final productTotalUnits = productItems.fold<double>(0, (sum, i) => sum + i.quantity);
              final productTotalCost = productItems.fold<double>(0, (sum, i) => sum + i.totalCost);

              content.addAll([
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        productName.toUpperCase(),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                      ),
                      pw.Text(
                        'Received: ${productTotalUnits.toStringAsFixed(1)} units • Cost: \$${productTotalCost.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.TableHelper.fromTextArray(
                  headers: ['Date', 'Supplier', 'Qty', 'Cost/Unit', 'Total Cost'],
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 7,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 7),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                  data: productItems
                      .map(
                        (i) => [
                          df.format(i.date),
                          i.supplierName,
                          i.quantity.toStringAsFixed(1),
                          i.costPrice.toStringAsFixed(2),
                          i.totalCost.toStringAsFixed(2),
                        ],
                      )
                      .toList(),
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                ),
              ]);
            }
          }

          content.addAll([
            pw.SizedBox(height: 20),
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
          ]);

          return content;
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/receiving_report_${startLabel}_$endLabel.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'ShopSync Receiving Report ($periodLabel)',
        text: 'Receiving Report from $startLabel to $endLabel',
      ),
    );
  }

  static pw.Widget _summaryBox(String label, double amount, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 7,
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            amount.toStringAsFixed(2),
            style: pw.TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
