import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/relatorios_provider.dart';

class GerencialObraScreen extends ConsumerStatefulWidget {
  const GerencialObraScreen({super.key});

  @override
  ConsumerState<GerencialObraScreen> createState() => _GerencialObraScreenState();
}

class _GerencialObraScreenState extends ConsumerState<GerencialObraScreen> {
  String _obraId = ''; // O usuário deve preencher o id da obra

  Future<Map<String, dynamic>>? _relatorioFuture;

  void _fetchDados() {
    if (_obraId.isEmpty) return;
    setState(() {
      _relatorioFuture = ref.read(relatoriosProvider).getGerencialObra(_obraId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DRE Gerencial da Obra'),
      ),
      body: Column(
        children: [
          _buildFiltro(),
          Expanded(
            child: _obraId.isEmpty
              ? const Center(child: Text('Insira o ID de uma obra para visualizar o DRE.'))
              : FutureBuilder<Map<String, dynamic>>(
                  future: _relatorioFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }
                    
                    final data = snapshot.data;
                    if (data == null || data['resumo'] == null) {
                      return const Center(child: Text('Nenhum dado encontrado ou erro na resposta.'));
                    }

                    final resumo = data['resumo'];
                    final entradas = List.from(data['entradas'] ?? []);
                    final saidas = data['saidas'] ?? {};
                    final folha = List.from(saidas['folhaPagamento'] ?? []);
                    final outrasDespesas = saidas['outrasDespesas'] ?? 0;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildResumoCards(resumo),
                        const SizedBox(height: 24),
                        
                        // Entradas
                        const Text('RECEITAS (Entradas)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        const Divider(),
                        ...entradas.map((e) => _buildLinhaDRE(
                          e['descricao'], 
                          previsto: e['previsto'], 
                          realizado: e['realizado']
                        )).toList(),
                        const SizedBox(height: 24),

                        // Saidas
                        const Text('CUSTOS E DESPESAS (Saídas)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                        const Divider(),
                        const Text('Folha de Pagamento', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...folha.map((f) => _buildLinhaDRE(
                          ' - ${f['nome']}',
                          realizado: f['valor']
                        )).toList(),
                        _buildLinhaDRE('Outras Despesas (Materiais/Fornecedores)', realizado: outrasDespesas),
                      ],
                    );
                  },
                ),
          )
        ],
      ),
    );
  }

  Widget _buildResumoCards(Map<String, dynamic> resumo) {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            'Faturamento',
            resumo['totalEntradasRealizado'],
            Colors.green,
            subtitle: 'Previsto: R\$ ${((resumo['totalEntradasPrevisto'] as num?) ?? 0).toStringAsFixed(2)}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCard('Custos Totais', resumo['totalSaidasRealizado'], Colors.red),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCard(
            'Lucro Caixa',
            resumo['lucroCaixa'],
            (resumo['lucroCaixa'] ?? 0) >= 0 ? Colors.blue : Colors.orange,
            subtitle: 'Margem: ${((resumo['margem'] as num?) ?? 0).toStringAsFixed(1)}%',
          ),
        ),
      ],
    );
  }

  Widget _buildCard(String title, dynamic value, Color color, {String? subtitle}) {
    final v = (value as num?)?.toDouble() ?? 0.0;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              'R\$ ${v.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaDRE(String label, {dynamic previsto, dynamic realizado}) {
    final p = (previsto as num?)?.toDouble();
    final r = (realizado as num?)?.toDouble() ?? 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          if (p != null) 
            Text('Prev: R\$ ${p.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          if (p != null) const SizedBox(width: 16),
          Text('R\$ ${r.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFiltro() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          decoration: const InputDecoration(
            labelText: 'ID da Obra',
            prefixIcon: Icon(Icons.business),
            hintText: 'Cole o ID da obra aqui e aperte Enter',
          ),
          onFieldSubmitted: (val) {
            _obraId = val;
            _fetchDados();
          },
        ),
      ),
    );
  }
}
