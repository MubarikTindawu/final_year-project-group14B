import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/crop_model.dart';
import '../models/inventory_model.dart';

class ReportService {
  // --- EXISTING FINANCE REPORT ---
  static Future<void> generateFarmReport({
    required List<TransactionModel> transactions,
    required List<CropModel> crops,
    required double totalIncome,
    required double totalExpense,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader("Operational & Financial Report", dateStr),
          pw.SizedBox(height: 20),
          _buildFinancialSummary(totalIncome, totalExpense),
          pw.SizedBox(height: 30),
          _buildSectionTitle("Current Crop Inventory"),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
            headers: ['Crop', 'Variety', 'Acres', 'Days Left'],
            data: crops.map((c) => [c.name, c.variety, c.area.toString(), "${c.daysRemaining} days"]).toList(),
          ),
          pw.SizedBox(height: 30),
          _buildSectionTitle("Recent Transactions"),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
            headers: ['Date', 'Category', 'Type', 'Amount'],
            data: transactions.map((t) => [
              DateFormat('yMd').format(t.date),
              t.category,
              t.isIncome ? "Income" : "Expense",
              "GHS ${t.amount.toStringAsFixed(2)}"
            ]).toList(),
          ),
          _buildFooter(),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Farm_Report_$dateStr.pdf');
  }

  // --- NEW: INVENTORY STOCK REPORT ---
  static Future<void> generateInventoryReport(List<InventoryModel> items) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM, yyyy').format(DateTime.now());
    final lowStockCount = items.where((i) => i.quantity <= i.minThreshold).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader("Stock Inventory & Analysis", dateStr),
          pw.SizedBox(height: 20),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox("Total Items", "${items.length}", PdfColors.grey100),
              _buildStatBox("Alerts", "$lowStockCount", lowStockCount > 0 ? PdfColors.red50 : PdfColors.green50),
            ],
          ),
          pw.SizedBox(height: 30),

          _buildSectionTitle("Inventory Breakdown"),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
            headers: ['Item Name', 'Category', 'Stock Qty', 'Unit', 'Status'],
            data: items.map((item) {
              final isLow = item.quantity <= item.minThreshold;
              return [
                item.itemName,
                item.category,
                item.quantity.toStringAsFixed(1),
                item.unit,
                isLow ? "LOW STOCK" : "STABLE"
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 50),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSignatureSpace("Store Keeper"),
              _buildSignatureSpace("Farm Manager"),
            ],
          ),
          _buildFooter(),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Inventory_Report_$dateStr.pdf');
  }

  // --- REUSABLE WIDGETS ---

  static pw.Widget _buildHeader(String title, String date) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("GROUP 14B FARM MANAGER", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
            pw.Text(title, style: const pw.TextStyle(fontSize: 14)),
          ],
        ),
        pw.Text(date),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _buildFinancialSummary(double income, double expense) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildPdfStat("Income", "GHS ${income.toStringAsFixed(2)}"),
          _buildPdfStat("Expenses", "GHS ${expense.toStringAsFixed(2)}"),
          _buildPdfStat("Balance", "GHS ${(income - expense).toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      ]),
    );
  }

  // FIXED: Moved border into pw.BoxDecoration
  static pw.Widget _buildSignatureSpace(String title) {
    return pw.Column(children: [
      pw.Container(
        width: 150,
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
        ),
      ),
      pw.SizedBox(height: 5),
      pw.Text(title),
    ]);
  }

  static pw.Widget _buildFooter() {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 40),
      child: pw.Center(
        child: pw.Text("End of Report - Generated by Group 14B Farm Manager", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
      ),
    );
  }

  static pw.Widget _buildPdfStat(String label, String value) {
    return pw.Column(children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
      pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
    ]);
  }
}