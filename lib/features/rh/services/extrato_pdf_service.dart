import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExtratoPdfService {
  static Future<void> imprimirExtrato(Map<String, dynamic> empreiteiro, List<dynamic> vales) async {
    final pdfBytes = await _gerarExtratoPdf(empreiteiro, vales);
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(bytes: pdfBytes, filename: 'Extrato_${empreiteiro['nome'].replaceAll(' ', '_')}_$dateStr.pdf');
  }

  static Future<Uint8List> _gerarExtratoPdf(Map<String, dynamic> empreiteiro, List<dynamic> vales) async {
    final pdf = pw.Document();
    final formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final valesDoEmpreiteiro = vales.where((v) => v['funcionarioId'] == empreiteiro['id']).toList();
    final totalVales = valesDoEmpreiteiro.fold<double>(0, (sum, v) => sum + (v['valor'] ?? 0));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DPG Construtoras & Obras', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.SizedBox(height: 4),
                    pw.Text('Extrato de Empreiteiro', style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text('Data: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 32),

            // Info Empreiteiro
            pw.Text('Dados do Colaborador', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text('Nome: ${empreiteiro['nome']}'),
            pw.Text('Cargo/Função: ${empreiteiro['cargo']}'),
            pw.Text('Tipo: ${empreiteiro['tipoColaborador']}'),
            if (empreiteiro['cpfCnpj'] != null) pw.Text('CPF/CNPJ: ${empreiteiro['cpfCnpj']}'),
            pw.SizedBox(height: 32),

            // Adiantamentos (Vales)
            pw.Text('Vales / Adiantamentos', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            if (valesDoEmpreiteiro.isEmpty)
              pw.Text('Nenhum vale lançado para este colaborador.', style: const pw.TextStyle(color: PdfColors.grey700))
            else
              pw.Table.fromTextArray(
                headers: ['Data', 'Descrição', 'Status', 'Valor'],
                data: valesDoEmpreiteiro.map((v) => [
                  DateFormat('dd/MM/yyyy').format(DateTime.parse(v['createdAt'] ?? v['dataVencimento'])),
                  v['descricao'].toString(),
                  v['status'].toString(),
                  formatCurrency.format(v['valor']),
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.red900),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                },
              ),
            
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total de Vales a Descontar: ', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text(formatCurrency.format(totalVales), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
              ],
            ),

            pw.Spacer(),

            // Assinaturas
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 200, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('DPG Construtoras', style: const pw.TextStyle(fontSize: 10)),
                  ]
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 200, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text(empreiteiro['nome'], style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('De Acordo', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ]
                ),
              ]
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
