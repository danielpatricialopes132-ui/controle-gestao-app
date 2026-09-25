import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfUtils {
  static Future<void> exportTablePdf({
    required String title,
    required String fileName,
    required List<String> headers,
    required List<List<String>> data,
    String? subtitle,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#0F172A'); // Slate 900
    final secondaryColor = PdfColor.fromHex('#007A8D'); // Teal
    final lightGray = PdfColor.fromHex('#F8FAFC'); // Slate 50

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        header: (context) => _buildHeader(context, title, subtitle, primaryColor, secondaryColor),
        footer: (context) => _buildFooter(context, primaryColor),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),
            _buildTable(headers, data, primaryColor, secondaryColor, lightGray),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: '$fileName.pdf');
  }

  static pw.Widget _buildHeader(
    pw.Context context, 
    String title, 
    String? subtitle,
    PdfColor primary, 
    PdfColor secondary
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CONTROLE & GESTÃO',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: primary,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Inteligência Gerencial e Financeira',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: secondary,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Data de Emissão',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
                pw.Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primary),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Container(
          width: double.infinity,
          height: 3,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [primary, secondary],
            ),
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: primary,
          ),
        ),
        if (subtitle != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context, PdfColor primary) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, thickness: 1),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Gerado automaticamente pelo sistema ERP Controle & Gestão.',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: primary, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTable(
    List<String> headers, 
    List<List<String>> data, 
    PdfColor primary, 
    PdfColor secondary,
    PdfColor lightGray
  ) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 11,
      ),
      headerDecoration: pw.BoxDecoration(
        color: primary,
        borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
      ),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        ),
      ),
      cellStyle: const pw.TextStyle(
        fontSize: 10,
        color: PdfColors.grey800,
      ),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      cellAlignments: {
        for (var i = 0; i < headers.length; i++) 
          i: i == 0 ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
      },
      oddRowDecoration: pw.BoxDecoration(
        color: lightGray,
      ),
    );
  }
}
