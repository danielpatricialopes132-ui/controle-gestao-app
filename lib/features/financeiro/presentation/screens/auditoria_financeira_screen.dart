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
            onPressed: () async {
              Navigator.of(ctx).pop();
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
            },
            child: const Text('Excluir'),
          ),
        ],
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
            Icon(Icons.security, color: Colors.amber),
            SizedBox(width: 8),
            Text('Auditoria Inteligente (MASTER)'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar Auditoria',
            onPressed: () => ref.invalidate(auditoriaFinanceiraProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.copy), text: 'Duplicidades'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Sem Comprovante'),
            Tab(icon: Icon(Icons.rule), text: 'Classificação'),
          ],
        ),
      ),
      body: auditoriaAsync.when(
        data: (data) {
          final resumo = data['resumo'] as Map<String, dynamic>? ?? {};
          final duplicidades = (data['duplicidades'] as List<dynamic>? ?? []);
          final pagosSemComprovante = (data['pagosSemComprovante'] as List<dynamic>? ?? []);
          final semObra = (data['semObra'] as List<dynamic>? ?? []);
          final semCategoria = (data['semCategoria'] as List<dynamic>? ?? []);

          return Column(
            children: [
              _buildResumoCards(resumo),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDuplicidadesTab(duplicidades),
                    _buildSemComprovanteTab(pagosSemComprovante),
                    _buildClassificacaoTab(semObra, semCategoria),
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
              Text('Analisando registros financeiros e cruzando dados...'),
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
                  'Erro ao carregar auditoria:\n$err',
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

  Widget _buildResumoCards(Map<String, dynamic> resumo) {
    final totalTransacoes = resumo['totalTransacoesAnalisadas'] ?? 0;
    final qtdDuplicadas = resumo['totalTransacoesDuplicadas'] ?? 0;
    final impactoDuplicadas = _toDouble(resumo['totalImpactoDuplicatas']);
    final qtdSemComprovante = resumo['qtdPagosSemComprovante'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              label: 'Total Analisado',
              value: '$totalTransacoes',
              icon: Icons.search,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'Duplicadas Suspeitas',
              value: '$qtdDuplicadas transações',
              subvalue: currencyFormat.format(impactoDuplicadas),
              icon: Icons.copy,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'Pagos s/ Comprovante',
              value: '$qtdSemComprovante pendentes',
              icon: Icons.receipt,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    String? subvalue,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
            if (subvalue != null)
              Text(
                subvalue,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
      ),
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
            SizedBox(height: 4),
            Text(
              'Todos os lançamentos financeiros aparentam estar regulares.',
              style: TextStyle(color: Colors.grey),
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
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Grupo ${index + 1} (${transacoes.length} lançamentos)',
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
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
                Text(
                  motivo,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Divider(height: 20),
                ...transacoes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final t = entry.value as Map<String, dynamic>;
                  final id = t['id'] ?? '';
                  final desc = t['descricao'] ?? '';
                  final status = t['status'] ?? 'PENDENTE';
                  final obraNome = t['obra']?['nome'] ?? 'Sem Obra';
                  final catNome = t['categoriaFk']?['descricao'] ?? 'Sem Categoria';
                  final dataStr = t['dataPagamento'] ?? t['dataVencimento'] ?? t['createdAt'];
                  DateTime? dataParsed;
                  if (dataStr != null) {
                    dataParsed = DateTime.tryParse(dataStr);
                  }

                  final isOriginalSugerido = idx == 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOriginalSugerido
                          ? Colors.green.withOpacity(0.06)
                          : Colors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOriginalSugerido
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isOriginalSugerido ? Colors.green : Colors.red,
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      desc,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                  if (isOriginalSugerido)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Principal / Original',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Possível Duplicata',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    'Data: ${dataParsed != null ? dateFormat.format(dataParsed) : 'N/A'}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    'Obra: $obraNome',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    'Cat: $catNome',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    'Status: $status',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: status == 'PAGO' ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                          tooltip: 'Editar Transação',
                          onPressed: () {
                            TransacaoModal.show(
                              context,
                              isReceita: t['tipo'] == 'RECEITA',
                              transacao: t,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          tooltip: 'Excluir Lançamento',
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
            SizedBox(height: 4),
            Text(
              'Nenhuma inconsistência fiscal detectada.',
              style: TextStyle(color: Colors.grey),
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
        final dataStr = t['dataPagamento'] ?? t['dataVencimento'] ?? t['createdAt'];
        DateTime? dataParsed;
        if (dataStr != null) {
          dataParsed = DateTime.tryParse(dataStr);
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.redAccent,
              child: Icon(Icons.receipt_long, color: Colors.white, size: 18),
            ),
            title: Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Obra: $obraNome | Categoria: $catNome'),
                if (dataParsed != null)
                  Text('Pago em: ${dateFormat.format(dataParsed)}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currencyFormat.format(valor),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                            IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.blue),
                  tooltip: 'Anexar Comprovante / Editar',
                  onPressed: () {
                    TransacaoModal.show(
                      context,
                      isReceita: t['tipo'] == 'RECEITA',
                      transacao: t,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassificacaoTab(List<dynamic> semObra, List<dynamic> semCategoria) {
    if (semObra.isEmpty && semCategoria.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category, color: Colors.green, size: 56),
            SizedBox(height: 12),
            Text(
              'Todas as transações estão classificadas!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Obras e categorias devidamente associadas.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (semObra.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.home_work, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Transações sem Obra Vinculada (${semObra.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          ...semObra.take(15).map((t) {
            final valor = _toDouble(t['valor']);
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                title: Text(t['descricao'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currencyFormat.format(valor), style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
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
          }),
        ],
        if (semCategoria.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.label_off, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Transações sem Categoria/Plano de Contas (${semCategoria.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          ...semCategoria.take(15).map((t) {
            final valor = _toDouble(t['valor']);
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                title: Text(t['descricao'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currencyFormat.format(valor), style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
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
          }),
        ],
      ],
    );
  }
}
