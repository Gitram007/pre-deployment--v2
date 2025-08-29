import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';

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
    Future.microtask(() {
      Provider.of<ReportProvider>(context, listen: false)
          .fetchOverallReport(_selectedFrequency);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final reportData = reportProvider.overallReport;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overall Report'),
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
                  reportProvider.fetchOverallReport(newValue);
                }
              },
            ),
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
