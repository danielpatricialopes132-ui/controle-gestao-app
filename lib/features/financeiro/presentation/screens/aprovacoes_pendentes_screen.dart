import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/aprovacao_financeira_provider.dart';

class AprovacoesPendentesScreen extends ConsumerStatefulWidget {
  const AprovacoesPendentesScreen({super.key});

  @override
  ConsumerState<AprovacoesPendentesScreen> createState() => _AprovacoesPendentesScreenState();
}

class _AprovacoesPendentesScreenState extends ConsumerState<AprovacoesPendentesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(aprovacaoFinanceiraProvider.notifier).fetchPendentes());
  }

  Future<void> _aprovarTudo() async {
    final state = ref.read(aprovacaoFinanceiraProvider);
    final ids = state.transacoesPendentes.map((t) => t.id).toList();
    if (ids.isEmpty) return;

    final sucesso = await ref.read(aprovacaoFinanceiraProvider.notifier).aprovarTransacoes(ids);
    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transações aprovadas com sucesso!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aprovacaoFinanceiraProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprovações Pendentes'),
        actions: [
          if (state.transacoesPendentes.isNotEmpty)
            TextButton.icon(
              onPressed: _aprovarTudo,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text('Aprovar Tudo', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Erro: ${state.error}'))
              : state.transacoesPendentes.isEmpty
                  ? const Center(child: Text('Nenhuma aprovação pendente no momento.'))
                  : ListView.builder(
                      itemCount: state.transacoesPendentes.length,
                      itemBuilder: (context, index) {
                        final transacao = state.transacoesPendentes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(transacao.descricao),
                            subtitle: Text('Valor: R\$ ${transacao.valor.toStringAsFixed(2)}\nTipo: ${transacao.tipo}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => ref.read(aprovacaoFinanceiraProvider.notifier).rejeitarTransacoes([transacao.id]),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => ref.read(aprovacaoFinanceiraProvider.notifier).aprovarTransacoes([transacao.id]),
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
