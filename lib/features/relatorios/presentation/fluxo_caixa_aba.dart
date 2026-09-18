import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/relatorios_provider.dart';

class FluxoCaixaAba extends ConsumerWidget {
  const FluxoCaixaAba({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fluxoAsync = ref.watch(fluxoCaixaProvider);

    return fluxoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erro: $e')),
      data: (data) {
        if (data.isEmpty) {
          return const Center(child: Text('Sem dados de fluxo de caixa.'));
        }

        final formatCurrency = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$');
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Projeção de Fluxo de Caixa (6 meses)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 16,
                children: [
                  _LegendItem(color: Colors.green, text: 'Receitas'),
                  _LegendItem(color: Colors.red, text: 'Despesas'),
                  _LegendItem(color: Colors.blue, text: 'Saldo Previsto'),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _calculateMaxY(data),
                    minY: _calculateMinY(data),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.blueGrey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            formatCurrency.format(rod.toY),
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                              child: Text(data[value.toInt()]['mesAno'], style: const TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text('0', style: TextStyle(fontSize: 10));
                            return Text(formatCurrency.format(value), style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    barGroups: data.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final receitas = (item['receitasRealizadas'] + item['receitasProjetadas']).toDouble();
                      final despesas = (item['despesasRealizadas'] + item['despesasProjetadas']).toDouble();
                      
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(toY: receitas, color: Colors.green, width: 12, borderRadius: BorderRadius.circular(4)),
                          BarChartRodData(toY: -despesas, color: Colors.red, width: 12, borderRadius: BorderRadius.circular(4)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final formatFull = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
                    final saldo = item['saldoTotalPrevisto'];
                    return Card(
                      child: ListTile(
                        title: Text('Mês: ${item['mesAno']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Receitas: ${formatFull.format(item['receitasRealizadas'] + item['receitasProjetadas'])}', style: const TextStyle(color: Colors.green)),
                            Text('Despesas: ${formatFull.format(item['despesasRealizadas'] + item['despesasProjetadas'])}', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Saldo Final'),
                            Text(formatFull.format(saldo), style: TextStyle(fontWeight: FontWeight.bold, color: saldo >= 0 ? Colors.green : Colors.red)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
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
    return max * 1.2;
  }

  double _calculateMinY(List data) {
    double min = 0;
    for (var item in data) {
      double desp = -(item['despesasRealizadas'] + item['despesasProjetadas']).toDouble();
      if (desp < min) min = desp;
    }
    return min * 1.2;
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
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
