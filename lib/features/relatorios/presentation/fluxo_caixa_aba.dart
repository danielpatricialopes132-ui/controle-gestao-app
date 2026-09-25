import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/pdf_utils.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/relatorios_provider.dart';

class FluxoCaixaAba extends ConsumerWidget {
  const FluxoCaixaAba({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fluxoAsync = ref.watch(fluxoCaixaProvider);

    return fluxoAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Projetando fluxo de caixa dos próximos meses...', style: TextStyle(color: Colors.grey)),
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
              Text('Erro ao carregar fluxo de caixa: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(fluxoCaixaProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Recarregar'),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        if (data.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Sem projeções de fluxo de caixa cadastradas para o período.'),
            ),
          );
        }

        final formatCurrency = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$');
        final formatFull = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF047857).withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Projeção de Fluxo de Caixa (6 Meses)',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Simulação de entradas e saídas previstas e saldo acumulado ao final de cada mês.',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF064E3B),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final dataList = data.map((item) {
                          final receitas = (item['receitasRealizadas'] ?? 0) + (item['receitasProjetadas'] ?? 0);
                          final despesas = (item['despesasRealizadas'] ?? 0) + (item['despesasProjetadas'] ?? 0);
                          final saldo = item['saldoTotalPrevisto'] ?? 0;
                          return [
                            item['mesAno'].toString(),
                            formatFull.format(receitas),
                            formatFull.format(despesas),
                            formatFull.format(saldo),
                          ];
                        }).toList();

                        await PdfUtils.exportTablePdf(
                          title: 'Projeção de Fluxo de Caixa',
                          fileName: 'fluxo_caixa_report',
                          headers: ['Mês', 'Receitas', 'Despesas', 'Saldo Final'],
                          data: dataList,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('Exportar PDF'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Gráfico Moderno
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Evolução Gráfica de Entradas e Saídas',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Wrap(
                            spacing: 16,
                            children: const [
                              _LegendItem(color: Color(0xFF10B981), text: 'Receitas'),
                              _LegendItem(color: Color(0xFFEF4444), text: 'Despesas'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 280,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _calculateMaxY(data),
                            minY: _calculateMinY(data),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => const Color(0xFF1E293B),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final isReceita = rod.color == const Color(0xFF10B981);
                                  return BarTooltipItem(
                                    '${isReceita ? "Receita" : "Despesa"}\n${formatFull.format(rod.toY.abs())}',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() < 0 || value.toInt() >= data.length) return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        data[value.toInt()]['mesAno'],
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) return const Text('0', style: TextStyle(fontSize: 10));
                                    return Text(formatCurrency.format(value), style: TextStyle(fontSize: 10, color: Colors.grey.shade600));
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: data.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final receitas = (item['receitasRealizadas'] + item['receitasProjetadas']).toDouble();
                              final despesas = (item['despesasRealizadas'] + item['despesasProjetadas']).toDouble();

                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: receitas,
                                    color: const Color(0xFF10B981),
                                    width: 14,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                  BarChartRodData(
                                    toY: -despesas,
                                    color: const Color(0xFFEF4444),
                                    width: 14,
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Lista Mensal Detalhada
              Text(
                'Detalhamento Mensal Previsto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = data[index];
                  final saldo = (item['saldoTotalPrevisto'] ?? 0).toDouble();
                  final receitas = (item['receitasRealizadas'] + item['receitasProjetadas']).toDouble();
                  final despesas = (item['despesasRealizadas'] + item['despesasProjetadas']).toDouble();

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFF007A8D).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.calendar_month, color: Color(0xFF007A8D), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['mesAno'].toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('Receitas: ${formatFull.format(receitas)}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 12),
                                    Text('Despesas: ${formatFull.format(despesas)}', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Saldo Previsto', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              const SizedBox(height: 2),
                              Text(
                                formatFull.format(saldo),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: saldo >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  double _calculateMaxY(List data) {
    double max = 0;
    for (var item in data) {
      double rec = (item['receitasRealizadas'] + item['receitasProjetadas']).toDouble();
      if (rec > max) max = rec;
    }
    return max > 0 ? max * 1.25 : 1000;
  }

  double _calculateMinY(List data) {
    double min = 0;
    for (var item in data) {
      double desp = -(item['despesasRealizadas'] + item['despesasProjetadas']).toDouble();
      if (desp < min) min = desp;
    }
    return min < 0 ? min * 1.25 : -1000;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
