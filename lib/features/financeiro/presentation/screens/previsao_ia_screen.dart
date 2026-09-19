import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/financeiro_provider.dart';

class PrevisaoIaScreen extends ConsumerStatefulWidget {
  const PrevisaoIaScreen({super.key});

  @override
  ConsumerState<PrevisaoIaScreen> createState() => _PrevisaoIaScreenState();
}

class _PrevisaoIaScreenState extends ConsumerState<PrevisaoIaScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _previsaoData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _gerarPrevisao();
  }

  Future<void> _gerarPrevisao() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ref.read(financeiroControllerProvider.notifier).gerarPrevisaoIa();
      setState(() {
        _previsaoData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previsão de Caixa (IA)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _gerarPrevisao,
            tooltip: 'Atualizar Previsão',
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('A Inteligência Artificial está analisando seu histórico...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Erro ao gerar previsão: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _gerarPrevisao,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_previsaoData == null) {
      return const SizedBox.shrink();
    }

    final analiseGeral = _previsaoData!['analiseGeral'] as String? ?? '';
    final gargalos = List<String>.from(_previsaoData!['gargalos'] ?? []);
    final meses = List<Map<String, dynamic>>.from(_previsaoData!['meses'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Análise do CFO Virtual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(analiseGeral, style: const TextStyle(fontSize: 16, height: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          if (gargalos.isNotEmpty) ...[
            const Text('Gargalos e Riscos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...gargalos.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(g, style: const TextStyle(fontSize: 15))),
                ],
              ),
            )),
            const SizedBox(height: 24),
          ],

          const Text('Projeção Mensal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meses.length,
            itemBuilder: (ctx, idx) {
              final m = meses[idx];
              final isDeficit = m['saldoPrevisto'] < 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(m['mes'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Chip(
                            label: Text('Risco: ${m['risco']}', style: const TextStyle(color: Colors.white)),
                            backgroundColor: m['risco'] == 'Alto' ? Colors.red : (m['risco'] == 'Médio' ? Colors.orange : Colors.green),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Receitas:', style: TextStyle(color: Colors.green)),
                          Text('R\$ ${m['receitasPrevistas'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Despesas:', style: TextStyle(color: Colors.red)),
                          Text('R\$ ${m['despesasPrevistas'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Saldo do Mês:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('R\$ ${m['saldoPrevisto'].toStringAsFixed(2)}', 
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDeficit ? Colors.red : Colors.blue,
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
  }
}
