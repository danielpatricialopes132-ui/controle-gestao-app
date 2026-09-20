import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TermoPortariaPdfService {
  static Future<void> exportarTermo({
    required String nomeObra,
    required String? enderecoObra,
    required Map<String, dynamic> autorizacao,
  }) async {
    final pdfBytes = await gerarPdfBytes(
      nomeObra: nomeObra,
      enderecoObra: enderecoObra,
      autorizacao: autorizacao,
    );

    final empresa = autorizacao['empresaNome'] ?? 'Terceiro';
    final fileName = 'Autorizacao_Portaria_${empresa.toString().replaceAll(' ', '_')}.pdf';
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  static Future<Uint8List> gerarPdfBytes({
    required String nomeObra,
    required String? enderecoObra,
    required Map<String, dynamic> autorizacao,
  }) async {
    final pdf = pw.Document();

    final df = DateFormat('dd/MM/yyyy');
    final dataInicio = autorizacao['dataInicio'] != null
        ? df.format(DateTime.parse(autorizacao['dataInicio']))
        : 'N/A';
    final dataFim = autorizacao['dataFim'] != null
        ? df.format(DateTime.parse(autorizacao['dataFim']))
        : 'N/A';

    final List<dynamic> colaboradores = autorizacao['colaboradores'] is List
        ? autorizacao['colaboradores']
        : [];

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
                  color: PdfColor.fromHex('#1E3A8A'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AUTORIZAÇÃO DE ACESSO & PORTARIA',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Liberação Formal para Montadores e Equipes de Interiores',
                          style: const pw.TextStyle(color: PdfColors.grey200, fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        'STATUS: ${autorizacao['status'] ?? 'AUTORIZADO'}',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#1E3A8A'),
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Dados da Obra e Condomínio
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'UNIDADE / OBRA: $nomeObra',
                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Endereço: ${enderecoObra ?? 'Conforme cadastro do condomínio'}',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Período: $dataInicio até $dataFim',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'Horário: ${autorizacao['horarioPermitido'] ?? '08:00 às 17:00'}',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Dados da Empresa Parceira e Veículo
              pw.Text(
                'DADOS DA EMPRESA & TRANSPORTE',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A8A')),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Empresa Contratada', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Tipo de Acesso', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Veículo / Placa', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(autorizacao['empresaNome'] ?? '-', style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(autorizacao['tipoAcesso'] ?? 'TERCEIRO_CLIENTE', style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          autorizacao['veiculoPlaca'] != null
                              ? '${autorizacao['veiculoModelo'] ?? 'Veículo'} (Placa: ${autorizacao['veiculoPlaca']})'
                              : 'Sem veículo informado / Acesso a pé',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Relação de Colaboradores / Montadores
              pw.Text(
                'COLABORADORES & MONTADORES AUTORIZADOS',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A8A')),
              ),
              pw.SizedBox(height: 6),
              if (colaboradores.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Text(
                    'Nenhum colaborador nominal inserido. Entrada sujeita a apresentação de crachá e documento na portaria.',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Nome Completo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('RG', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('CPF', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Função', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ),
                      ],
                    ),
                    ...colaboradores.map((c) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(c['nome'] ?? '-', style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(c['rg'] ?? '-', style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(c['cpf'] ?? '-', style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(c['funcao'] ?? 'Montador/Técnico', style: const pw.TextStyle(fontSize: 9)),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              pw.SizedBox(height: 16),

              // Regras Condominiais
              pw.Text(
                'NORMAS CONDOMINIAIS DE SEGURANÇA & ACESSO',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#B91C1C')),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  border: pw.Border.all(color: PdfColors.red200),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  autorizacao['regrasCondominio'] ??
                      '1. Uso obrigatório de calçado fechado e crachá de identificação.\n'
                      '2. Entrada e saída exclusivamente pela portaria/elevador de serviço.\n'
                      '3. Proibido qualquer serviço com ruído fora dos horários permitidos pelo regimento interno.\n'
                      '4. Descarte de entulhos e sobras de montagem sob inteira responsabilidade da contratada.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.red900),
                ),
              ),

              pw.Spacer(),

              // Assinaturas e Carimbos
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 200,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey500)),
                        ),
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Center(
                          child: pw.Text('Responsável pela Obra / Construtora', style: const pw.TextStyle(fontSize: 8)),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 200,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey500)),
                        ),
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Center(
                          child: pw.Text('Visto da Portaria / Administração', style: const pw.TextStyle(fontSize: 8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Documento gerado eletronicamente pelo Sistema de Gestão de Obras em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
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
