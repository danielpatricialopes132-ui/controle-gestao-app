import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/suprimentos_provider.dart';
import '../data/models/fornecedor.dart';

class FornecedoresScreen extends ConsumerStatefulWidget {
  const FornecedoresScreen({super.key});

  @override
  ConsumerState<FornecedoresScreen> createState() => _FornecedoresScreenState();
}

class _FornecedoresScreenState extends ConsumerState<FornecedoresScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(suprimentosProvider.notifier).fetchFornecedores());
  }

  void _showAddFornecedorModal() {
    final nomeController = TextEditingController();
    final cnpjController = TextEditingController();
    final telefoneController = TextEditingController();
    final emailController = TextEditingController();

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
              const Text('Novo Fornecedor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Razão Social / Nome'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cnpjController,
                decoration: const InputDecoration(labelText: 'CNPJ/CPF'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (nomeController.text.isEmpty) return;
                  try {
                    await ref.read(suprimentosProvider.notifier).createFornecedor(
                      Fornecedor(
                        id: '',
                        nome: nomeController.text,
                        cnpj: cnpjController.text,
                        telefone: telefoneController.text,
                        email: emailController.text,
                      )
                    );
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                  }
                },
                child: const Text('Salvar Fornecedor'),
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
      appBar: AppBar(title: const Text('Fornecedores')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.fornecedores.length,
              itemBuilder: (context, index) {
                final fornecedor = provider.fornecedores[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
                  title: Text(fornecedor.nome),
                  subtitle: Text(fornecedor.telefone ?? 'Sem telefone'),
                  trailing: const Icon(Icons.chevron_right),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFornecedorModal,
        tooltip: 'Adicionar Fornecedor',
        child: const Icon(Icons.add),
      ),
    );
  }
}
