import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/suprimentos_provider.dart';
import '../data/models/produto.dart';

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
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
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
                value: unidadeMedida,
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
                      Produto(
                        id: '',
                        nome: nomeController.text,
                        unidadeMedida: unidadeMedida,
                        precoBase: double.tryParse(precoController.text.replaceAll(',', '.')) ?? 0,
                      )
                    );
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
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
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.inventory_2)),
                  title: Text(produto.nome),
                  subtitle: Text('Medida: ${produto.unidadeMedida} | Preço Base: R\$ ${produto.precoBase}'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProdutoModal,
        tooltip: 'Adicionar Produto',
        child: const Icon(Icons.add),
      ),
    );
  }
}
