import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/categorias_provider.dart';
import '../providers/financeiro_provider.dart';
import '../../../shared/providers/api_client_provider.dart';

class ConfiguracaoContabilScreen extends ConsumerStatefulWidget {
  const ConfiguracaoContabilScreen({super.key});

  @override
  ConsumerState<ConfiguracaoContabilScreen> createState() => _ConfiguracaoContabilScreenState();
}

class _ConfiguracaoContabilScreenState extends ConsumerState<ConfiguracaoContabilScreen> {
  final _codigoController = TextEditingController();
  final _descricaoController = TextEditingController();
  String _tipoSelecionado = 'DESPESA';

  final _nomeBancoController = TextEditingController();
  final _saldoInicialController = TextEditingController();

  @override
  void dispose() {
    _codigoController.dispose();
    _descricaoController.dispose();
    _nomeBancoController.dispose();
    _saldoInicialController.dispose();
    super.dispose();
  }

  void _limparForm() {
    _codigoController.clear();
    _descricaoController.clear();
    setState(() {
      _tipoSelecionado = 'DESPESA';
    });
  }

  Future<void> _adicionarCategoria() async {
    final codigo = _codigoController.text.trim();
    final descricao = _descricaoController.text.trim();

    if (codigo.isEmpty || descricao.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha código e descrição.')));
      return;
    }

    try {
      await ref.read(categoriaControllerProvider.notifier).criar({
        'codigo': codigo,
        'descricao': descricao,
        'tipo': _tipoSelecionado,
      });
      _limparForm();
      ref.invalidate(categoriasProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _excluirCategoria(String id) async {
    try {
      await ref.read(categoriaControllerProvider.notifier).excluir(id);
      ref.invalidate(categoriasProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
  }

  Future<void> _adicionarContaBancaria() async {
    final nome = _nomeBancoController.text.trim();
    final saldoTexto = _saldoInicialController.text.trim().replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
    
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha o nome do banco/caixa.')));
      return;
    }

    try {
      await ref.read(apiClientProvider).post('/financeiro/contas-bancarias', {
        'nome': nome,
        'saldoInicial': saldoTexto.isEmpty ? 0 : (double.tryParse(saldoTexto) ?? 0),
      });
      _nomeBancoController.clear();
      _saldoInicialController.clear();
      ref.invalidate(contasBancariasProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _excluirContaBancaria(String id) async {
    try {
      await ref.read(apiClientProvider).delete('/financeiro/contas-bancarias/$id');
      ref.invalidate(contasBancariasProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
  }

  void _mostrarEdicaoConta(Map<String, dynamic> conta) {
    final nomeController = TextEditingController(text: conta['nome']);
    final saldoController = TextEditingController(text: conta['saldoInicial']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Conta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome da Conta', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: saldoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Saldo Inicial (R\$)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              final saldoTexto = saldoController.text.trim().replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
              
              if (nome.isEmpty) return;
              
              try {
                await ref.read(apiClientProvider).put('/financeiro/contas-bancarias/${conta['id']}', {
                  'nome': nome,
                  'saldoInicial': saldoTexto.isEmpty ? 0 : (double.tryParse(saldoTexto) ?? 0),
                });
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ref.invalidate(contasBancariasProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao editar: $e')));
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final asyncCategorias = ref.watch(categoriasProvider);
    final isSaving = ref.watch(categoriaControllerProvider) is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração Contábil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plano de Contas Panel
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Plano de Contas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _codigoController,
                            decoration: const InputDecoration(labelText: 'Cód (ex: 2.1)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: _descricaoController,
                            decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _tipoSelecionado,
                            decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'DESPESA', child: Text('Despesa')),
                              DropdownMenuItem(value: 'RECEITA', child: Text('Receita')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _tipoSelecionado = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSaving ? null : _adicionarCategoria,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          ),
                          child: const Icon(Icons.add),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: asyncCategorias.when(
                        data: (categorias) {
                          if (categorias.isEmpty) {
                            return const Center(child: Text('Nenhuma categoria cadastrada.'));
                          }
                          return ListView.builder(
                            itemCount: categorias.length,
                            itemBuilder: (context, index) {
                              final cat = categorias[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: Colors.black87, fontSize: 16),
                                      children: [
                                        TextSpan(text: '${cat['codigo']} - ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: cat['descricao']),
                                      ]
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Chip(
                                        label: Text(cat['tipo'], style: const TextStyle(fontSize: 10)),
                                        backgroundColor: cat['tipo'] == 'RECEITA' ? Colors.green.shade100 : Colors.red.shade100,
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => _excluirCategoria(cat['id']),
                                      )
                                    ],
                                  ),
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
          ),
          
          // Contas Bancárias Panel
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Contas Bancárias / Caixas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _nomeBancoController,
                            decoration: const InputDecoration(labelText: 'Nome (ex: Itaú, Caixa Físico)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _saldoInicialController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Saldo Inicial (R\$)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _adicionarContaBancaria,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          ),
                          child: const Icon(Icons.add),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final asyncContas = ref.watch(contasBancariasProvider);
                          return asyncContas.when(
                            data: (contas) {
                              if (contas.isEmpty) {
                                return const Center(child: Text('Nenhuma conta cadastrada.'));
                              }
                              return ListView.builder(
                                itemCount: contas.length,
                                itemBuilder: (context, index) {
                                  final conta = contas[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const Icon(Icons.account_balance, color: Colors.blueGrey),
                                      title: Text(conta['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('Saldo Atual: R\$ ${(double.tryParse(conta['saldoAtual']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _mostrarEdicaoConta(conta),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _excluirContaBancaria(conta['id']),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, st) => Center(child: Text('Erro: $e')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
