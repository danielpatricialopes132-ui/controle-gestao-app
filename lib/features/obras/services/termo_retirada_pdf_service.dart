import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TermoRetiradaPdfService {
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
    final fileName = 'Cautela_Retirada_${numero.toString().replaceAll('/', '_')}.pdf';
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  static Future<Uint8List> gerarPdfBytes({
    required String nomeObra,
    required String? enderecoObra,
    required Map<String, dynamic> termo,
  }) async {
    final pdf = pw.Document();

    final df = DateFormat('dd/MM/yyyy');
    final dataRetirada = termo['dataRetirada'] != null
        ? df.format(DateTime.parse(termo['dataRetirada']))
        : df.format(DateTime.now());
    final previsaoDevolucao = termo['previsaoDevolucao'] != null
        ? df.format(DateTime.parse(termo['previsaoDevolucao']))
        : 'Não estipulada';

    final List<dynamic> itens = termo['itensRetirados'] is List
        ? termo['itensRetirados']
        : [];

    // Decodifica assinaturas digitais em imagem
    pw.MemoryImage? imgAssinaturaRetirante;
    if (termo['assinaturaDigitalRetirante'] != null &&
        termo['assinaturaDigitalRetirante'].toString().isNotEmpty) {
      try {
        final b64 = termo['assinaturaDigitalRetirante'].toString().contains(',')
            ? termo['assinaturaDigitalRetirante'].toString().split(',').last
            : termo['assinaturaDigitalRetirante'].toString();
        imgAssinaturaRetirante = pw.MemoryImage(base64Decode(b64));
      } catch (_) {}
    }

    pw.MemoryImage? imgAssinaturaObra;
    if (termo['assinaturaDigitalResponsavelObra'] != null &&
        termo['assinaturaDigitalResponsavelObra'].toString().isNotEmpty) {
      try {
        final b64 = termo['assinaturaDigitalResponsavelObra'].toString().contains(',')
            ? termo['assinaturaDigitalResponsavelObra'].toString().split(',').last
            : termo['assinaturaDigitalResponsavelObra'].toString();
        imgAssinaturaObra = pw.MemoryImage(base64Decode(b64));
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
              // Cabeçalho Oficial
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#0F766E'), // Verde petróleo / segurança
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TERMO DE CAUTELA & RETIRADA DE ITENS DA OBRA',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Controle de Insumos Retirados por Terceiros para Usinagem / Ajustes',
                          style: const pw.TextStyle(color: PdfColors.grey200, fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          termo['numeroTermo'] ?? 'RET-000',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'STATUS: ${termo['status'] ?? 'RETIRADO'}',
                          style: const pw.TextStyle(color: PdfColors.amber100, fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Identificação da Obra e Retirante
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
                            'Obra: $nomeObra',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'Data da Retirada: $dataRetirada',
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
                            'Empresa: ${termo['empresaRetirante'] ?? '-'}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'Previsão de Retorno: $previsaoDevolucao',
                            style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#0F766E'), fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Responsável pela Retirada: ${termo['nomeResponsavelRetirada'] ?? '-'}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'Documento (RG/CPF): ${termo['documentoResponsavel'] ?? 'Não informado'}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Finalidade / Motivo
              pw.Text(
                'FINALIDADE DA RETIRADA',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E')),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'Motivo: ${termo['motivoRetirada'] ?? 'Usinagem / furação em bancadas de marmoraria'}. '
                  '${termo['observacoes'] != null ? '\nObservações adicionais: ${termo['observacoes']}' : ''}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                ),
              ),
              pw.SizedBox(height: 16),

              // Relação de Itens Retirados
              pw.Text(
                'ITENS, QUANTIDADES E ESTADO DE CONSERVAÇÃO',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E')),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Descrição do Item / Equipamento', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Qtd', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Unid', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Estado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Obs / Detalhes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                    ],
                  ),
                  ...itens.map((it) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(it['item'] ?? '-', style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${it['quantidade'] ?? 1}', style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(it['unidade'] ?? 'un', style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(it['estadoConservacao'] ?? 'Novo na caixa', style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(it['observacao'] ?? '-', style: const pw.TextStyle(fontSize: 9)),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 16),

              // Cláusula de Responsabilidade
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber200),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'A empresa e o recebedor declaram ter recebido os itens acima em perfeitas condições de integridade, '
                  'assumindo total responsabilidade pela sua guarda, conservação e devolução no prazo estipulado.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                ),
              ),

              pw.Spacer(),

              // Assinaturas Digitais Coletadas
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Assinatura do Retirante
                  pw.Column(
                    children: [
                      if (imgAssinaturaRetirante != null)
                        pw.Container(
                          height: 55,
                          width: 170,
                          child: pw.Image(imgAssinaturaRetirante, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.SizedBox(height: 55),
                      pw.Container(
                        width: 200,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey500)),
                        ),
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              termo['nomeResponsavelRetirada'] ?? 'Responsável pela Retirada',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text('Assinatura Digital Coletada', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Assinatura do Encarregado da Obra
                  pw.Column(
                    children: [
                      if (imgAssinaturaObra != null)
                        pw.Container(
                          height: 55,
                          width: 170,
                          child: pw.Image(imgAssinaturaObra, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.SizedBox(height: 55),
                      pw.Container(
                        width: 200,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey500)),
                        ),
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'Encarregado / Engenharia da Obra',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text('Autorização de Saída Registrada', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
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
                  'Termo auditado e autenticado digitalmente em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
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
