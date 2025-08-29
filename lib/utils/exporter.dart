import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_saver/file_saver.dart';

class Exporter {
  static Future<void> exportToCsv(Map<String, dynamic> data, String fileName) async {
    List<List<dynamic>> rows = [];
    rows.add(['Material', 'Usage']); // Header
    data.forEach((key, value) {
      rows.add([key, value]);
    });

    String csv = const ListToCsvConverter().convert(rows);

    await FileSaver.instance.saveFile(
      name: '$fileName.csv',
      bytes: Uint8List.fromList(csv.codeUnits),
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  static Future<void> exportToPdf(Map<String, dynamic> data, String fileName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ['Material', 'Usage'],
            data: data.entries.map((e) => [e.key, e.value.toString()]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(),
            border: pw.TableBorder.all(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          );
        },
      ),
    );

    await FileSaver.instance.saveFile(
      name: '$fileName.pdf',
      bytes: await pdf.save(),
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
  }
}
