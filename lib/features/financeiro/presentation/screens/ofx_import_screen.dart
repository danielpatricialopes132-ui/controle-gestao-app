import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../financeiro/providers/financeiro_provider.dart';

class OfxImportScreen extends ConsumerStatefulWidget {
  const OfxImportScreen({super.key});

  @override
  ConsumerState<OfxImportScreen> createState() => _OfxImportScreenState();
}

class _OfxImportScreenState extends ConsumerState<OfxImportScreen> {
  List<dynamic> _ofxTransactions = [];
  bool _isLoading = false;

  void _importarOfx() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ofx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await File(result.files.single.path!).readAsBytes();
        final base64String = base64Encode(bytes);
        
        final ofxList = await ref.read(financeiroControllerProvider.notifier).uploadOfx(
          base64String,
          'application/x-ofx',
          result.files.single.name,
        );
        
        setState(() {
          _ofxTransactions = ofxList;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao importar OFX: $e')));
        }
      }
    }
  }

  void _conciliar(dynamic ofxTrn, dynamic erpTrn) async {
    try {
      await ref.read(financeiroControllerProvider.notifier).conciliarTransacao(
        erpTrn['id'], 
        ofxTrn['id'], 
        ofxTrn['data']
      );
      
      setState(() {
        _ofxTransactions.removeWhere((t) => t['id'] == ofxTrn['id']);
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
        title: const Text('Conciliação OFX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _importarOfx,
            tooltip: 'Importar OFX',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ofxTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Nenhum OFX carregado.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _importarOfx,
                        icon: const Icon(Icons.upload),
                        label: const Text('Carregar Arquivo .OFX'),
                      )
                    ],
                  ),
                )
              : Row(
                  children: [
                    // Esquerda: Extrato OFX
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Extrato do Banco (OFX)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            const Divider(),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _ofxTransactions.length,
                                itemBuilder: (context, index) {
                                  final t = _ofxTransactions[index];
                                  final dataFmt = DateFormat('dd/MM/yyyy').format(DateTime.parse(t['data']));
                                  final isDespesa = t['tipo'] == 'DESPESA';
                                  
                                  return ListTile(
                                    leading: Icon(isDespesa ? Icons.arrow_downward : Icons.arrow_upward, color: isDespesa ? Colors.red : Colors.green),
                                    title: Text(t['descricao']),
                                    subtitle: Text(dataFmt),
                                    trailing: Text('R\$ ${t['valor'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    onTap: () {
                                      // Logica para selecionar
                                    },
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
                                      
                                      // Procura match no OFX (valor igual e tipo igual)
                                      final match = _ofxTransactions.cast<Map<String,dynamic>>().firstWhere(
                                        (ofx) => ofx['valor'] == valor && ofx['tipo'] == t['tipo'], 
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
