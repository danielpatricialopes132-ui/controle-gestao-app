import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ExportUtils {
  
  /// Exporta uma lista de dados (List<List<dynamic>>) para CSV
  static Future<void> exportToCsv({
    required String fileName,
    required List<List<dynamic>> rows,
  }) async {
    try {
      String csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
      final Uint8List bytes = Uint8List.fromList(csv.codeUnits);

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: '$fileName.csv',
            mimeType: 'text/csv',
          )
        ],
        text: 'Exportação CSV: $fileName',
      );
    } catch (e) {
      debugPrint('Erro ao exportar CSV: $e');
    }
  }

  /// Exporta uma tabela simples para PDF
  static Future<void> exportTableToPdf({
    required String title,
    required String fileName,
    required List<String> headers,
    required List<List<String>> data,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 30,
              cellAlignments: {
                for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft,
              },
            ),
          ],
        ),
      );

      final bytes = await pdf.save();

      await Printing.sharePdf(
        bytes: bytes,
        filename: '$fileName.pdf',
      );
    } catch (e) {
      debugPrint('Erro ao exportar PDF: $e');
    }
  }
}
