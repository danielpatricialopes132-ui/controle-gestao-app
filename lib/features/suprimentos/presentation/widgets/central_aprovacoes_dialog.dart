import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../providers/suprimentos_provider.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/notificacoes_menu_widget.dart';

final aprovacoesPendentesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/aprovacoes/pendentes');
  if (res is Map<String, dynamic> && res['success'] == true) {
    return res;
  }
  return {'totalPendentes': 0, 'totalPodeAprovar': 0, 'itens': []};
});

class CentralAprovacoesDialog extends ConsumerStatefulWidget {
  const CentralAprovacoesDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const CentralAprovacoesDialog(),
    );
  }

  @override
  ConsumerState<CentralAprovacoesDialog> createState() => _CentralAprovacoesDialogState();
}

class _CentralAprovacoesDialogState extends ConsumerState<CentralAprovacoesDialog> {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  bool _processando = false;

  Future<void> _deliberarItem({
    required String tipoEntidade,
    required String entidadeId,
    required String decisao,
    String? justificativa,
  }) async {
    setState(() => _processando = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post('/aprovacoes/decidir', {
        'tipoEntidade': tipoEntidade,
        'entidadeId': entidadeId,
        'decisao': decisao,
        'justificativa': justificativa,
      });

      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['mensagem'] ?? 'Deliberação registrada com sucesso!'),
              backgroundColor: decisao == 'APROVADO' ? Colors.green : Colors.red,
            ),
          );
          ref.invalidate(aprovacoesPendentesProvider);
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(notificacoesProvider);
          ref.read(suprimentosProvider.notifier).fetchOrdensCompra();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['error'] ?? 'Não foi possível deliberar.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  void _confirmarDecisao(Map<String, dynamic> item, String decisao) {
    final justificativaCtrl = TextEditingController();
    final isAprovacao = decisao == 'APROVADO';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAprovacao ? 'Confirmar Aprovação' : 'Confirmar Rejeição'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item['titulo']}\nValor: ${_currencyFormat.format(item['valorTotal'] ?? 0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              isAprovacao
                ? 'Deseja autorizar este item e lançar no Contas a Pagar?'
                : 'Informe a justificativa da rejeição/glosa técnica:',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: justificativaCtrl,
              decoration: InputDecoration(
                labelText: isAprovacao ? 'Observação (Opcional)' : 'Justificativa *',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!isAprovacao && justificativaCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A justificativa é obrigatória para rejeição.')),
                );
                return;
              }
              Navigator.pop(ctx);
              _deliberarItem(
                tipoEntidade: item['tipo'],
                entidadeId: item['id'],
                decisao: decisao,
                justificativa: justificativaCtrl.text.trim().isNotEmpty ? justificativaCtrl.text.trim() : null,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAprovacao ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isAprovacao ? 'Aprovar Agora' : 'Rejeitar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aprovacoesAsync = ref.watch(aprovacoesPendentesProvider);
    final size = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 850,
          maxHeight: size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007A8D).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.gavel, color: Color(0xFF007A8D), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Central de Alçadas & Deliberações',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Governança de Compras, Medições e Alçadas de Diretoria',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Lista de Pendências
              Expanded(
                child: aprovacoesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Erro: $err', style: const TextStyle(color: Colors.red))),
                  data: (dados) {
                    final List<dynamic> itens = dados['itens'] ?? [];
                    final total = dados['totalPendentes'] ?? 0;
                    final totalPodeAprovar = dados['totalPodeAprovar'] ?? 0;

                    if (itens.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhuma pendência de aprovação!',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Todas as ordens de compra e medições estão deliberadas.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card de resumo das alçadas
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blueGrey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Pendentes: $total  |  Disponíveis para sua alçada: $totalPodeAprovar',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey.shade800),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                onPressed: () => ref.invalidate(aprovacoesPendentesProvider),
                                tooltip: 'Recarregar',
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: itens.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = itens[index];
                              final isOC = item['tipo'] == 'ORDEM_COMPRA';
                              final podeAprovar = item['podeAprovar'] == true;
                              final valor = item['valorTotal'] ?? 0;
                              final data = DateTime.tryParse(item['data']?.toString() ?? '');

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: podeAprovar ? const Color(0xFF007A8D).withValues(alpha: 0.3) : Colors.grey.shade300,
                                    width: podeAprovar ? 1.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isOC ? Colors.blue.shade50 : Colors.indigo.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isOC ? 'ORDEM DE COMPRA' : 'MEDIÇÃO DE EMPREITEIRO',
                                                style: TextStyle(
                                                  color: isOC ? Colors.blue.shade800 : Colors.indigo.shade800,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (data != null)
                                              Text(
                                                _dateFormat.format(data),
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                              ),
                                          ],
                                        ),
                                        Text(
                                          _currencyFormat.format(valor),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF007A8D),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['titulo'] ?? '',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['subtitulo'] ?? '',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(height: 10),
                                    // Alerta de Alçada
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: podeAprovar ? Colors.green.shade50 : Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            podeAprovar ? Icons.verified_user : Icons.lock_clock,
                                            size: 14,
                                            color: podeAprovar ? Colors.green.shade800 : Colors.amber.shade900,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item['motivoAlcada'] ?? '',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: podeAprovar ? Colors.green.shade900 : Colors.amber.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Ações
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (podeAprovar) ...[
                                          OutlinedButton.icon(
                                            onPressed: _processando ? null : () => _confirmarDecisao(item, 'REJEITADO'),
                                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                            label: const Text('Rejeitar', style: TextStyle(color: Colors.red)),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.red),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          ElevatedButton.icon(
                                            onPressed: _processando ? null : () => _confirmarDecisao(item, 'APROVADO'),
                                            icon: const Icon(Icons.check, size: 16),
                                            label: const Text('Aprovar com 1 Clique'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ),
                                        ] else ...[
                                          Tooltip(
                                            message: 'Seu perfil não possui alçada para este valor',
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Exige perfil: ${item['aprovadorNecessarioRole'] ?? 'DIRETORIA'}',
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
