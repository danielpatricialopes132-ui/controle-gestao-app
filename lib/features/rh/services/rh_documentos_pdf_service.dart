import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RhDocumentosPdfService {
  static final _formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _formatDate = DateFormat('dd/MM/yyyy');

  /// Gera e compartilha o Extrato de Empreiteiro
  static Future<void> imprimirExtratoEmpreiteiro(Map<String, dynamic> empreiteiro, List<dynamic> vales, {Uint8List? assinaturaBytes}) async {
    final pdfBytes = await _gerarExtratoPdf(empreiteiro, vales, assinaturaBytes);
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(bytes: pdfBytes, filename: 'Extrato_${empreiteiro['nome'].replaceAll(' ', '_')}_$dateStr.pdf');
  }

  /// Gera e compartilha o Recibo de Pagamento Autônomo (RPA)
  static Future<void> imprimirRPA(Map<String, dynamic> funcionario, double valorBruto, double inss, double iss, {Uint8List? assinaturaBytes}) async {
    final pdfBytes = await _gerarRPAPdf(funcionario, valorBruto, inss, iss, assinaturaBytes);
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(bytes: pdfBytes, filename: 'RPA_${funcionario['nome'].replaceAll(' ', '_')}_$dateStr.pdf');
  }

  /// Gera e compartilha o Holerite
  static Future<void> imprimirHolerite(Map<String, dynamic> funcionario, double salarioBase, List<dynamic> vales, {Uint8List? assinaturaBytes}) async {
    final pdfBytes = await _gerarHoleritePdf(funcionario, salarioBase, vales, assinaturaBytes);
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(bytes: pdfBytes, filename: 'Holerite_${funcionario['nome'].replaceAll(' ', '_')}_$dateStr.pdf');
  }

  // =========================================================================
  // GERAÇÃO DOS PDFs (Layouts)
  // =========================================================================

  static Future<Uint8List> _gerarExtratoPdf(Map<String, dynamic> empreiteiro, List<dynamic> vales, Uint8List? assinaturaBytes) async {
    final pdf = pw.Document();

    final valesDoEmpreiteiro = vales.where((v) => v['funcionarioId'] == empreiteiro['id']).toList();
    final totalVales = valesDoEmpreiteiro.fold<double>(0, (sum, v) => sum + (v['valor'] ?? 0));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader('Extrato de Empreiteiro'),
            pw.SizedBox(height: 32),
            _buildDadosColaborador(empreiteiro),
            pw.SizedBox(height: 32),
            pw.Text('Vales / Adiantamentos', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            if (valesDoEmpreiteiro.isEmpty)
              pw.Text('Nenhum vale lançado para este colaborador.', style: const pw.TextStyle(color: PdfColors.grey700))
            else
              pw.Table.fromTextArray(
                headers: ['Data', 'Descrição', 'Status', 'Valor'],
                data: valesDoEmpreiteiro.map((v) => [
                  _formatDate.format(DateTime.parse(v['createdAt'] ?? v['dataVencimento'])),
                  v['descricao'].toString(),
                  v['status'].toString(),
                  _formatCurrency.format(v['valor']),
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
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
                pw.Text(_formatCurrency.format(totalVales), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
              ],
            ),
            pw.Spacer(),
            _buildAssinaturas(empreiteiro['nome'], assinaturaBytes),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> _gerarRPAPdf(Map<String, dynamic> funcionario, double valorBruto, double inss, double iss, Uint8List? assinaturaBytes) async {
    final pdf = pw.Document();
    final valorLiquido = valorBruto - inss - iss;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Recibo de Pagamento Autônomo (RPA)'),
              pw.SizedBox(height: 32),
              _buildDadosColaborador(funcionario),
              pw.SizedBox(height: 32),
              pw.Text('Demonstrativo de Pagamento', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _buildRowValor('Valor Bruto dos Serviços:', valorBruto),
              pw.SizedBox(height: 8),
              _buildRowValor('(-) Desconto INSS:', inss, isDesconto: true),
              pw.SizedBox(height: 4),
              _buildRowValor('(-) Desconto ISS:', iss, isDesconto: true),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              _buildRowValor('Valor Líquido a Pagar:', valorLiquido, isTotal: true),
              
              pw.Spacer(),
              pw.Text('Recebi a importância líquida supra, dando plena e geral quitação.', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 32),
              _buildAssinaturas(funcionario['nome'], assinaturaBytes),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  static Future<Uint8List> _gerarHoleritePdf(Map<String, dynamic> funcionario, double salarioBase, List<dynamic> vales, Uint8List? assinaturaBytes) async {
    final pdf = pw.Document();
    
    final valesDoFuncionario = vales.where((v) => v['funcionarioId'] == funcionario['id']).toList();
    final totalVales = valesDoFuncionario.fold<double>(0, (sum, v) => sum + (v['valor'] ?? 0));
    
    // Simplificação de INSS para exemplo (8%)
    final inss = salarioBase * 0.08;
    final valorLiquido = salarioBase - inss - totalVales;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Recibo de Pagamento de Salário (Holerite)'),
              pw.SizedBox(height: 32),
              _buildDadosColaborador(funcionario),
              pw.SizedBox(height: 32),
              pw.Text('Demonstrativo', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Descrição', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Proventos', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Descontos', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ]
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Salário Base')),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_formatCurrency.format(salarioBase), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('', textAlign: pw.TextAlign.right)),
                    ]
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('INSS (8%)')),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('', textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_formatCurrency.format(inss), textAlign: pw.TextAlign.right)),
                    ]
                  ),
                  if (totalVales > 0)
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Adiantamentos / Vales')),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('', textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_formatCurrency.format(totalVales), textAlign: pw.TextAlign.right)),
                      ]
                    ),
                ]
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total Proventos: ${_formatCurrency.format(salarioBase)}  |  Total Descontos: ${_formatCurrency.format(inss + totalVales)}', style: const pw.TextStyle(fontSize: 10)),
                ]
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('Líquido a Receber: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(_formatCurrency.format(valorLiquido), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                  ]
                )
              ),

              pw.Spacer(),
              pw.Text('Recebi a importância líquida supra, dando plena e geral quitação.', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 24),
              _buildAssinaturas(funcionario['nome'], assinaturaBytes),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // =========================================================================
  // WIDGETS AUXILIARES PARA PDF
  // =========================================================================

  static pw.Widget _buildHeader(String titulo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('DPG Construtoras & Obras', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.SizedBox(height: 4),
            pw.Text(titulo, style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
          ],
        ),
        pw.Text('Data: ${_formatDate.format(DateTime.now())}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildDadosColaborador(Map<String, dynamic> f) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Dados do Colaborador', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Divider(),
        pw.Text('Nome: ${f['nome']}'),
        pw.Text('Cargo/Função: ${f['cargo']}'),
        pw.Text('Tipo de Contratação: ${f['tipoColaborador'] ?? 'CLT'}'),
        if (f['cpfCnpj'] != null) pw.Text('CPF/CNPJ: ${f['cpfCnpj']}'),
      ]
    );
  }

  static pw.Widget _buildRowValor(String label, double valor, {bool isDesconto = false, bool isTotal = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(
          _formatCurrency.format(valor), 
          style: pw.TextStyle(
            color: isDesconto ? PdfColors.red800 : (isTotal ? PdfColors.green800 : PdfColors.black),
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal
          )
        ),
      ]
    );
  }

  static pw.Widget _buildAssinaturas(String nome, Uint8List? assinaturaBytes) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
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
            if (assinaturaBytes != null)
              pw.Container(
                height: 60,
                child: pw.Image(pw.MemoryImage(assinaturaBytes)),
              )
            else
              pw.SizedBox(height: 60), // Espaço vazio se não houver assinatura

            pw.Container(width: 200, height: 1, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text(nome, style: const pw.TextStyle(fontSize: 10)),
            pw.Text('De Acordo', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ]
        ),
      ]
    );
  }
}
