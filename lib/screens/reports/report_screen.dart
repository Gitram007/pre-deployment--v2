import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../utils/exporter.dart';
import 'dart:html' as html;

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedReportType = 'overall'; // 'overall', 'by_product', or 'overall_report'
  String _selectedFrequency = 'daily'; // 'daily', 'weekly', 'monthly'
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).clearReports();
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  void _generateReport() {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    // Calculate and set the date range string
    final now = DateTime.now();
    final formatter = DateFormat.yMd();
    final endDate = formatter.format(now);
    String startDate;

    if (_selectedFrequency == 'daily') {
      startDate = formatter.format(now.subtract(const Duration(days: 1)));
    } else if (_selectedFrequency == 'weekly') {
      startDate = formatter.format(now.subtract(const Duration(days: 7)));
    } else { // monthly
      startDate = formatter.format(now.subtract(const Duration(days: 30)));
    }

    // Fetch the report data
    if (_selectedReportType == 'overall') {
      reportProvider.fetchOverallMaterialUsage(_selectedFrequency);
    } else if (_selectedReportType == 'overall_report') {
      reportProvider.fetchOverallReport(_selectedFrequency);
    } else {
      if (_selectedProduct != null) {
        reportProvider.fetchMaterialUsageByProduct(_selectedProduct!.id, _selectedFrequency);
      } else {
        // Show an error or prompt to select a product
      }
    }
  }

  void _exportToCsv() {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final Map<String, dynamic> reportData;
    switch (_selectedReportType) {
      case 'overall_report':
        reportData = reportProvider.overallReport;
        break;
      case 'overall':
        reportData = reportProvider.overallMaterialUsage;
        break;
      default: // 'by_product'
        reportData = reportProvider.materialUsage;
    }

    if (reportData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export.')),
      );
      return;
    }

    final List<List<dynamic>> rows = [];
    if (_selectedReportType == 'overall_report') {
      rows.add(['Material', 'Inward', 'Usage', 'Balance']);
      (reportData as Map<String, dynamic>).forEach((key, value) {
        rows.add([key, value['inward'], value['usage'], value['balance']]);
      });
    } else {
      rows.add(['Material', 'Usage']);
      (reportData as Map<String, dynamic>).forEach((key, value) {
        rows.add([key, value]);
      });
    }

    String csv = rows.map((row) => row.map((item) {
      String value = item.toString().replaceAll('"', '""');
      return '"$value"';
    }).join(',')).join('\n');

    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "report.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _exportToPdf() {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final Map<String, dynamic> reportData;
    switch (_selectedReportType) {
      case 'overall_report':
        reportData = reportProvider.overallReport;
        break;
      case 'overall':
        reportData = reportProvider.overallMaterialUsage;
        break;
      default: // 'by_product'
        reportData = reportProvider.materialUsage;
    }

    if (reportData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export.')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('<html><head><title>Report</title>');
    buffer.writeln('<style>table { border-collapse: collapse; width: 100%; } th, td { border: 1px solid black; padding: 8px; text-align: left; }</style>');
    buffer.writeln('</head><body><h1>Report</h1>');
    buffer.writeln('<table>');

    if (_selectedReportType == 'overall_report') {
      buffer.writeln('<tr><th>Material</th><th>Inward</th><th>Usage</th><th>Balance</th></tr>');
      (reportData as Map<String, dynamic>).forEach((key, value) {
        buffer.writeln('<tr><td>$key</td><td>${value['inward']}</td><td>${value['usage']}</td><td>${value['balance']}</td></tr>');
      });
    } else {
      buffer.writeln('<tr><th>Material</th><th>Usage</th></tr>');
      (reportData as Map<String, dynamic>).forEach((key, value) {
        buffer.writeln('<tr><td>$key</td><td>$value</td></tr>');
      });
    }

    buffer.writeln('</table>');
    buffer.writeln('<script>window.onload = function() { window.print(); }</script>');
    buffer.writeln('</body></html>');

    final blob = html.Blob([buffer.toString()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final reportProvider = Provider.of<ReportProvider>(context);
    final Map<String, dynamic> reportData;
    switch (_selectedReportType) {
      case 'overall_report':
        reportData = reportProvider.overallReport;
        break;
      case 'overall':
        reportData = reportProvider.overallMaterialUsage;
        break;
      default: // 'by_product'
        reportData = reportProvider.materialUsage;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Report selection controls
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedReportType,
                    items: const [
                      DropdownMenuItem(value: 'overall', child: Text('Overall Usage')),
                      DropdownMenuItem(value: 'by_product', child: Text('Usage by Product')),
                      DropdownMenuItem(value: 'overall_report', child: Text('Overall Report')),
                    ],
                    onChanged: (value) => setState(() => _selectedReportType = value!),
                  ),
                ),
                const SizedBox(width: 10),
                if (_selectedReportType == 'by_product')
                  Expanded(
                    child: DropdownButtonFormField<Product>(
                      hint: const Text('Select Product'),
                      value: _selectedProduct,
                      items: productProvider.products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                      onChanged: (value) => setState(() => _selectedProduct = value),
                    ),
                  ),
              ],
            ),
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (value) => setState(() => _selectedFrequency = value!),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _generateReport,
                  child: const Text('Generate Report'),
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Export as CSV',
                  onPressed: _exportToCsv,
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Export as PDF',
                  onPressed: _exportToPdf,
                ),
              ],
            ),
            const Divider(),
            Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final formatter = DateFormat.yMd();
                  final endDate = formatter.format(now);
                  String startDate;

                  if (_selectedFrequency == 'daily') {
                    startDate = formatter.format(now.subtract(const Duration(days: 1)));
                  } else if (_selectedFrequency == 'weekly') {
                    startDate = formatter.format(now.subtract(const Duration(days: 7)));
                  } else { // monthly
                    startDate = formatter.format(now.subtract(const Duration(days: 30)));
                  }
                  final dateRangeText = 'Report for: $startDate - $endDate';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      dateRangeText,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
            ),
            // Report display
            Expanded(
              child: reportProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : reportData.isEmpty
                  ? const Center(child: Text('No report generated.'))
                  : ListView(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _selectedReportType == 'overall_report'
                        ? DataTable(
                      columns: const [
                        DataColumn(label: Text('Material')),
                        DataColumn(label: Text('Inward')),
                        DataColumn(label: Text('Usage')),
                        DataColumn(label: Text('Balance')),
                      ],
                      rows: (reportData as Map<String, dynamic>).entries.map((entry) {
                        return DataRow(cells: [
                          DataCell(Text(entry.key)),
                          DataCell(Text(entry.value['inward'].toString())),
                          DataCell(Text(entry.value['usage'].toString())),
                          DataCell(Text(entry.value['balance'].toString())),
                        ]);
                      }).toList(),
                    )
                        : DataTable(
                      columns: const [
                        DataColumn(label: Text('Material')),
                        DataColumn(label: Text('Usage')),
                      ],
                      rows: (reportData as Map<String, dynamic>).entries.map((entry) {
                        return DataRow(cells: [
                          DataCell(Text(entry.key)),
                          DataCell(Text(entry.value.toString())),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
