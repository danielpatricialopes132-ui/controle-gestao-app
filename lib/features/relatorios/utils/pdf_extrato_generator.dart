import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfExtratoGenerator {
  static Future<void> exportC6StylePdf({
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
    final dateFormat = DateFormat('dd/MM', 'pt_BR');
    final fullDateFormat = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR');
    
    // Agrupar transações por mês/ano
    final Map<String, List<dynamic>> grouped = {};
    for (var t in transacoes) {
      final date = DateTime.parse(t['data'].toString());
      final key = DateFormat('MMMM yyyy', 'pt_BR').format(date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    final now = DateTime.now();
    final exportDateStr = 'Extrato exportado no dia ${fullDateFormat.format(now)} às ${DateFormat('HH:mm').format(now)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        header: (context) {
          if (context.pageNumber > 1) {
            return pw.SizedBox.shrink();
          }
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                exportDateStr,
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F4F4F5'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(width: 4, height: 24, color: PdfColor.fromHex('#FACC15')), // Yellow bar
                        pw.SizedBox(width: 12),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              '$empresaNome • $cnpj',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              contaInfo,
                              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.Text('CONTROLE & GESTÃO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Extrato', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Período • ${fullDateFormat.format(dataInicio)} até ${fullDateFormat.format(dataFim)}',
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Saldo do dia • ${fullDateFormat.format(dataFim)} • ${formatter.format(saldoFinal)}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
        build: (context) {
          final List<pw.Widget> elements = [];

          for (final entry in grouped.entries) {
            final monthName = entry.key[0].toUpperCase() + entry.key.substring(1);
            final monthTransactions = entry.value;

            double entradas = 0;
            double saidas = 0;
            for (var t in monthTransactions) {
              final val = (t['valor'] ?? 0).toDouble();
              if (t['tipo'] == 'RECEITA') {
                entradas += val;
              } else {
                saidas += val;
              }
            }

            final firstDay = DateTime.parse(monthTransactions.first['data']);
            final lastDay = DateTime.parse(monthTransactions.last['data']);
            final lastSaldo = (monthTransactions.last['saldoProgressivo'] ?? 0).toDouble();

            elements.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 16, bottom: 8),
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F4F4F5'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(text: '$monthName ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                          pw.TextSpan(text: '( ${DateFormat('dd/MM/yyyy').format(firstDay)} - ${DateFormat('dd/MM/yyyy').format(lastDay)} )', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                    pw.Row(
                      children: [
                        pw.Text('↑ Entradas: ', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                        pw.Text(formatter.format(entradas), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                        pw.Text('  •  ', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey400)),
                        pw.Text('↓ Saídas: ', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                        pw.Text(formatter.format(saidas), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                      ],
                    ),
                  ],
                ),
              ),
            );

            elements.add(
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 2, child: pw.Text('Data\nlançamento', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 2, child: pw.Text('Data\ncontábil', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 3, child: pw.Text('Tipo', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 7, child: pw.Text('Descrição', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 3, child: pw.Text('Valor', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
              ),
            );

            elements.add(pw.Divider(color: PdfColors.grey300, thickness: 1));

            for (var i = 0; i < monthTransactions.length; i++) {
              final t = monthTransactions[i];
              final date = DateTime.parse(t['data']);
              final dateStr = dateFormat.format(date);
              final tipo = t['categoria']?.toString() ?? '';
              final desc = t['descricao']?.toString() ?? '';
              final val = (t['valor'] ?? 0).toDouble();
              final isReceita = t['tipo'] == 'RECEITA';

              elements.add(
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: i % 2 == 1 ? PdfColor.fromHex('#FAFAFA') : null,
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 2, child: pw.Text(dateStr, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 2, child: pw.Text(dateStr, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 3, child: pw.Text(tipo, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 7, child: pw.Text(desc, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(
                        flex: 3, 
                        child: pw.Text(
                          (isReceita ? '' : '-') + formatter.format(val),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: isReceita ? PdfColor.fromHex('#16A34A') : PdfColors.grey600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            elements.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 4, bottom: 8),
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F4F4F5'),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Saldo do dia ${dateFormat.format(lastDay)}/${lastDay.year.toString().substring(2)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text(formatter.format(lastSaldo), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                  ],
                ),
              ),
            );
          }

          return elements;
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'extrato_bancario_c6.pdf');
  }
}
