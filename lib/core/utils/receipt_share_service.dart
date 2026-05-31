import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_settlement_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_model.dart';

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
    await Share.share(text, subject: 'ShopSync Receipt #${order.id}');
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
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
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
                pw.Text('Date: ${df.format(order.dueDate)}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Receipt #: ${order.id}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Customer: ${order.customerName}', style: const pw.TextStyle(fontSize: 9)),
                if (order.phoneNumber != null && order.phoneNumber!.isNotEmpty)
                  pw.Text('Phone: ${order.phoneNumber}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Status: ${order.status.name.toUpperCase()}', style: const pw.TextStyle(fontSize: 9)),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                
                // Item table
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('$productName (x${order.amount.toStringAsFixed(0)})', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(_formatCurrency(totalBase), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                if (order.addonName != null && order.addonName!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('+ ${order.addonName} (x${order.addonAmount?.toStringAsFixed(0)})', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(_formatCurrency(totalAddon), style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
                
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL AMOUNT:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text(_formatCurrency(totalAmount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Advance Paid:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(_formatCurrency(order.advancePayment), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Balance Due:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.red900)),
                    pw.Text(_formatCurrency(balanceDue), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.red900)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text('Payment Method: ${order.paymentMethod.name.toUpperCase()}', style: const pw.TextStyle(fontSize: 8)),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 8),
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

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Here is your receipt from ShopSync.',
      subject: 'ShopSync Receipt #${order.id}',
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
        await Share.shareXFiles(
          [XFile(file.path)],
          text: buffer.toString(),
          subject: 'Settlement Proof - ${supplier.name}',
        );
        return;
      }
    }

    await Share.share(
      buffer.toString(),
      subject: 'Settlement Details - ${supplier.name}',
    );
  }
}
