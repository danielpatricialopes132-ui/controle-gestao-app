import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/proposta.dart';
import 'package:intl/intl.dart';

class PdfGeneratorService {
  static Future<Uint8List> gerarOrcamentoPdf(Proposta proposta, String nomeEmpresa) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(nomeEmpresa, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      pw.SizedBox(height: 4),
                      pw.Text('Proposta Comercial', style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Data: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                      pw.Text('Validade: ${proposta.validadeDias} dias'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              
              // Cliente Info
              pw.Text('Dados do Cliente', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('Nome: ${proposta.cliente?.nome ?? 'Não informado'}'),
              if (proposta.cliente?.cpfCnpj != null) pw.Text('CPF/CNPJ: ${proposta.cliente!.cpfCnpj}'),
              if (proposta.cliente?.telefone != null) pw.Text('Telefone: ${proposta.cliente!.telefone}'),
              if (proposta.cliente?.email != null) pw.Text('Email: ${proposta.cliente!.email}'),
              
              pw.SizedBox(height: 32),
              
              // Proposta Titulo
              pw.Text('Ref: ${proposta.titulo}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              
              // Itens (se houver)
              if (proposta.itens.isNotEmpty) ...[
                pw.Table.fromTextArray(
                  headers: ['Descrição', 'Qtd', 'Vlr. Unitário', 'Subtotal'],
                  data: proposta.itens.map((item) => [
                    item.descricao,
                    item.quantidade.toString(),
                    'R\$ ${item.valorUnitario.toStringAsFixed(2)}',
                    'R\$ ${item.valorTotal.toStringAsFixed(2)}'
                  ]).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                  },
                ),
                pw.SizedBox(height: 16),
              ],
              
              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Valor Total: ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('R\$ ${proposta.valorTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                ],
              ),
              
              pw.Spacer(),
              
              // Termos e Condições
              if (proposta.termos != null && proposta.termos!.isNotEmpty) ...[
                pw.Text('Termos e Condições', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.Text(proposta.termos!, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                pw.SizedBox(height: 32),
              ],
              
              // Assinatura
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 200, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text(nomeEmpresa, style: const pw.TextStyle(fontSize: 10)),
                    ]
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 200, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text('De Acordo (Cliente)', style: const pw.TextStyle(fontSize: 10)),
                    ]
                  ),
                ]
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> imprimirOuCompartilhar(Proposta proposta, String nomeEmpresa) async {
    final pdfBytes = await gerarOrcamentoPdf(proposta, nomeEmpresa);
    await Printing.sharePdf(bytes: pdfBytes, filename: 'Orcamento_${proposta.titulo.replaceAll(' ', '_')}.pdf');
  }

  static Future<void> gerarECompartilharFatura(Proposta proposta, String nomeEmpresa) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(height: 50),
              pw.Text(nomeEmpresa, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.SizedBox(height: 20),
              pw.Text('FATURA DE SERVIÇOS / PRODUTOS', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 40),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Cliente: ${proposta.cliente?.nome ?? 'Desconhecido'}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    if (proposta.cliente?.cpfCnpj != null) pw.Text('CPF/CNPJ: ${proposta.cliente!.cpfCnpj}'),
                    pw.SizedBox(height: 16),
                    pw.Text('Referência: ${proposta.titulo}'),
                    pw.Text('Data de Emissão: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                    pw.SizedBox(height: 16),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('VALOR TOTAL A PAGAR:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.Text('R\$ ${proposta.valorTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text('Dados para Pagamento (PIX / Transferência)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('Banco: 000 - Nome do Banco'),
              pw.Text('Agência: 0000 | Conta: 00000-0'),
              pw.Text('Chave PIX (CNPJ): 00.000.000/0000-00'),
              pw.Spacer(),
              pw.Text('Obrigado pela preferência!', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
              if (proposta.nfUrl != null) ...[
                pw.SizedBox(height: 16),
                pw.Text('* A Nota Fiscal oficial referente a esta fatura encontra-se em anexo/link enviado junto a este documento.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
              ]
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    await Printing.sharePdf(bytes: pdfBytes, filename: 'Fatura_${proposta.titulo.replaceAll(' ', '_')}.pdf');
  }
}
