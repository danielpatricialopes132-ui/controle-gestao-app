import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import 'dart:typed_data';

class PdfExtratoGenerator {
  static Future<Uint8List> generateC6StylePdf({
    required List<dynamic> transacoes,
    required DateTime dataInicio,
    required DateTime dataFim,
    required double saldoFinal,
    String empresaNome = 'SUA EMPRESA LTDA',
    String cnpj = '00.000.000/0001-00',
    String contaInfo = 'Conta Principal',
  }) async {
    final pdf = pw.Document();
    
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
    
    final headers = [
      'DATA\nPAGAMENTO',
      'DESCRIÇÃO DO\nLANÇAMENTO',
      'CLIENTE /\nFORNECEDOR',
      'PLANO DE CONTAS',
      'OBRA\nRELACIONADA',
      'ENTRADA',
      'SAÍDA',
      'SALDO\nACUMULADO'
    ];

    final data = <List<String>>[];
    for (var t in transacoes) {
      final date = DateTime.parse(t['data']);
      final isReceita = t['tipo'] == 'RECEITA';
      final val = (t['valor'] ?? 0).toDouble();
      final saldo = (t['saldoProgressivo'] ?? 0).toDouble();

      data.add([
        dateFormat.format(date),
        t['descricao']?.toString() ?? '',
        t['favorecido']?.toString() ?? t['contato']?.toString() ?? 'Não informado',
        t['categoria']?.toString() ?? '',
        t['obra']?.toString() ?? '--',
        isReceita ? formatter.format(val) : '-',
        !isReceita ? formatter.format(val) : '-',
        formatter.format(saldo),
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('CONTROLE & GESTÃO', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#007A8D'))),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('CONSOLIDADO GERAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#007A8D'))),
                      pw.Text('Livro Caixa (Extrato Financeiro)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Período: ${dateFormat.format(dataInicio)} a ${dateFormat.format(dataFim)}', style: const pw.TextStyle(fontSize: 10)),
                    ]
                  )
                ]
              ),
              pw.SizedBox(height: 20),
            ]
          );
        },
        build: (context) {
          return [
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.all(4),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.centerRight,
                7: pw.Alignment.centerRight,
              },
              columnWidths: {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(4),
                2: pw.FlexColumnWidth(3),
                3: pw.FlexColumnWidth(3),
                4: pw.FlexColumnWidth(3),
                5: pw.FlexColumnWidth(2.5),
                6: pw.FlexColumnWidth(2.5),
                7: pw.FlexColumnWidth(3),
              }
            )
          ];
        },
      ),
    );

    return await pdf.save();
  }

  static Future<void> exportC6StylePdf({
    required List<dynamic> transacoes,
    required DateTime dataInicio,
    required DateTime dataFim,
    required double saldoFinal,
    String empresaNome = 'SUA EMPRESA LTDA',
    String cnpj = '00.000.000/0001-00',
    String contaInfo = 'Conta Principal',
  }) async {
    final bytes = await generateC6StylePdf(
      transacoes: transacoes,
      dataInicio: dataInicio,
      dataFim: dataFim,
      saldoFinal: saldoFinal,
      empresaNome: empresaNome,
      cnpj: cnpj,
      contaInfo: contaInfo,
    );
    await Printing.sharePdf(bytes: bytes, filename: 'extrato_bancario.pdf');
  }
}
