import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/relatorios_provider.dart';

class LucratividadeAba extends ConsumerWidget {
  const LucratividadeAba({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lucAsync = ref.watch(lucratividadeProvider);
    final mesAno = ref.watch(relatorioMesAnoProvider);

    return lucAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Calculando margens e lucratividade por obra...', style: TextStyle(color: Colors.grey)),
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
              Text('Erro ao carregar lucratividade: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(lucratividadeProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        final resumo = data['resumo'] as Map<String, dynamic>? ?? {};
        final obras = (data['obras'] as List<dynamic>? ?? []);

        final formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
        final formatPercent = NumberFormat.decimalPattern('pt_BR');
        final formatMes = DateFormat('MMMM / yyyy', 'pt_BR').format(mesAno);

        final fatTotal = (resumo['faturamentoTotal'] ?? 0).toDouble();
        final custosFixos = (resumo['custosFixosTotais'] ?? 0).toDouble();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
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
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.leaderboard_outlined, color: Colors.amberAccent, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lucratividade Real por Obra ($formatMes)',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Demonstra a margem de cada projeto após o rateio proporcional das despesas fixas da sede.',
                            style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Totalizadores
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Faturamento Total Obras',
                      value: formatCurrency.format(fatTotal),
                      subtitle: '${obras.length} projetos monitorados',
                      icon: Icons.payments_outlined,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Custos Fixos a Ratear',
                      value: formatCurrency.format(custosFixos),
                      subtitle: 'Despesas estruturais da sede',
                      icon: Icons.domain_disabled_outlined,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Demonstrativo Individual por Obra',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
              ),
              const SizedBox(height: 12),

              if (obras.isEmpty)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(
                      child: Text(
                        'Nenhuma transação vinculada a obras neste mês.',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: obras.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final obra = obras[index] as Map<String, dynamic>;
                    final lucro = (obra['lucroLiquido'] ?? 0).toDouble();
                    final margem = (obra['margemLiquida'] ?? 0).toDouble();
                    final isPositivo = lucro >= 0;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isPositivo ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFEF4444).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPositivo ? Icons.domain_verification_rounded : Icons.warning_amber_rounded,
                            color: isPositivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            size: 22,
                          ),
                        ),
                        title: Text(
                          obra['nome']?.toString() ?? 'Obra sem nome',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Text(
                                'Resultado: ${formatCurrency.format(lucro)}',
                                style: TextStyle(
                                  color: isPositivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPositivo ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Margem: ${formatPercent.format(margem)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isPositivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(14),
                                bottomRight: Radius.circular(14),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow('Receitas Faturadas', obra['receitas'], formatCurrency, color: const Color(0xFF10B981)),
                                _buildDetailRow('(-) Custos Diretos de Obra', obra['custosDiretos'], formatCurrency, color: const Color(0xFFEF4444)),
                                _buildDetailRow('(=) Margem Bruta do Projeto', obra['lucroBruto'], formatCurrency, isBold: true, color: const Color(0xFF2563EB)),
                                const Divider(height: 16),
                                _buildDetailRow('(-) Rateio Proporcional Custos Sede', obra['rateioDespesasFixas'], formatCurrency, color: const Color(0xFFEF4444)),
                                _buildDetailRow('(=) Lucro Líquido Real da Obra', obra['lucroLiquido'], formatCurrency, isBold: true, color: isPositivo ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
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
        border: Border.all(color: Colors.grey.shade200),
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
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value, NumberFormat format, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 14 : 13,
              color: isBold ? const Color(0xFF0F172A) : Colors.grey.shade700,
            ),
          ),
          Text(
            format.format(value ?? 0),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 14 : 13,
              color: color ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
