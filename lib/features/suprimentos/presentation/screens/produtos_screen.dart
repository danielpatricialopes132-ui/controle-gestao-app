import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/suprimentos_provider.dart';
import 'historico_precos_modal.dart';

class ProdutosScreen extends ConsumerStatefulWidget {
  const ProdutosScreen({super.key});

  @override
  ConsumerState<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends ConsumerState<ProdutosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(suprimentosProvider.notifier).fetchProdutos());
  }

  void _showAddProdutoModal() {
    final nomeController = TextEditingController();
    final precoController = TextEditingController();
    String unidadeMedida = 'UN';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Novo Produto/Insumo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Material'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: unidadeMedida,
                decoration: const InputDecoration(labelText: 'Unidade de Medida'),
                items: ['UN', 'KG', 'SC', 'LT', 'M2', 'M3', 'CX'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => unidadeMedida = v!,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: precoController,
                decoration: const InputDecoration(labelText: 'Preço Base (R\$)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (nomeController.text.isEmpty) return;
                  try {
                    await ref.read(suprimentosProvider.notifier).createProduto(
                      {
                        'nome': nomeController.text,
                        'unidadeMedida': unidadeMedida,
                        'precoBase': double.tryParse(precoController.text.replaceAll(',', '.')) ?? 0,
                      }
                    );
                    if (mounted && modalCtx.mounted) Navigator.pop(modalCtx);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                    }
                  }
                },
                child: const Text('Salvar Produto'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(suprimentosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de Produtos')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.produtos.length,
              itemBuilder: (context, index) {
                final produto = provider.produtos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.inventory_2, size: 20),
                    ),
                    title: Text(produto['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Medida: ${produto['unidadeMedida']} | Preço Base: R\$ ${produto['precoBase'] ?? 0}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.analytics_outlined, color: Colors.indigo),
                      tooltip: 'Inteligência de Preços & Custo Médio',
                      onPressed: () => HistoricoPrecosModal.show(context, produto['id'], produto['nome']),
                    ),
                    onTap: () => HistoricoPrecosModal.show(context, produto['id'], produto['nome']),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(heroTag: null, 
        onPressed: _showAddProdutoModal,
        tooltip: 'Adicionar Produto',
        child: const Icon(Icons.add),
      ),
    );
  }
}
