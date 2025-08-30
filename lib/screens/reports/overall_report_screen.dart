import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import 'dart:html' as html;

class OverallReportScreen extends StatefulWidget {
  const OverallReportScreen({super.key});

  @override
  _OverallReportScreenState createState() => _OverallReportScreenState();
}

class _OverallReportScreenState extends State<OverallReportScreen> {
  String _selectedFrequency = 'daily';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).clearReports();
    });
  }

  void _exportToCsv() {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final reportData = reportProvider.overallReport;

    if (reportData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export.')),
      );
      return;
    }

    final List<List<dynamic>> rows = [];
    // Add header row
    rows.add(['Material', 'Inward', 'Usage', 'Balance']);
    // Add data rows
    reportData.forEach((key, value) {
      rows.add([
        key,
        value['inward'],
        value['usage'],
        value['balance'],
      ]);
    });

    // Manually convert to CSV string
    String csv = rows.map((row) => row.map((item) {
      // Handle commas and quotes by wrapping in double quotes
      String value = item.toString().replaceAll('"', '""');
      return '"$value"';
    }).join(',')).join('\n');

    // Create a blob and trigger a download
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "overall_report.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _exportToPdf() {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final reportData = reportProvider.overallReport;

    if (reportData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export.')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('<html><head><title>Overall Report</title>');
    buffer.writeln('<style>');
    buffer.writeln('table { border-collapse: collapse; width: 100%; }');
    buffer.writeln('th, td { border: 1px solid black; padding: 8px; text-align: left; }');
    buffer.writeln('</style></head><body>');
    buffer.writeln('<h1>Overall Report</h1>');
    buffer.writeln('<table>');
    buffer.writeln('<tr><th>Material</th><th>Inward</th><th>Usage</th><th>Balance</th></tr>');

    reportData.forEach((key, value) {
      buffer.writeln('<tr>');
      buffer.writeln('<td>$key</td>');
      buffer.writeln('<td>${value['inward']}</td>');
      buffer.writeln('<td>${value['usage']}</td>');
      buffer.writeln('<td>${value['balance']}</td>');
      buffer.writeln('</tr>');
    });

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
    final reportProvider = Provider.of<ReportProvider>(context);
    final reportData = reportProvider.overallReport;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overall Report'),
        actions: [
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedFrequency,
              items: <String>['daily', 'weekly', 'monthly']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.toUpperCase()),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedFrequency = newValue;
                  });
                }
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              reportProvider.fetchOverallReport(_selectedFrequency);
            },
            child: const Text('Generate Report'),
          ),
          reportProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Material')),
                  DataColumn(label: Text('Inward')),
                  DataColumn(label: Text('Usage')),
                  DataColumn(label: Text('Balance')),
                ],
                rows: reportData.entries.map((entry) {
                  return DataRow(cells: [
                    DataCell(Text(entry.key)),
                    DataCell(Text(entry.value['inward'].toString())),
                    DataCell(Text(entry.value['usage'].toString())),
                    DataCell(Text(entry.value['balance'].toString())),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}