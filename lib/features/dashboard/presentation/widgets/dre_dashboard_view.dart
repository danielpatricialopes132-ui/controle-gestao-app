import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';

class DreDashboardView extends ConsumerStatefulWidget {
  const DreDashboardView({super.key});

  @override
  ConsumerState<DreDashboardView> createState() => _DreDashboardViewState();
}

class _DreDashboardViewState extends ConsumerState<DreDashboardView> {
  String _filtroAtual = 'ano'; // 'mes', 'trimestre', 'ano'
  final _formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  double _parseNum(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

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
          loading: () => const SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(height: 12),
                  Text('Carregando dados da DRE...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          ),
          error: (err, stack) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Não foi possível carregar os dados contábeis da DRE: $err', style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Recarregar'),
                  onPressed: () => ref.invalidate(dreProvider),
                ),
              ],
            ),
          ),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            _formatCurrency.format(_parseNum(value)),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildMarginCard(Map<String, dynamic> ind) {
    double margemBruta = _parseNum(ind['margemBruta']);
    double margemLiquida = _parseNum(ind['margemLiquida']);

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
    final recBruta = _parseNum(ind['receitaBruta']);
    final custos = _parseNum(ind['custosDiretos']);
    final lucroBruto = _parseNum(ind['lucroBruto']);
    final despesas = _parseNum(ind['despesasOperacionais']);
    final lucroLiq = _parseNum(ind['lucroLiquido']);

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
                  maxY: (recBruta > 0 ? recBruta : 1000) * 1.2,
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
                    horizontalInterval: (recBruta > 0 ? (recBruta / 4) : 250),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeGroupData(0, recBruta, Colors.blue),
                    _makeGroupData(1, custos, Colors.red),
                    _makeGroupData(2, lucroBruto, Colors.orange),
                    _makeGroupData(3, despesas, Colors.redAccent),
                    _makeGroupData(4, lucroLiq, lucroLiq >= 0 ? Colors.teal : Colors.red),
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
