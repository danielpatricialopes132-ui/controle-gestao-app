import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../../../auth/providers/tenant_provider.dart';
import 'package:intl/intl.dart';

class CronogramaGanttScreen extends ConsumerStatefulWidget {
  final String obraId;
  const CronogramaGanttScreen({super.key, required this.obraId});

  @override
  ConsumerState<CronogramaGanttScreen> createState() => _CronogramaGanttScreenState();
}

class _CronogramaGanttScreenState extends ConsumerState<CronogramaGanttScreen> {
  bool _isLoading = true;
  List<dynamic> _etapas = [];
  Map<String, dynamic> _resumo = {};

  @override
  void initState() {
    super.initState();
    _loadCronograma();
  }

  Future<void> _loadCronograma() async {
    setState(() => _isLoading = true);
    try {
      final tenantId = ref.read(tenantOverrideProvider);
      final api = ref.read(apiClientProvider);
      
      final res = await api.get('/obras/${widget.obraId}/cronograma?tenantId=$tenantId');
      
      if (res['success'] == true) {
        setState(() {
          _etapas = res['data']['etapas'] ?? [];
          _resumo = res['data']['resumo'] ?? {};
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar cronograma: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final num totalPrevisto = _resumo['totalPrevisto'] ?? 0;
    final num totalRealizado = _resumo['totalRealizadoFisico'] ?? 0;
    final num percentualGeral = _resumo['percentualGeral'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gantt e Curva S (Físico-Financeiro)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildIndicador('Custo Previsto (Total)', currency.format(totalPrevisto), Colors.blue),
                    _buildIndicador('Avanço Físico (Acumulado)', currency.format(totalRealizado), Colors.green),
                    _buildIndicador('% Conclusão Geral', '${percentualGeral.toStringAsFixed(1)}%', Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Etapas do Cronograma (Gantt Simplificado)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: _etapas.isEmpty
                  ? const Center(child: Text('Nenhuma etapa cadastrada no cronograma.'))
                  : ListView.builder(
                      itemCount: _etapas.length,
                      itemBuilder: (context, index) {
                        final etapa = _etapas[index];
                        final num p = etapa['percentualConclusao'] ?? 0;
                        final dtIni = DateTime.parse(etapa['dataInicioEstimada']);
                        final dtFim = DateTime.parse(etapa['dataFimEstimada']);
                        final format = DateFormat('dd/MM/yyyy');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircularProgressIndicator(
                              value: p / 100,
                              backgroundColor: Colors.grey.shade300,
                              color: p == 100 ? Colors.green : Colors.blue,
                            ),
                            title: Text(etapa['nome'] ?? 'Etapa', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Início: ${format.format(dtIni)} | Término: ${format.format(dtFim)}\nCusto: ${currency.format(etapa['custoPrevisto'])}'),
                            trailing: Text('${p.toStringAsFixed(0)}%', style: TextStyle(fontSize: 18, color: p == 100 ? Colors.green : Colors.black87)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicador(String titulo, String valor, Color cor) {
    return Column(
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 8),
        Text(valor, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: cor)),
      ],
    );
  }
}
