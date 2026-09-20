import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TermoRecebimentoPdfService {
  static Future<void> exportarTermo({
    required String nomeObra,
    required String? enderecoObra,
    required Map<String, dynamic> termo,
  }) async {
    final pdfBytes = await gerarPdfBytes(
      nomeObra: nomeObra,
      enderecoObra: enderecoObra,
      termo: termo,
    );

    final numero = termo['numeroTermo'] ?? 'Termo';
    final fileName = 'Termo_Recebimento_Interiores_${numero.toString().replaceAll('/', '_')}.pdf';
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  static Future<Uint8List> gerarPdfBytes({
    required String nomeObra,
    required String? enderecoObra,
    required Map<String, dynamic> termo,
  }) async {
    final pdf = pw.Document();

    final df = DateFormat('dd/MM/yyyy');
    final dataEmissao = termo['dataEmissao'] != null
        ? df.format(DateTime.parse(termo['dataEmissao']))
        : df.format(DateTime.now());

    final List<dynamic> ambientes = termo['detalhesAmbientes'] is List
        ? termo['detalhesAmbientes']
        : [];

    // Decodifica a assinatura digital do cliente
    pw.MemoryImage? imgAssinaturaCliente;
    if (termo['assinaturaDigitalCliente'] != null &&
        termo['assinaturaDigitalCliente'].toString().isNotEmpty) {
      try {
        final b64 = termo['assinaturaDigitalCliente'].toString().contains(',')
            ? termo['assinaturaDigitalCliente'].toString().split(',').last
            : termo['assinaturaDigitalCliente'].toString();
        imgAssinaturaCliente = pw.MemoryImage(base64Decode(b64));
      } catch (_) {}
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho de Gala / Oficial
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#4338CA'), // Índigo executivo
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TERMO DE ENTREGA & RECEBIMENTO DE INTERIORES',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Conclusão da Coordenação de Terceiros e Saneamento do Punch List',
                          style: const pw.TextStyle(color: PdfColors.grey200, fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          termo['numeroTermo'] ?? 'REC-000',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'STATUS: ${termo['status'] ?? 'ASSINADO'}',
                          style: pw.TextStyle(color: PdfColor.fromHex('#D1FAE5'), fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Dados da Obra e do Cliente
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Obra / Projeto: $nomeObra',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'Data de Emissão: $dataEmissao',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Cliente Final: ${termo['nomeCliente'] ?? '-'}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'CPF / Documento: ${termo['documentoCliente'] ?? 'Não informado'}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Responsável Técnico: ${termo['responsavelTecnico'] ?? 'Engenharia da Obra'}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'Endereço: ${enderecoObra ?? 'Local da obra'}',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Balanço de Auditoria do Punch List
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#ECFDF5'),
                        border: pw.Border.all(color: PdfColor.fromHex('#6EE7B7')),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'ITENS RESOLVIDOS / SANADOS',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#064E3B')),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '${termo['totalItensResolvidos'] ?? 0} de ${termo['totalItensVistoriados'] ?? 0}',
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#065F46')),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.indigo50,
                        border: pw.Border.all(color: PdfColors.indigo300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'CONDIÇÃO DA ENTREGA',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            (termo['statusPunchList'] ?? 'TODOS_RESOLVIDOS') == 'TODOS_RESOLVIDOS'
                                ? 'APROVADO 100% SEM RESSALVAS'
                                : 'RECEBIDO COM RESSALVAS MENORES',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // Relação de Ambientes e Itens Inspecionados
              pw.Text(
                'HISTÓRICO DE AUDITORIA POR AMBIENTE',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#4338CA')),
              ),
              pw.SizedBox(height: 6),
              if (ambientes.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Text(
                    'Todos os ambientes e acabamentos foram vistoriados diretamente in loco sem apontamento de não-conformidades prévias.',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(4),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Ambiente', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Item Vistoriado / Tratativa', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Empresa Responsável', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Status Final', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        ),
                      ],
                    ),
                    ...ambientes.map((amb) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(amb['ambiente'] ?? '-', style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(amb['descricao'] ?? '-', style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(amb['empresaResponsavel'] ?? 'Geral', style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(amb['status'] ?? 'RESOLVIDO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              pw.SizedBox(height: 12),

              // Declaração de Aceite Formal
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'DECLARAÇÃO DE RECEBIMENTO: O(A) Contratante/Proprietário(a) declara que realizou a vistoria final minuciosa '
                  'das instalações de interiores (incluindo marcenaria, mármores, climatização, esquadrias e acabamentos), '
                  'atestando que todos os itens apontados no Punch List foram devidamente sanados e entregues em perfeito funcionamento.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900),
                ),
              ),

              pw.Spacer(),

              // Assinatura Digital do Cliente
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      if (imgAssinaturaCliente != null)
                        pw.Container(
                          height: 60,
                          width: 190,
                          child: pw.Image(imgAssinaturaCliente, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.SizedBox(height: 60),
                      pw.Container(
                        width: 220,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey500)),
                        ),
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              termo['nomeCliente'] ?? 'Assinatura do Cliente',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text('Assinatura Digital Coletada na Vistoria', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 60),
                      pw.Container(
                        width: 220,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey500)),
                        ),
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              termo['responsavelTecnico'] ?? 'Engenheiro / Gerente da Obra',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text('Visto da Coordenação de Obra', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Certidão emitida eletronicamente pelo Sistema de Gestão e Coordenação de Obras em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
