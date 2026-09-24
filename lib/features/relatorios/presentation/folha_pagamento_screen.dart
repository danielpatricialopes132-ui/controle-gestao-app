import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/relatorios_provider.dart';

class FolhaPagamentoScreen extends ConsumerStatefulWidget {
  const FolhaPagamentoScreen({super.key});

  @override
  ConsumerState<FolhaPagamentoScreen> createState() => _FolhaPagamentoScreenState();
}

class _FolhaPagamentoScreenState extends ConsumerState<FolhaPagamentoScreen> {
  DateTime _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _dataFim = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  Future<Map<String, dynamic>>? _relatorioFuture;
  List<dynamic> _funcionarios = [];
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _fetchDados();
  }

  void _fetchDados() {
    setState(() {
      _relatorioFuture = ref.read(relatoriosProvider).getFolhaPagamento(
        dataInicio: _dataInicio,
        dataFim: _dataFim,
      ).then((val) {
        _funcionarios = List.from(val['funcionarios'] ?? []);
        return val;
      });
    });
  }
  
  Future<void> _pagarSaldoRestante() async {
    final apagar = _funcionarios.where((f) => (f['saldo'] ?? 0) > 0).toList();
    
    if (apagar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum saldo pendente para pagar.'))
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Pagamento'),
        content: Text('Deseja gerar pagamento para ${apagar.length} funcionário(s)?\nIsso criará lançamentos de DESPESA no financeiro.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      )
    );

    if (confirm != true) return;

    setState(() => _isPaying = true);

    try {
      final pagamentos = apagar.map((f) => {
        'funcionarioId': f['id'],
        'valor': f['saldo'],
        'descricao': 'Salário ref. ${f['nome']}',
      }).toList();

      await ref.read(relatoriosProvider).pagarFolha(pagamentos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pagamentos gerados com sucesso!'))
        );
        _fetchDados();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao pagar: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folha de Pagamentos'),
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
                
                if (_funcionarios.isEmpty) {
                  return const Center(child: Text('Nenhum dado encontrado para o período.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _funcionarios.length,
                  itemBuilder: (context, index) {
                    final f = _funcionarios[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(f['nome'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                Chip(
                                  label: Text(f['tipoPagamento'] ?? 'MENSAL'),
                                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                )
                              ],
                            ),
                            Text(f['cargo'] ?? 'Funcionário', style: const TextStyle(color: Colors.grey)),
                            const Divider(),
                            _buildLinha('Ganhos por Ponto / Salário', f['ganhosPonto']),
                            _buildLinha('Ganhos de Viagem', f['ganhosViagem']),
                            _buildLinha('Bônus', f['bonus']),
                            const Divider(),
                            _buildLinha('Total a Receber', f['totalReceber'], bold: true),
                            _buildLinha('Vales/Adiantamentos', f['vales'], isDeducao: true),
                            _buildLinha('Já Pago no Caixa', f['jaPago'], isDeducao: true),
                            const Divider(),
                            _buildLinha('Saldo a Pagar', f['saldo'], bold: true, color: (f['saldo'] ?? 0) > 0 ? Colors.green : Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: _funcionarios.any((f) => (f['saldo'] ?? 0) > 0)
        ? FloatingActionButton.extended(heroTag: null, 
            onPressed: _isPaying ? null : _pagarSaldoRestante,
            icon: _isPaying ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.payment),
            label: Text(_isPaying ? 'Processando...' : 'Pagar Saldo Restante'),
          )
        : null,
    );
  }

  Widget _buildLinha(String label, dynamic value, {bool bold = false, bool isDeducao = false, Color? color}) {
    final v = (value as num?)?.toDouble() ?? 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '${isDeducao ? '- ' : ''}R\$ ${v.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isDeducao ? Colors.red : null),
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Data Inicial', isDense: true),
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _dataInicio, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (d != null) {
                      setState(() => _dataInicio = d);
                      _fetchDados();
                    }
                  },
                  child: Text('${_dataInicio.day}/${_dataInicio.month}/${_dataInicio.year}'),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Data Final', isDense: true),
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _dataFim, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (d != null) {
                      setState(() => _dataFim = d);
                      _fetchDados();
                    }
                  },
                  child: Text('${_dataFim.day}/${_dataFim.month}/${_dataFim.year}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
