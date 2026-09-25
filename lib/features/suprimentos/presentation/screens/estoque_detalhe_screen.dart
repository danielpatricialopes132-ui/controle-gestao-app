import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../../../../core/offline/sync_manager.dart';

class EstoqueDetalheScreen extends ConsumerStatefulWidget {
  final String estoqueId;
  final String estoqueNome;

  const EstoqueDetalheScreen({
    super.key,
    required this.estoqueId,
    required this.estoqueNome,
  });

  @override
  ConsumerState<EstoqueDetalheScreen> createState() => _EstoqueDetalheScreenState();
}

class _EstoqueDetalheScreenState extends ConsumerState<EstoqueDetalheScreen> {
  bool isLoading = true;
  List<dynamic> itens = [];

  @override
  void initState() {
    super.initState();
    fetchItens();
  }

  Future<void> fetchItens() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/suprimentos/estoques/${widget.estoqueId}/itens');
      
      setState(() {
        itens = response as List<dynamic>;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar itens do estoque: $e')),
      );
    }
  }

  Future<void> showBaixaDialog(dynamic item) async {
    final qtdCtrl = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Dar Baixa: ${item['produto']['nome']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Saldo Atual: ${item['quantidade']} ${item['produto']['unidadeMedida']}'),
              const SizedBox(height: 16),
              TextField(
                controller: qtdCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Quantidade a retirar',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final qtdStr = qtdCtrl.text.replaceAll(',', '.');
                final qtdNum = double.tryParse(qtdStr);
                
                if (qtdNum == null || qtdNum <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantidade inválida')));
                  return;
                }
                
                if (qtdNum > double.parse(item['quantidade'].toString())) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saldo insuficiente')));
                  return;
                }
                
                Navigator.pop(context);
                await registrarBaixa(item['produtoId'], qtdNum);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      }
    );
  }

  Future<void> registrarBaixa(String produtoId, double quantidade) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/suprimentos/estoques/${widget.estoqueId}/itens', {
        'produtoId': produtoId,
        'quantidade': quantidade,
        'tipo': 'SAIDA',
        'data': DateTime.now().toIso8601String(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baixa registrada com sucesso!')),
      );
      
      fetchItens();
    } catch (e) {
      // Offline fallback
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        try {
          final syncManager = ref.read(syncManagerProvider);
          await syncManager.enqueue('POST', '/suprimentos/estoques/${widget.estoqueId}/itens', {
            'produtoId': produtoId,
            'quantidade': quantidade,
            'tipo': 'SAIDA',
            'data': DateTime.now().toIso8601String(),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offline: Baixa enfileirada para sincronização.')),
          );
        } catch (syncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao salvar baixa offline.')),
          );
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> showTransferDialog(dynamic item) async {
    final qtdCtrl = TextEditingController();
    String? destEstoqueId;
    List<dynamic> estoquesList = [];
    
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/suprimentos/estoques');
      estoquesList = (res as List).where((e) => e['id'] != widget.estoqueId).toList();
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar estoques de destino: $e')));
      return;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Transferir: ${item['produto']['nome']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Saldo Atual: ${item['quantidade']} ${item['produto']['unidadeMedida']}'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Obra/Estoque de Destino', border: OutlineInputBorder()),
                    items: estoquesList.map((e) => DropdownMenuItem<String>(
                      value: e['id'],
                      child: Text(e['nome']),
                    )).toList(),
                    onChanged: (val) => setStateDialog(() => destEstoqueId = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: qtdCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Quantidade a transferir',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (destEstoqueId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione o destino')));
                      return;
                    }
                    final qtdStr = qtdCtrl.text.replaceAll(',', '.');
                    final qtdNum = double.tryParse(qtdStr);
                    
                    if (qtdNum == null || qtdNum <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantidade inválida')));
                      return;
                    }
                    
                    if (qtdNum > double.parse(item['quantidade'].toString())) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saldo insuficiente')));
                      return;
                    }
                    
                    Navigator.pop(context);
                    await registrarTransferencia(item['produtoId'], qtdNum, destEstoqueId!);
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> registrarTransferencia(String produtoId, double quantidade, String toEstoqueId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/suprimentos/estoques/transferencia', {
        'fromEstoqueId': widget.estoqueId,
        'toEstoqueId': toEstoqueId,
        'produtoId': produtoId,
        'quantidade': quantidade,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transferência realizada com sucesso!')),
      );
      
      fetchItens();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.estoqueNome),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : itens.isEmpty
          ? const Center(child: Text('Este estoque está vazio. Quando uma Ordem de Compra for entregue, os materiais aparecerão aqui.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: itens.length,
              itemBuilder: (context, index) {
                final item = itens[index];
                final produto = item['produto'];
                final qtd = double.parse(item['quantidade'].toString());
                
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: qtd > 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      child: Icon(Icons.category, color: qtd > 0 ? Colors.green : Colors.red),
                    ),
                    title: Text(produto['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Saldo: $qtd ${produto['unidadeMedida']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: qtd > 0 ? () => showTransferDialog(item) : null,
                          child: const Text('Transferir'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: qtd > 0 ? () => showBaixaDialog(item) : null,
                          child: const Text('Baixa'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
