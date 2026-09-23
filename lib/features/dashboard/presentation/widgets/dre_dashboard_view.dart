import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';

class DreDashboardView extends ConsumerStatefulWidget {
  const DreDashboardView({Key? key}) : super(key: key);

  @override
  ConsumerState<DreDashboardView> createState() => _DreDashboardViewState();
}

class _DreDashboardViewState extends ConsumerState<DreDashboardView> {
  String _filtroAtual = 'ano'; // 'mes', 'trimestre', 'ano'
  final _formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  Map<String, String> _getParams() {
    final hoje = DateTime.now();
    DateTime inicio;
    DateTime fim = DateTime(hoje.year, hoje.month + 1, 0, 23, 59, 59);

    if (_filtroAtual == 'mes') {
      inicio = DateTime(hoje.year, hoje.month, 1);
    } else if (_filtroAtual == 'trimestre') {
      int mesInicio = ((hoje.month - 1) ~/ 3) * 3 + 1;
      inicio = DateTime(hoje.year, mesInicio, 1);
    } else {
      inicio = DateTime(hoje.year, 1, 1);
      fim = DateTime(hoje.year, 12, 31, 23, 59, 59);
    }

    return {
      'dataInicio': inicio.toIso8601String(),
      'dataFim': fim.toIso8601String(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final dreAsync = ref.watch(dreProvider(_getParams()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Demonstração do Resultado (DRE)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'mes', label: Text('Mês')),
                ButtonSegment(value: 'trimestre', label: Text('Tri')),
                ButtonSegment(value: 'ano', label: Text('Ano')),
              ],
              selected: {_filtroAtual},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _filtroAtual = newSelection.first;
                });
              },
            )
          ],
        ),
        const SizedBox(height: 16),
        dreAsync.when(
          loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
          error: (err, stack) => SizedBox(height: 200, child: Center(child: Text('Erro ao carregar DRE: $err'))),
          data: (data) {
            final ind = data['indicadores'] ?? {};
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDreSummaryCards(ind),
                const SizedBox(height: 24),
                SizedBox(
                  height: 300,
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: _buildWaterfallChart(ind)),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: _buildMarginCard(ind)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDreSummaryCards(Map<String, dynamic> ind) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final double width = isDesktop ? 200 : 150;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMiniCard('Receita Bruta', ind['receitaBruta'], Colors.blue, width),
        _buildMiniCard('Custos Diretos', ind['custosDiretos'], Colors.red, width),
        _buildMiniCard('Lucro Bruto', ind['lucroBruto'], Colors.orange, width),
        _buildMiniCard('Desp. Operacionais', ind['despesasOperacionais'], Colors.redAccent, width),
        _buildMiniCard('EBITDA', ind['ebitda'], Colors.green, width),
        _buildMiniCard('Lucro Líquido', ind['lucroLiquido'], Colors.teal, width),
      ],
    );
  }

  Widget _buildMiniCard(String title, dynamic value, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            _formatCurrency.format((value ?? 0).toDouble()),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildMarginCard(Map<String, dynamic> ind) {
    double margemBruta = (ind['margemBruta'] ?? 0).toDouble();
    double margemLiquida = (ind['margemLiquida'] ?? 0).toDouble();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Margens do Negócio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Margem Bruta', style: TextStyle(color: Colors.grey)),
            Text('${margemBruta.toStringAsFixed(1)}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: margemBruta >= 0 ? Colors.green : Colors.red)),
            const SizedBox(height: 24),
            const Text('Margem Líquida', style: TextStyle(color: Colors.grey)),
            Text('${margemLiquida.toStringAsFixed(1)}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: margemLiquida >= 0 ? Colors.teal : Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterfallChart(Map<String, dynamic> ind) {
    // Um gráfico de barras simples simulando o DRE (Cascata)
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Composição do Resultado', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (ind['receitaBruta'] ?? 0).toDouble() * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10);
                          String text;
                          switch (value.toInt()) {
                            case 0: text = 'Rec. Bruta'; break;
                            case 1: text = 'Custos'; break;
                            case 2: text = 'L. Bruto'; break;
                            case 3: text = 'Despesas'; break;
                            case 4: text = 'L. Líquido'; break;
                            default: text = ''; break;
                          }
                          return SideTitleWidget(meta: meta, space: 4, child: Text(text, style: style));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ((ind['receitaBruta'] ?? 1000) / 4).toDouble(),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeGroupData(0, (ind['receitaBruta'] ?? 0).toDouble(), Colors.blue),
                    _makeGroupData(1, (ind['custosDiretos'] ?? 0).toDouble(), Colors.red),
                    _makeGroupData(2, (ind['lucroBruto'] ?? 0).toDouble(), Colors.orange),
                    _makeGroupData(3, (ind['despesasOperacionais'] ?? 0).toDouble(), Colors.redAccent),
                    _makeGroupData(4, (ind['lucroLiquido'] ?? 0).toDouble(), (ind['lucroLiquido'] ?? 0) >= 0 ? Colors.teal : Colors.red),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y.abs(),
          color: color,
          width: 32,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: y < 0 ? y.abs() : 0,
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }
}
