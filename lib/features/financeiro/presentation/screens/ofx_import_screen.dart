import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/financeiro_provider.dart';

class OfxImportScreen extends ConsumerStatefulWidget {
  const OfxImportScreen({super.key});

  @override
  ConsumerState<OfxImportScreen> createState() => _OfxImportScreenState();
}

class _OfxImportScreenState extends ConsumerState<OfxImportScreen> {
  List<dynamic> _extratoTransactions = [];
  bool _isLoading = false;
  String _origemExtrato = ''; // 'OFX' ou 'PDF'

  void _importarExtrato({required bool isPdf}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: isPdf ? ['pdf'] : ['ofx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isLoading = true;
        _origemExtrato = isPdf ? 'PDF (IA)' : 'OFX';
      });
      try {
        final bytes = await File(result.files.single.path!).readAsBytes();
        final base64String = base64Encode(bytes);
        
        List<dynamic> transactionsList;
        if (isPdf) {
          transactionsList = await ref.read(financeiroControllerProvider.notifier).uploadExtratoPdf(
            base64String,
            'application/pdf',
            result.files.single.name,
          );
        } else {
          transactionsList = await ref.read(financeiroControllerProvider.notifier).uploadOfx(
            base64String,
            'application/x-ofx',
            result.files.single.name,
          );
        }
        
        setState(() {
          _extratoTransactions = transactionsList;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${transactionsList.length} transações extraídas do extrato ${isPdf ? "PDF com IA" : "OFX"}!'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao importar extrato: $e')));
        }
      }
    }
  }

  void _conciliar(dynamic extratoTrn, dynamic erpTrn) async {
    try {
      await ref.read(financeiroControllerProvider.notifier).conciliarTransacao(
        erpTrn['id'], 
        extratoTrn['id'], 
        extratoTrn['data']
      );
      
      setState(() {
        _extratoTransactions.removeWhere((t) => t['id'] == extratoTrn['id']);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transação conciliada com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transacoesAsync = ref.watch(transacoesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_origemExtrato.isNotEmpty ? 'Conciliação Bancária ($_origemExtrato)' : 'Conciliação Bancária (OFX / PDF)'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Importar Extrato',
            icon: const Icon(Icons.upload_file),
            onSelected: (val) {
              if (val == 'ofx') {
                _importarExtrato(isPdf: false);
              } else if (val == 'pdf') {
                _importarExtrato(isPdf: true);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'ofx',
                child: Row(
                  children: [
                    Icon(Icons.file_present, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Importar Arquivo .OFX'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Importar Extrato PDF (IA)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _origemExtrato.contains('PDF')
                        ? 'Lendo e analisando extrato em PDF com Inteligência Artificial...'
                        : 'Processando arquivo OFX...',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          : _extratoTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Nenhum extrato carregado.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Você pode importar tanto arquivos .OFX quanto extratos bancários em PDF.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _importarExtrato(isPdf: false),
                            icon: const Icon(Icons.file_present),
                            label: const Text('Carregar .OFX'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _importarExtrato(isPdf: true),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Carregar PDF do Extrato (IA)'),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              : Row(
                  children: [
                    // Esquerda: Extrato do Banco (OFX ou PDF)
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Extrato Bancário ($_origemExtrato)',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${_extratoTransactions.length} itens',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _extratoTransactions.length,
                                itemBuilder: (context, index) {
                                  final t = _extratoTransactions[index];
                                  final dataFmt = DateFormat('dd/MM/yyyy').format(DateTime.parse(t['data']));
                                  final isDespesa = t['tipo'] == 'DESPESA';
                                  
                                  return ListTile(
                                    leading: Icon(isDespesa ? Icons.arrow_downward : Icons.arrow_upward, color: isDespesa ? Colors.red : Colors.green),
                                    title: Text(t['descricao']),
                                    subtitle: Text(dataFmt),
                                    trailing: Text('R\$ ${t['valor'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Direita: Livro Caixa do ERP
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Livro Caixa (Sistema)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            const Divider(),
                            Expanded(
                              child: transacoesAsync.when(
                                data: (erpList) {
                                  // Filtra transações não conciliadas
                                  final nConciliadas = erpList.where((t) => t['isConciliada'] != true).toList();
                                  
                                  if (nConciliadas.isEmpty) {
                                    return const Center(child: Text('Nenhuma transação pendente no ERP.'));
                                  }

                                  return ListView.builder(
                                    itemCount: nConciliadas.length,
                                    itemBuilder: (context, index) {
                                      final t = nConciliadas[index];
                                      final valor = t['valor'] is String ? double.parse(t['valor']) : t['valor'];
                                      final dataPag = t['dataVencimento'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(t['dataVencimento'])) : '';
                                      
                                      // Procura match no Extrato (valor igual e tipo igual)
                                      final match = _extratoTransactions.cast<Map<String,dynamic>>().firstWhere(
                                        (ofx) => (ofx['valor'] - valor).abs() < 0.01 && ofx['tipo'] == t['tipo'], 
                                        orElse: () => <String,dynamic>{}
                                      );

                                      return ListTile(
                                        leading: Icon(t['tipo'] == 'DESPESA' ? Icons.remove_circle_outline : Icons.add_circle_outline),
                                        title: Text(t['descricao']),
                                        subtitle: Text('Status: ${t['status']} | Venc: $dataPag'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('R\$ ${valor.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            if (match.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.link, color: Colors.blue),
                                                tooltip: 'Conciliar Sugestão',
                                                onPressed: () => _conciliar(match, t),
                                              )
                                            ]
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (e, st) => Center(child: Text('Erro: $e')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
