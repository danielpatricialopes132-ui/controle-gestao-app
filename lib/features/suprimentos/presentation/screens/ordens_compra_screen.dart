import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/suprimentos_provider.dart';

class OrdensCompraScreen extends ConsumerStatefulWidget {
  const OrdensCompraScreen({super.key});

  @override
  ConsumerState<OrdensCompraScreen> createState() => _OrdensCompraScreenState();
}

class _OrdensCompraScreenState extends ConsumerState<OrdensCompraScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(suprimentosProvider.notifier).fetchOrdensCompra());
  }

  void _atualizarStatus(String id, String novoStatus) async {
    try {
      await ref.read(suprimentosProvider.notifier).updateOrdemStatus(id, novoStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status atualizado com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(suprimentosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ordens de Compra')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.ordensCompra.length,
              itemBuilder: (context, index) {
                final ordem = provider.ordensCompra[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('OC #${ordem['numero']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Chip(
                              label: Text(ordem['status'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                              backgroundColor: ordem['status'] == 'ENTREGUE' ? Colors.green : Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Fornecedor: ${ordem['fornecedor']?['nome'] ?? 'Desconhecido'}'),
                        Text('Valor Total: R\$ ${(ordem['valorTotal'] ?? 0).toStringAsFixed(2)}'),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (ordem['status'] == 'PENDENTE')
                              ElevatedButton.icon(
                                onPressed: () => _atualizarStatus(ordem['id'], 'APROVADA'),
                                icon: const Icon(Icons.thumb_up),
                                label: const Text('Aprovar OC'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                              ),
                            if (ordem['status'] == 'APROVADA')
                              ElevatedButton.icon(
                                onPressed: () => _atualizarStatus(ordem['id'], 'ENTREGUE'),
                                icon: const Icon(Icons.local_shipping),
                                label: const Text('Registrar Entrega'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              ),
                            if (ordem['status'] == 'ENTREGUE')
                              const Text('Estoque Atualizado', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(heroTag: null, 
        onPressed: () {
          // TODO: Tela complexa de criação de OC com seleção de múltiplos produtos
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nova OC em desenvolvimento')));
        },
        tooltip: 'Nova Ordem',
        child: const Icon(Icons.add),
      ),
    );
  }
}
