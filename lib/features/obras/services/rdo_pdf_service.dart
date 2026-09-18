import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RdoPdfService {
  static Future<void> imprimirRdo(
    String nomeObra,
    DateTime dataDiario,
    List<Map<String, dynamic>> apontamentos,
    List<dynamic> fotos,
  ) async {
    final pdfBytes = await _gerarRdoPdf(nomeObra, dataDiario, apontamentos, fotos);
    final dateStr = DateFormat('yyyyMMdd').format(dataDiario);
    await Printing.sharePdf(bytes: pdfBytes, filename: 'RDO_${nomeObra.replaceAll(' ', '_')}_$dateStr.pdf');
  }

  static Future<Uint8List> _gerarRdoPdf(
    String nomeObra,
    DateTime dataDiario,
    List<Map<String, dynamic>> apontamentos,
    List<dynamic> fotos,
  ) async {
    final pdf = pw.Document();

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
                    pw.Text('Relatório Diário de Obra (RDO)', style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Obra: $nomeObra', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Data: ${DateFormat('dd/MM/yyyy').format(dataDiario)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                )
              ],
            ),
            pw.SizedBox(height: 32),

            // Equipe
            pw.Text('Efetivo do Dia (Apontamentos)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            if (apontamentos.isEmpty)
              pw.Text('Nenhum colaborador registrado no dia.', style: const pw.TextStyle(color: PdfColors.grey700))
            else
              pw.Table.fromTextArray(
                headers: ['Colaborador', 'Função', 'Status', 'Horas', 'Obs'],
                data: apontamentos.map((ap) => [
                  ap['nome'].toString(),
                  ap['tipo'].toString(),
                  ap['status'].toString(),
                  ap['horasTrabalhadas'].toString(),
                  ap['observacao']?.toString() ?? '',
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerLeft,
                },
              ),

            pw.SizedBox(height: 32),

            // Fotos
            pw.Text('Registro Fotográfico', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            if (fotos.isEmpty)
              pw.Text('Nenhuma foto anexada neste dia.', style: const pw.TextStyle(color: PdfColors.grey700))
            else
              pw.Wrap(
                spacing: 16,
                runSpacing: 16,
                children: fotos.map((foto) {
                  return pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        // Como a foto no GED é uma URL, no Flutter nativo com a lib pdf
                        // idealmente faríamos o download do bytes via http.get. 
                        // Para simplificar no MVP, colocamos apenas o nome do arquivo/link.
                        pw.Container(
                          height: 100,
                          color: PdfColors.grey200,
                          child: pw.Center(child: pw.Text('[Imagem Anexada]', style: const pw.TextStyle(color: PdfColors.grey600))),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(foto['nome'] ?? 'Foto', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              
            pw.Spacer(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 200, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Engenheiro Responsável', style: const pw.TextStyle(fontSize: 10)),
                  ]
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 200, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Cliente / Fiscal', style: const pw.TextStyle(fontSize: 10)),
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
