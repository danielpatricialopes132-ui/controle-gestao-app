import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RevistaPdfService {
  static Future<void> exportarRevista({
    required String nomeObra,
    required String clienteNome,
    required String tipoPeriodicidade, // "SEMANAL" ou "MENSAL"
    required String titulo,
    required String periodoReferencia,
    required String editorial,
    required String destaques,
    required String lookahead,
    required int climaDiasSol,
    required int climaDiasChuva,
    required double percentualAvanco,
    required List<dynamic> fotos,
    List<dynamic>? mapaVisitas,
    String? logoEmpresa,
  }) async {
    final pdfBytes = await gerarPdfBytes(
      nomeObra: nomeObra,
      clienteNome: clienteNome,
      tipoPeriodicidade: tipoPeriodicidade,
      titulo: titulo,
      periodoReferencia: periodoReferencia,
      editorial: editorial,
      destaques: destaques,
      lookahead: lookahead,
      climaDiasSol: climaDiasSol,
      climaDiasChuva: climaDiasChuva,
      percentualAvanco: percentualAvanco,
      fotos: fotos,
      mapaVisitas: mapaVisitas,
      logoEmpresa: logoEmpresa,
    );

    final sufixo = tipoPeriodicidade == 'SEMANAL' ? 'Semanal' : 'Mensal';
    final fileName = 'Revista_Obra_${sufixo}_${nomeObra.replaceAll(' ', '_')}_$periodoReferencia.pdf';
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  static Future<Uint8List> gerarPdfBytes({
    required String nomeObra,
    required String clienteNome,
    required String tipoPeriodicidade,
    required String titulo,
    required String periodoReferencia,
    required String editorial,
    required String destaques,
    required String lookahead,
    required int climaDiasSol,
    required int climaDiasChuva,
    required double percentualAvanco,
    required List<dynamic> fotos,
    List<dynamic>? mapaVisitas,
    String? logoEmpresa,
  }) async {
    final pdf = pw.Document();

    final isSemanal = tipoPeriodicidade == 'SEMANAL';
    final corPrimaria = isSemanal ? PdfColors.teal800 : PdfColors.indigo900;
    final corSecundaria = isSemanal ? PdfColors.teal50 : PdfColors.indigo50;
    final rotuloTipo = isSemanal ? 'BOLETIM SEMANAL DE EVOLUÇÃO' : 'REVISTA EXECUTIVA DA OBRA';

    // PÁGINA 1: CAPA EDITORIAL ESTILO REVISTA
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.grey100,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Top Header com Tarja da Construtora
                pw.Container(
                  color: corPrimaria,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DPG CONSTRUTORAS & ENGENHARIA',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            rotuloTipo,
                            style: const pw.TextStyle(
                              color: PdfColors.amber300,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.white),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          periodoReferencia.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Foto de Capa / Mock de Destaque
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    margin: const pw.EdgeInsets.all(32),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey400, width: 2),
                    ),
                    child: pw.Center(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            nomeObra.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: corPrimaria,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 12),
                          pw.Container(width: 80, height: 3, color: PdfColors.amber),
                          pw.SizedBox(height: 12),
                          pw.Text(
                            'Relatório de Acompanhamento Executivo & Avanço Físico',
                            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                          ),
                          if (clienteNome.isNotEmpty) ...[
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'Preparado especialmente para: $clienteNome',
                              style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Rodapé da Capa com Termômetro Geral
                pw.Container(
                  color: corSecundaria,
                  padding: const pw.EdgeInsets.all(24),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildCapaIndicator('AVANÇO GERAL', '${percentualAvanco.toStringAsFixed(0)}% CONCLUÍDO', corPrimaria),
                      _buildCapaIndicator('DIAS DE SOL', '$climaDiasSol DIAS', PdfColors.green800),
                      _buildCapaIndicator('DIAS CHUVOSOS', '$climaDiasChuva DIAS', PdfColors.blueGrey700),
                      _buildCapaIndicator('STATUS GERAL', 'CRONOGRAMA EM DIA', PdfColors.teal800),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // PÁGINA 2: EDITORIAL DO ENGENHEIRO & INFOGRÁFICO EXECUTIVO
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho Interno
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('MENSAGEM DO ENGENHEIRO & METAS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: corPrimaria)),
                  pw.Text('$nomeObra | $periodoReferencia', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                ],
              ),
              pw.Divider(thickness: 1.5, color: corPrimaria),
              pw.SizedBox(height: 16),

              // Carta do Engenheiro
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: corSecundaria,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Carta Mensal de Evolução', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: corPrimaria)),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      editorial.isNotEmpty ? editorial : 'Neste período, as frentes de trabalho concentraram-se na execução com rigoroso controle de qualidade dos materiais e conformidade com as normas técnicas de segurança e engenharia.',
                      style: const pw.TextStyle(fontSize: 11, height: 1.5, color: PdfColors.black),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Destaques e Lookahead (2 colunas elegantes)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.green300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Destaques Concluídos no Período', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            destaques.isNotEmpty ? destaques : '• Conclusão das etapas prioritárias de alvenaria e infraestrutura técnica.',
                            style: const pw.TextStyle(fontSize: 10, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.amber400),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Lookahead (Próximos Passos)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            lookahead.isNotEmpty ? lookahead : '• Início dos acabamentos finos e vistorias prévias com equipes especializadas.',
                            style: const pw.TextStyle(fontSize: 10, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // Seção de Fotos Selecionadas
              pw.Text('REGISTRO VISUAL E STORYTELLING DE AMBIENTES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: corPrimaria)),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              if (fotos.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(24),
                  alignment: pw.Alignment.center,
                  child: pw.Text('Nenhum registro fotográfico anexado nesta edição.', style: const pw.TextStyle(color: PdfColors.grey600)),
                )
              else
                pw.Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: fotos.take(4).map((f) {
                    final legenda = f['legenda'] ?? f['descricao'] ?? 'Avanço de obra';
                    final ambiente = f['ambiente'] ?? 'Canteiro Geral';
                    return pw.Container(
                      width: 250,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(6),
                        color: PdfColors.grey50,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            height: 120,
                            color: PdfColors.grey200,
                            alignment: pw.Alignment.center,
                            child: pw.Text('[Foto de Alta Resolução]', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(ambiente, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: corPrimaria)),
                          pw.Text(legenda, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800), maxLines: 2),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('DPG Construtoras & Engenharia — Gestão e Transparência', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  pw.Text('Página 2 de ${mapaVisitas != null && mapaVisitas.isNotEmpty ? '3' : '2'}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // PÁGINA 3: MATRIZ SEMANAL DE VISITAS E ATUAÇÃO DE TERCEIROS (S, T, Q, Q, S, S, D)
    if (mapaVisitas != null && mapaVisitas.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('MAPA SEMANAL DE VISITAS DE TERCEIROS (S T Q Q S S D)',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: corPrimaria)),
                    pw.Text('$nomeObra | $periodoReferencia', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: corPrimaria),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Acompanhamento das equipes terceirizadas contratadas diretamente pelo cliente (interiores, acabamentos e instalações).',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 16),

                pw.TableHelper.fromTextArray(
                  headers: ['Empresa Parceira', 'Especialidade', 'Status', 'S', 'T', 'Q', 'Q', 'S', 'S', 'D', 'Total'],
                  data: mapaVisitas.map((t) {
                    final dias = (t['dias'] as Map<String, dynamic>?) ?? {};
                    String formatDia(String key) {
                      final lista = dias[key] as List<dynamic>?;
                      if (lista != null && lista.isNotEmpty) {
                        final motivo = lista[0]['motivo']?.toString() ?? '';
                        if (motivo.toLowerCase().contains('medi')) return 'Medição';
                        if (motivo.toLowerCase().contains('mont')) return 'Montag.';
                        if (motivo.toLowerCase().contains('vist')) return 'Vistor.';
                        return 'OK';
                      }
                      return '-';
                    }

                    return [
                      t['nomeEmpresa']?.toString() ?? 'Empresa',
                      t['especialidade']?.toString() ?? 'Geral',
                      t['statusCiclo']?.toString() ?? 'Ativo',
                      formatDia('seg'),
                      formatDia('ter'),
                      formatDia('qua'),
                      formatDia('qui'),
                      formatDia('sex'),
                      formatDia('sab'),
                      formatDia('dom'),
                      '${t['totalVisitas'] ?? 0}x',
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                  headerDecoration: pw.BoxDecoration(color: corPrimaria),
                  cellStyle: const pw.TextStyle(fontSize: 8.5),
                  cellAlignment: pw.Alignment.center,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerLeft,
                  },
                ),

                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Text(
                    'Legenda de Acesso: S=Segunda | T=Terça | Q=Quarta | Q=Quinta | S=Sexta | S=Sábado | D=Domingo.\nAs visitas são apontadas e supervisionadas pela coordenação para garantia de compatibilização e qualidade de entrega.',
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800, height: 1.3),
                  ),
                ),

                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('DPG Construtoras & Engenharia — Gestão e Transparência', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.Text('Página 3 de 3', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildCapaIndicator(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
