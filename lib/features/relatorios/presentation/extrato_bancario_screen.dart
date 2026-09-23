import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../shared/utils/export_utils.dart';

class ExtratoBancarioScreen extends ConsumerStatefulWidget {
  const ExtratoBancarioScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ExtratoBancarioScreen> createState() => _ExtratoBancarioScreenState();
}

class _ExtratoBancarioScreenState extends ConsumerState<ExtratoBancarioScreen> {
  String _contaSelecionada = 'todas';
  DateTime _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _dataFim = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  final _formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _formatDate = DateFormat('dd/MM/yyyy');

  Map<String, String> _getParams() {
    return {
      'contaBancariaId': _contaSelecionada,
      'dataInicio': _dataInicio.toIso8601String(),
      'dataFim': _dataFim.toIso8601String(),
    };
  }

  Future<void> _selecionarData(BuildContext context, bool isInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInicio ? _dataInicio : _dataFim,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = picked;
        } else {
          _dataFim = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final extratoAsync = ref.watch(extratoProvider(_getParams()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extrato Bancário e Fluxo de Caixa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () {
              final dataAsync = ref.read(extratoProvider(_getParams()));
              dataAsync.whenData((data) {
                final transacoes = data['transacoes'] as List;
                ExportUtils.exportTableToPdf(
                  title: 'Extrato Bancário',
                  fileName: 'extrato_bancario',
                  headers: ['Data', 'Conta', 'Categoria', 'Descrição', 'Valor', 'Saldo'],
                  data: transacoes.map((t) => [
                    _formatDate.format(DateTime.parse(t['data'])),
                    t['conta'].toString(),
                    t['categoria'].toString(),
                    t['descricao'].toString(),
                    (t['tipo'] == 'RECEITA' ? '+ ' : '- ') + _formatCurrency.format(t['valor']),
                    _formatCurrency.format(t['saldoProgressivo']),
                  ]).toList(),
                );
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar CSV',
            onPressed: () {
              final dataAsync = ref.read(extratoProvider(_getParams()));
              dataAsync.whenData((data) {
                final transacoes = data['transacoes'] as List;
                
                final rows = <List<dynamic>>[];
                rows.add(['Data', 'Conta', 'Categoria', 'Descrição', 'Tipo', 'Valor', 'Saldo Progressivo']);
                
                for (var t in transacoes) {
                  rows.add([
                    _formatDate.format(DateTime.parse(t['data'])),
                    t['conta'],
                    t['categoria'],
                    t['descricao'],
                    t['tipo'],
                    t['valor'],
                    t['saldoProgressivo']
                  ]);
                }
                
                ExportUtils.exportToCsv(
                  fileName: 'extrato_bancario',
                  rows: rows,
                );
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filtros
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // TODO: Carregar lista de contas do backend para o Dropdown
                    DropdownButton<String>(
                      value: _contaSelecionada,
                      items: const [
                        DropdownMenuItem(value: 'todas', child: Text('Todas as Contas (Global)')),
                        // DropdownMenuItem(value: 'id', child: Text('Nome Conta')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _contaSelecionada = val);
                      },
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Início: ${_formatDate.format(_dataInicio)}'),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selecionarData(context, true),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Fim: ${_formatDate.format(_dataFim)}'),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selecionarData(context, false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Tabela
            Expanded(
              child: extratoAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Erro: $err')),
                data: (data) {
                  final transacoes = data['transacoes'] as List;
                  final saldoAbertura = (data['saldoAberturaPeriodo'] ?? 0).toDouble();
                  final saldoFinal = (data['saldoFinalPeriodo'] ?? 0).toDouble();

                  return Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Saldo de Abertura do Período', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Text(
                            _formatCurrency.format(saldoAbertura),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: saldoAbertura >= 0 ? Colors.green : Colors.red),
                          ),
                          tileColor: Colors.grey.shade100,
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.separated(
                            itemCount: transacoes.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final t = transacoes[index];
                              final dt = DateTime.parse(t['data']);
                              final isReceita = t['tipo'] == 'RECEITA';
                              final val = (t['valor'] ?? 0).toDouble();
                              final saldoProg = (t['saldoProgressivo'] ?? 0).toDouble();

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isReceita ? Colors.green.shade100 : Colors.red.shade100,
                                  child: Icon(
                                    isReceita ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: isReceita ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(t['descricao'] ?? 'Sem descrição'),
                                subtitle: Text('${_formatDate.format(dt)} - ${t['categoria']} (${t['conta']})'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      isReceita ? '+ ${_formatCurrency.format(val)}' : '- ${_formatCurrency.format(val)}',
                                      style: TextStyle(color: isReceita ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Saldo: ${_formatCurrency.format(saldoProg)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Saldo Final do Período', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Text(
                            _formatCurrency.format(saldoFinal),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: saldoFinal >= 0 ? Colors.green : Colors.red),
                          ),
                          tileColor: Colors.grey.shade100,
                        ),
                      ],
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
}
