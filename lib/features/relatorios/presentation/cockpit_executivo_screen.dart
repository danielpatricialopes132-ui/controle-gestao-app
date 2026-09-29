import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/providers/api_client_provider.dart';

final cockpitProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/relatorios/cockpit');
  if (res is Map<String, dynamic> && res['success'] == true) {
    return res['data'] ?? {};
  }
  return {};
});

class CockpitExecutivoScreen extends ConsumerStatefulWidget {
  const CockpitExecutivoScreen({super.key});

  @override
  ConsumerState<CockpitExecutivoScreen> createState() => _CockpitExecutivoScreenState();
}

class _CockpitExecutivoScreenState extends ConsumerState<CockpitExecutivoScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  String? _obraSelecionadaId;

  @override
  Widget build(BuildContext context) {
    final cockpitAsync = ref.watch(cockpitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cockpit Executivo & Curva S'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(cockpitProvider),
            tooltip: 'Atualizar Dados',
          ),
        ],
      ),
      body: cockpitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Erro ao carregar Cockpit: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (dados) {
          final resumo = dados['resumoGeral'] ?? {};
          final List<dynamic> obras = dados['obras'] ?? [];

          if (obras.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Nenhuma obra ativa com dados para Curva S',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Cadastre contratos e transações para gerar o previsto vs. realizado.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final obraAtual = _obraSelecionadaId == null
              ? obras.first
              : obras.firstWhere((o) => o['id'] == _obraSelecionadaId, orElse: () => obras.first);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topo: Indicadores Macro (Previsto vs Realizado Geral)
                _buildMacroKpis(resumo),
                const SizedBox(height: 24),

                // Seletor de Obra para Análise Detalhada
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Análise Detalhada da Obra',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: obraAtual['id'],
                      underline: const SizedBox(),
                      items: obras.map<DropdownMenuItem<String>>((o) {
                        return DropdownMenuItem<String>(
                          value: o['id'],
                          child: Text(o['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _obraSelecionadaId = val;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card de Saúde Financeira & EVM (Earned Value Management)
                _buildSaudeEvmCard(obraAtual),
                const SizedBox(height: 24),

                // Gráfico Curva S (Previsto Físico vs Realizado Físico & Financeiro)
                _buildCurvaSChart(obraAtual),
                const SizedBox(height: 24),

                // Tabela de Burn Rate & Saldo Orçamentário
                _buildBurnRateSection(obraAtual),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMacroKpis(Map<String, dynamic> resumo) {
    final orcado = (resumo['totalOrcado'] as num?)?.toDouble() ?? 0.0;
    final realizado = (resumo['totalRealizado'] as num?)?.toDouble() ?? 0.0;
    final saldo = (resumo['saldoGeral'] as num?)?.toDouble() ?? 0.0;
    final desvio = (resumo['desvioPercentual'] as num?)?.toDouble() ?? 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 700;
        final cardWidth = isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard('Orçamento Previsto', _currencyFormat.format(orcado), Icons.pie_chart_outline, Colors.blue),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard('Custo Real Desembolsado', _currencyFormat.format(realizado), Icons.payments_outlined, Colors.purple),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                'Saldo Operacional',
                _currencyFormat.format(saldo),
                Icons.account_balance_wallet,
                saldo >= 0 ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                'Desvio de Custo',
                '${desvio > 0 ? '+' : ''}$desvio%',
                Icons.trending_up,
                desvio <= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(String title, String valor, IconData icon, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: cor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSaudeEvmCard(Map<String, dynamic> obra) {
    final progFisico = (obra['progressoFisico'] as num?)?.toInt() ?? 0;
    final progFinanceiro = (obra['progressoFinanceiro'] as num?)?.toInt() ?? 0;
    final cpi = (obra['cpi'] as num?)?.toDouble() ?? 1.0;
    final statusCpi = obra['cpiStatus'] ?? 'SAUDAVEL';

    Color corStatus = Colors.green;
    String labelStatus = 'Custo Controlado (No Orçamento)';
    if (statusCpi == 'ATENCAO') {
      corStatus = Colors.orange;
      labelStatus = 'Alerta: Consumo Acelerado';
    } else if (statusCpi == 'CRITICO') {
      corStatus = Colors.red;
      labelStatus = 'Crítico: Estouro Orçamentário';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Obra: ${obra['nome']}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: corStatus.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: corStatus),
                    const SizedBox(width: 6),
                    Text(
                      'CPI $cpi - $labelStatus',
                      style: TextStyle(color: corStatus, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Avanço Físico: $progFisico%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progFisico / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.teal,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Desembolso Financeiro: $progFinanceiro%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progFinanceiro / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.purple,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurvaSChart(Map<String, dynamic> obra) {
    final List<dynamic> pontos = obra['curvaS'] ?? [];

    final spotsPrevisto = <FlSpot>[];
    final spotsRealizado = <FlSpot>[];

    for (int i = 0; i < pontos.length; i++) {
      final p = pontos[i];
      spotsPrevisto.add(FlSpot(i.toDouble(), (p['previstoFisico'] as num?)?.toDouble() ?? 0.0));
      spotsRealizado.add(FlSpot(i.toDouble(), (p['realizadoFisico'] as num?)?.toDouble() ?? 0.0));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Curva S - Avanço Físico (%)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Linha Sigmóide Previsto vs. Medição Real', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Row(
                children: [
                  Row(
                    children: [
                      Container(width: 12, height: 4, color: Colors.blue),
                      const SizedBox(width: 6),
                      const Text('Planejado', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Row(
                    children: [
                      Container(width: 12, height: 4, color: Colors.teal),
                      const SizedBox(width: 6),
                      const Text('Realizado', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (val, _) => Text('${val.toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < pontos.length) {
                          return Text(pontos[idx]['marco'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spotsPrevisto,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: spotsRealizado,
                    isCurved: true,
                    color: Colors.teal,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.teal.withValues(alpha: 0.1),
                    ),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBurnRateSection(Map<String, dynamic> obra) {
    final orcamento = (obra['orcamentoTotal'] as num?)?.toDouble() ?? 0.0;
    final gasto = (obra['totalGasto'] as num?)?.toDouble() ?? 0.0;
    final saldo = (obra['saldoRestante'] as num?)?.toDouble() ?? 0.0;
    final burnRate = (obra['burnRateMensal'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Burn Rate & Previsão Orçamentária Restante',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBurnItem('Orçamento Pactuado', _currencyFormat.format(orcamento)),
              _buildBurnItem('Gasto Real Total', _currencyFormat.format(gasto)),
              _buildBurnItem('Saldo Restante', _currencyFormat.format(saldo)),
              _buildBurnItem('Burn Rate Médio', '${_currencyFormat.format(burnRate)}/mês'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBurnItem(String label, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
        const SizedBox(height: 2),
        Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
