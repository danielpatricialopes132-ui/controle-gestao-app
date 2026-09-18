import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RelatoriosPdfService {
  static Future<void> imprimirDRE(Map<String, dynamic> data, DateTime mesAno) async {
    final pdfBytes = await _gerarDrePdf(data, mesAno);
    final mesAnoStr = DateFormat('MM_yyyy').format(mesAno);
    await Printing.sharePdf(bytes: pdfBytes, filename: 'DRE_$mesAnoStr.pdf');
  }

  static Future<void> imprimirFluxoCaixa(List<dynamic> data) async {
    final pdfBytes = await _gerarFluxoCaixaPdf(data);
    await Printing.sharePdf(bytes: pdfBytes, filename: 'FluxoCaixa.pdf');
  }

  static Future<Uint8List> _gerarDrePdf(Map<String, dynamic> data, DateTime mesAno) async {
    final pdf = pw.Document();
    final formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatPercent = NumberFormat.decimalPattern('pt_BR');
    
    final resumo = data['resumo'];
    final receitas = data['receitas'] as List;
    final custosDiretos = data['custosDiretos'] as List;
    final despesasFixas = data['despesasFixas'] as List;

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
                    pw.Text('Demonstrativo de Resultado do Exercício (DRE)', style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text('Período: ${DateFormat('MM/yyyy').format(mesAno)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 32),

            // Resumo
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Text('Resumo Consolidado', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Divider(),
                  _buildResumoRow('Faturamento Bruto', resumo['receitas'], formatCurrency, isBold: true),
                  _buildResumoRow('(-) Custos Diretos', resumo['custosDiretos'], formatCurrency),
                  _buildResumoRow('(=) Margem de Contribuição', resumo['lucroBruto'], formatCurrency, isBold: true, color: PdfColors.blue800),
                  pw.Text('Margem Bruta: ${formatPercent.format(resumo['margemBrutaPercentual'])}%', style: const pw.TextStyle(color: PdfColors.grey)),
                  pw.Divider(),
                  _buildResumoRow('(-) Despesas Fixas', resumo['despesasFixas'], formatCurrency),
                  _buildResumoRow('(=) Lucro Líquido', resumo['lucroLiquido'], formatCurrency, isBold: true, color: (resumo['lucroLiquido'] >= 0) ? PdfColors.green : PdfColors.red),
                  pw.Text('Margem Líquida: ${formatPercent.format(resumo['margemLiquidaPercentual'])}%', style: const pw.TextStyle(color: PdfColors.grey)),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Detalhamento
            pw.Text('Detalhamento', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            
            _buildDetalheTable('1. Receitas Operacionais Brutas', receitas, formatCurrency, isReceita: true),
            pw.SizedBox(height: 16),
            _buildDetalheTable('2. Custos Diretos (Obras)', custosDiretos, formatCurrency, isReceita: false),
            pw.SizedBox(height: 16),
            _buildDetalheTable('3. Despesas Fixas (Escritório / Administrativo)', despesasFixas, formatCurrency, isReceita: false),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildResumoRow(String label, dynamic value, NumberFormat format, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
          pw.Text(format.format(value ?? 0), style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildDetalheTable(String title, List items, NumberFormat format, {required bool isReceita}) {
    double total = items.fold(0, (sum, item) => sum + (item['valor'] ?? 0));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          color: PdfColors.grey200,
          padding: const pw.EdgeInsets.all(8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(format.format(total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: isReceita ? PdfColors.green : PdfColors.red)),
            ],
          ),
        ),
        if (items.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('Nenhum registro no período.', style: const pw.TextStyle(color: PdfColors.grey700)),
          )
        else
          pw.Table.fromTextArray(
            headers: ['Categoria', 'Valor'],
            data: items.map((item) => [
              item['categoria'].toString(),
              format.format(item['valor'] ?? 0),
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
            },
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
              bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
            ),
          ),
      ]
    );
  }

  static Future<Uint8List> _gerarFluxoCaixaPdf(List<dynamic> data) async {
    final pdf = pw.Document();
    final formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

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
                    pw.Text('Projeção de Fluxo de Caixa', style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text('Data: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 32),

            pw.Table.fromTextArray(
              headers: ['Mês/Ano', 'Receitas Previstas', 'Despesas Previstas', 'Saldo Projetado'],
              data: data.map((item) => [
                item['mesAno'].toString(),
                formatCurrency.format(item['receitas'] ?? 0),
                formatCurrency.format(item['despesas'] ?? 0),
                formatCurrency.format(item['saldo'] ?? 0),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
