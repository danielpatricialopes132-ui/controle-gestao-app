import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../../../../shared/utils/pdf_utils.dart';
import '../providers/relatorios_provider.dart';

class AuditoriaConfirmarAba extends ConsumerStatefulWidget {
  const AuditoriaConfirmarAba({super.key});

  @override
  ConsumerState<AuditoriaConfirmarAba> createState() => _AuditoriaConfirmarAbaState();
}

class _AuditoriaConfirmarAbaState extends ConsumerState<AuditoriaConfirmarAba> {
  final _searchController = TextEditingController();
  final _formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _formatDate = DateFormat('dd/MM/yyyy');


  @override
  Widget build(BuildContext context) {
    final auditoriaAsync = ref.watch(auditoriaConfirmarProvider);

    return auditoriaAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Carregando transações a confirmar...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Erro ao carregar auditoria: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(auditoriaConfirmarProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        final resumo = data['resumo'] as Map<String, dynamic>? ?? {};
        final transacoes = (data['transacoes'] as List<dynamic>? ?? []);
        final totalItens = resumo['totalItens'] ?? transacoes.length;
        final totalValor = (resumo['totalValor'] ?? 0).toDouble();
        final totalDespesas = (resumo['totalDespesas'] ?? 0).toDouble();
        final totalReceitas = (resumo['totalReceitas'] ?? 0).toDouble();

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header de Destaque
                  _buildHeaderBanner(totalItens, totalValor, transacoes),
                  const SizedBox(height: 20),

                  // Cards de KPIs Modernos
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Pendentes de Auditoria',
                          value: '$totalItens',
                          subtitle: 'Itens a confirmar',
                          icon: Icons.pending_actions_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Despesas a Confirmar',
                          value: _formatCurrency.format(totalDespesas),
                          subtitle: 'Saídas sob análise',
                          icon: Icons.arrow_downward_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Receitas a Confirmar',
                          value: _formatCurrency.format(totalReceitas),
                          subtitle: 'Entradas pendentes',
                          icon: Icons.arrow_upward_rounded,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Barra de Busca e Filtro
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Pesquise por descrição, favorecido, obra ou observação...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (val) {
                                ref.read(auditoriaConfirmarBuscaProvider.notifier).setBusca(val);
                              },
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(auditoriaConfirmarBuscaProvider.notifier).setBusca('');
                              },
                            ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007A8D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              ref.read(auditoriaConfirmarBuscaProvider.notifier).setBusca(_searchController.text);
                            },
                            icon: const Icon(Icons.filter_alt_outlined, size: 18),
                            label: const Text('Filtrar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lista de Transações a Confirmar
                  if (transacoes.isEmpty)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.verified_outlined, size: 48, color: Color(0xFF10B981)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhuma transação com status "A Confirmar"!',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Todas as transações financeiras foram devidamente auditadas e conciliadas pela equipe.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transacoes.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final t = transacoes[index] as Map<String, dynamic>;
                        return _buildTransacaoAuditCard(t);
                      },
                    ),
                ],
              ),
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.2),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderBanner(int totalItens, double totalValor, List<dynamic> transacoes) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.policy_outlined, color: Color(0xFFF59E0B), size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auditoria de Transações "A Confirmar"',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Identifique lançamentos de cartão, débitos avulsos e conciliações pendentes de validação contábil.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007A8D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final dataList = transacoes.map((t) {
                final dt = t['dataVencimento'] != null ? _formatDate.format(DateTime.parse(t['dataVencimento'])) : '-';
                return [
                  dt,
                  t['descricao']?.toString() ?? '',
                  t['obra']?.toString() ?? '',
                  t['contaBancaria']?.toString() ?? '',
                  _formatCurrency.format(t['valor'] ?? 0),
                  t['observacao']?.toString() ?? '',
                ];
              }).toList();

              await PdfUtils.exportTablePdf(
                title: 'Relatório de Auditoria Financeira - A Confirmar',
                fileName: 'auditoria_a_confirmar',
                headers: ['Data', 'Descrição', 'Obra / Destino', 'Conta', 'Valor', 'Observação'],
                data: dataList,
              );
            },
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Exportar PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
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
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildTransacaoAuditCard(Map<String, dynamic> t) {
    final isReceita = t['tipo'] == 'RECEITA';
    final val = (t['valor'] ?? 0).toDouble();
    final dtStr = t['dataVencimento'] ?? t['dataPagamento'];
    final dataFormatada = dtStr != null ? _formatDate.format(DateTime.parse(dtStr)) : 'Sem data';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge de Tipo
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isReceita ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isReceita ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: isReceita ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Detalhes Principais
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['descricao'] ?? 'Sem descrição',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildChip(Icons.calendar_today_outlined, dataFormatada, Colors.blueGrey),
                        _buildChip(Icons.account_balance_outlined, t['contaBancaria'] ?? 'Conta não informada', const Color(0xFF007A8D)),
                        _buildChip(Icons.domain_outlined, t['obra'] ?? 'Geral', const Color(0xFF6366F1)),
                        _buildChip(Icons.category_outlined, t['categoria'] ?? 'Sem categoria', const Color(0xFF8B5CF6)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Valor e Badge de Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    (isReceita ? '+ ' : '- ') + _formatCurrency.format(val),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: isReceita ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFD97706)),
                        SizedBox(width: 4),
                        Text(
                          'A CONFIRMAR',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (t['observacao'] != null && t['observacao'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t['observacao'],
                      style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],

        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
