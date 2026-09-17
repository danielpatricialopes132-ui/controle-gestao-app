import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/relatorios_provider.dart';

class RelatorioGerencialScreen extends ConsumerStatefulWidget {
  const RelatorioGerencialScreen({super.key});

  @override
  ConsumerState<RelatorioGerencialScreen> createState() => _RelatorioGerencialScreenState();
}

class _RelatorioGerencialScreenState extends ConsumerState<RelatorioGerencialScreen> {
  int _mes = DateTime.now().month;
  int _ano = DateTime.now().year;

  Future<Map<String, dynamic>>? _relatorioFuture;

  @override
  void initState() {
    super.initState();
    _fetchDados();
  }

  void _fetchDados() {
    _relatorioFuture = ref.read(relatoriosProvider).getRelatorioGerencial(
      mes: _mes,
      ano: _ano,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório Gerencial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {}, // Future PDF Export
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _relatorioFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                
                final data = snapshot.data;
                if (data == null) return const Center(child: Text('Nenhum dado encontrado.'));

                final resumo = data['resumo'];
                final receitas = List.from(data['receitas'] ?? []);
                final despesas = List.from(data['despesas'] ?? []);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildResumoCard(resumo),
                      const SizedBox(height: 24),
                      _buildTabelaCategoria('Receitas por Categoria', receitas, Colors.green),
                      const SizedBox(height: 24),
                      _buildTabelaCategoria('Despesas por Categoria', despesas, Colors.red),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _mes,
              decoration: const InputDecoration(labelText: 'Mês', isDense: true),
              items: List.generate(12, (i) => i + 1)
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0'))))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _mes = val);
                  _fetchDados();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _ano,
              decoration: const InputDecoration(labelText: 'Ano', isDense: true),
              items: [2024, 2025, 2026]
                  .map((a) => DropdownMenuItem(value: a, child: Text(a.toString())))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _ano = val);
                  _fetchDados();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoCard(dynamic resumo) {
    if (resumo == null) return const SizedBox.shrink();
    
    return Card(
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Faturamento', style: TextStyle(color: Colors.white70)),
                Text('R\$ ${resumo['faturamento']?.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Custos', style: TextStyle(color: Colors.white70)),
                Text('R\$ ${resumo['custos']?.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('LUCRO/PREJUÍZO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(
                  'R\$ ${resumo['lucro']?.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: (resumo['lucro'] ?? 0) >= 0 ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaCategoria(String titulo, List items, Color corItem) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...items.map((cat) {
            return ListTile(
              title: Text(cat['categoria'] ?? 'Sem Categoria'),
              trailing: Text('R\$ ${cat['valor']?.toStringAsFixed(2)}', style: TextStyle(color: corItem, fontWeight: FontWeight.bold)),
            );
          }).toList()
        ],
      ),
    );
  }
}
