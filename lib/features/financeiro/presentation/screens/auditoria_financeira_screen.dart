import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/financeiro_provider.dart';
import '../transacao_modal.dart';

class AuditoriaFinanceiraScreen extends ConsumerStatefulWidget {
  const AuditoriaFinanceiraScreen({super.key});

  @override
  ConsumerState<AuditoriaFinanceiraScreen> createState() => _AuditoriaFinanceiraScreenState();
}

class _AuditoriaFinanceiraScreenState extends ConsumerState<AuditoriaFinanceiraScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmarExclusao(BuildContext context, String transacaoId, String descricao, double valor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Excluir Transação'),
          ],
        ),
        content: Text(
          'Deseja realmente excluir a transação duplicada?\n\n'
          '• Descrição: $descricao\n'
          '• Valor: ${currencyFormat.format(valor)}\n\n'
          'Esta ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              Future.microtask(() async {
                try {
                  await ref.read(financeiroControllerProvider.notifier).excluirTransacao(transacaoId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transação excluída com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao excluir: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              });
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _reclassificarRapido(
    BuildContext context,
    String transacaoId,
    String descricao,
    String? sugestaoId,
    String? sugestaoNome,
    List<dynamic> planoContasDisponivel,
  ) {
    String? categoriaSelecionada = sugestaoId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.auto_fix_high, color: Colors.purple),
                SizedBox(width: 8),
                Text('Enquadramento Contábil'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transação:\n$descricao',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (sugestaoNome != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.psychology, color: Colors.purple, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sugestão da IA:\n$sugestaoNome',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Selecione a Conta no Plano de Contas:'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: planoContasDisponivel.any((c) => c['id'] == categoriaSelecionada) ? categoriaSelecionada : null,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: planoContasDisponivel.map<DropdownMenuItem<String>>((c) {
                      return DropdownMenuItem<String>(
                        value: c['id'],
                        child: Text('${c['codigo'] ?? ''} - ${c['descricao'] ?? ''}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        categoriaSelecionada = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Confirmar Enquadramento'),
                onPressed: categoriaSelecionada == null
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                        Future.microtask(() async {
                          try {
                            await ref.read(financeiroControllerProvider.notifier).reclassificarTransacao(
                                  transacaoId,
                                  categoriaSelecionada!,
                                );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transação reenquadrada no plano de contas com sucesso!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao reenquadrar: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        });
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auditoriaAsync = ref.watch(auditoriaFinanceiraProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.purpleAccent, size: 28),
            SizedBox(width: 8),
            Text('Super Auditor Contábil (MASTER)'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recalcular Auditoria Completa',
            onPressed: () => ref.invalidate(auditoriaFinanceiraProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_tree), text: 'Plano de Contas & DRE'),
            Tab(icon: Icon(Icons.copy), text: 'Duplicidades'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Sem Comprovante'),
          ],
        ),
      ),
      body: auditoriaAsync.when(
        data: (data) {
          final resumo = data['resumo'] as Map<String, dynamic>? ?? {};
          final score = (data['scoreSaudeContabil'] as num?)?.toInt() ?? 100;
          final duplicidades = (data['duplicidades'] as List<dynamic>? ?? []);
          final pagosSemComprovante = (data['pagosSemComprovante'] as List<dynamic>? ?? []);
          final enquadramentos = (data['enquadramentoContabil'] as List<dynamic>? ?? []);
          final planoContas = (data['planoContasDisponivel'] as List<dynamic>? ?? []);

          return Column(
            children: [
              _buildScoreBar(score, resumo),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEnquadramentoTab(enquadramentos, planoContas),
                    _buildDuplicidadesTab(duplicidades),
                    _buildSemComprovanteTab(pagosSemComprovante),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Super Auditor processando regras contábeis, DRE e duplicidades...'),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Erro ao carregar o Super Auditor:\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(auditoriaFinanceiraProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBar(int score, Map<String, dynamic> resumo) {
    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 50) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    final totalTransacoes = resumo['totalTransacoesAnalisadas'] ?? 0;
    final qtdDuplicadas = resumo['qtdDuplicidades'] ?? 0;
    final qtdSemComp = resumo['qtdPagosSemComprovante'] ?? 0;
    final qtdEnquadramento = resumo['qtdSuspeitasEnquadramento'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          // Velocímetro Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scoreColor.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Saúde Contábil', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(
                  '$score%',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scoreColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChipBadge('Total Analisado: $totalTransacoes', Colors.blue),
                _buildChipBadge('Enquadramentos a Corrigir: $qtdEnquadramento', Colors.purple),
                _buildChipBadge('Duplicidades: $qtdDuplicadas', Colors.orange),
                _buildChipBadge('Sem Comprovante: $qtdSemComp', Colors.redAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildEnquadramentoTab(List<dynamic> enquadramentos, List<dynamic> planoContas) {
    if (enquadramentos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, color: Colors.green, size: 56),
            SizedBox(height: 12),
            Text(
              'Enquadramento Contábil Impecável!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Todos os lançamentos estão associados às contas corretas da DRE.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: enquadramentos.length,
      itemBuilder: (context, index) {
        final item = enquadramentos[index] as Map<String, dynamic>;
        final t = item['transacao'] as Map<String, dynamic>;
        final id = t['id'] ?? '';
        final desc = t['descricao'] ?? '';
        final valor = _toDouble(t['valor']);
        final tipo = t['tipo'] ?? 'DESPESA';
        final catAtual = t['categoriaFk']?['descricao'] ?? 'Nenhum / Não Classificado';
        final obraNome = t['obra']?['nome'] ?? 'Sem Obra Vinculada';
        final problema = item['problemaDetectado'] ?? '';
        final sugestaoNome = item['sugestaoDescricao'];
        final sugestaoId = item['sugestaoPlanoContaId'];
        final justificativa = item['justificativa'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.purple, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Problema: $problema',
                        style: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      currencyFormat.format(valor),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: tipo == 'RECEITA' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Obra: $obraNome | Categoria Atual: $catAtual',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.purple, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (sugestaoNome != null)
                              Text(
                                'Recomendação Contábil: $sugestaoNome',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple),
                              ),
                            Text(
                              justificativa,
                              style: const TextStyle(fontSize: 11, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Enquadrar', style: TextStyle(fontSize: 12)),
                        onPressed: () => _reclassificarRapido(
                          context,
                          id,
                          desc,
                          sugestaoId,
                          sugestaoNome,
                          planoContas,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDuplicidadesTab(List<dynamic> duplicidades) {
    if (duplicidades.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 56),
            SizedBox(height: 12),
            Text(
              'Nenhuma transação duplicada encontrada!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: duplicidades.length,
      itemBuilder: (context, index) {
        final grupo = duplicidades[index] as Map<String, dynamic>;
        final valor = _toDouble(grupo['valor']);
        final tipo = grupo['tipo'] ?? 'DESPESA';
        final motivo = grupo['motivo'] ?? '';
        final transacoes = (grupo['transacoes'] as List<dynamic>? ?? []);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.orange, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Grupo ${index + 1} (${transacoes.length} repetições)',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      currencyFormat.format(valor),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: tipo == 'RECEITA' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(motivo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Divider(height: 20),
                ...transacoes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final t = entry.value as Map<String, dynamic>;
                  final id = t['id'] ?? '';
                  final desc = t['descricao'] ?? '';
                  final status = t['status'] ?? 'PENDENTE';
                  final obraNome = t['obra']?['nome'] ?? 'Sem Obra';
                  final catNome = t['categoriaFk']?['descricao'] ?? 'Sem Categoria';
                  final isOriginalSugerido = idx == 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOriginalSugerido ? Colors.green.withOpacity(0.06) : Colors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOriginalSugerido ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isOriginalSugerido ? Colors.green : Colors.red,
                          child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                'Obra: $obraNome | Cat: $catNome | Status: $status',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                          onPressed: () => TransacaoModal.show(
                            context,
                            isReceita: t['tipo'] == 'RECEITA',
                            transacao: t,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _confirmarExclusao(context, id, desc, valor),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSemComprovanteTab(List<dynamic> pagosSemComprovante) {
    if (pagosSemComprovante.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, color: Colors.green, size: 56),
            SizedBox(height: 12),
            Text(
              '100% dos pagamentos possuem comprovante!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: pagosSemComprovante.length,
      itemBuilder: (context, index) {
        final t = pagosSemComprovante[index] as Map<String, dynamic>;
        final desc = t['descricao'] ?? '';
        final valor = _toDouble(t['valor']);
        final obraNome = t['obra']?['nome'] ?? 'Sem Obra';
        final catNome = t['categoriaFk']?['descricao'] ?? 'Sem Categoria';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.redAccent,
              child: Icon(Icons.receipt_long, color: Colors.white, size: 18),
            ),
            title: Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Obra: $obraNome | Categoria: $catNome'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currencyFormat.format(valor),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.blue),
                  onPressed: () => TransacaoModal.show(
                    context,
                    isReceita: t['tipo'] == 'RECEITA',
                    transacao: t,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
