import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfUtils {
  static Future<void> exportTablePdf({
    required String title,
    required String fileName,
    required List<String> headers,
    required List<List<String>> data,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: headers,
              data: data,
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300)),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(6),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: '$fileName.pdf');
  }
}
