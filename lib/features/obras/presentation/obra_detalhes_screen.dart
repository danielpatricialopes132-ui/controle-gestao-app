import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'adendo_modal.dart';
import '../providers/obras_detalhe_provider.dart';
import 'ged_aba.dart';
import 'cronograma_aba.dart';
import 'relatorios_obra_aba.dart';
import 'gerenciamento_terceiros_aba.dart';

class ObraDetalhesScreen extends ConsumerStatefulWidget {
  final String obraId;
  final String obraNome;

  const ObraDetalhesScreen({super.key, required this.obraId, required this.obraNome});

  @override
  ConsumerState<ObraDetalhesScreen> createState() => _ObraDetalhesScreenState();
}

class _ObraDetalhesScreenState extends ConsumerState<ObraDetalhesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.obraNome),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.indigo,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dashboard Financeiro', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Revista & Diário (RDO)', icon: Icon(Icons.auto_stories)),
            Tab(text: 'Coordenação Terceiros', icon: Icon(Icons.architecture)),
            Tab(text: 'Aditivos e Contratos', icon: Icon(Icons.assignment)),
            Tab(text: 'Documentos (GED)', icon: Icon(Icons.folder)),
            Tab(text: 'Cronograma', icon: Icon(Icons.calendar_month)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          RelatoriosObraAba(obraId: widget.obraId, obraNome: widget.obraNome),
          GerenciamentoTerceirosAba(obraId: widget.obraId, obraNome: widget.obraNome),
          _buildAditivosTab(),
          GedAba(obraId: widget.obraId),
          CronogramaAba(obraId: widget.obraId),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    final dashboardAsync = ref.watch(obraDashboardProvider(widget.obraId));

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro ao carregar dados: $err')),
      data: (data) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Resumo Financeiro (Fluxo de Caixa)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildMetricCard('Receitas Totais', data.receitasTotal, Colors.blue),
                  _buildMetricCard('Despesas Realizadas', data.despesasTotal, Colors.red),
                  _buildMetricCard('Orçamento Previsto', data.totalOrcado, Colors.orange),
                  _buildMetricCard('Resultado (Lucro/Prejuízo)', data.lucro, data.lucro >= 0 ? Colors.green : Colors.red),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Margem de Lucro: ${data.margemLucro.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 32),
                  Text('Despesas / Orçamento: ${data.percentualCustoOrcamento.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Despesas por Categoria', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildCentroCustoList(data),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, double value, Color color) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            'R\$ ${value.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCentroCustoList(DashboardData data) {
    if (data.despesasPorCategoria.isEmpty) {
      return const Text('Nenhuma despesa registrada.');
    }

    return Column(
      children: data.despesasPorCategoria.map((item) {
        return Column(
          children: [
            ListTile(
              title: Text(item['categoria']),
              trailing: Text('R\$ ${(item['valor'] as num).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAditivosTab() {
    // Para simplificar, poderíamos ter uma rota GET /api/obras/[id]/adendos ou pegar do dashboard.
    // Como os adendos não estão detalhados na resposta atual do dashboard, vamos apenas 
    // pedir ao usuário para recarregar ou exibir uma lista vazia por enquanto (Fase 3 completa terá endpoint de listagem).
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Use o botão abaixo para registrar um aditivo.'),
            Text('Os valores já são refletidos no Dashboard Financeiro!'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AdendoModal.show(context, widget.obraId),
        icon: const Icon(Icons.add),
        label: const Text('Novo Aditivo'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }
}
