import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/relatorios_provider.dart';
import '../../obras/providers/obras_provider.dart';
import '../../../shared/utils/whatsapp_helper.dart';

class ExtratoBancarioScreen extends ConsumerStatefulWidget {
  const ExtratoBancarioScreen({super.key});

  @override
  ConsumerState<ExtratoBancarioScreen> createState() => _ExtratoBancarioScreenState();
}

class _ExtratoBancarioScreenState extends ConsumerState<ExtratoBancarioScreen> {
  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dataFim = DateTime.now();
  String? _selectedObraId;

  Map<String, dynamic>? _extratoData;
  bool _isLoading = false;
  String? _error;

  Future<void> _gerarRelatorio() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(relatoriosProvider);
      final data = await service.getExtratoBancario(
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        obraId: _selectedObraId,
      );
      setState(() {
        _extratoData = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInicio ? _dataInicio : _dataFim,
      firstDate: DateTime(2000),
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

  void _compartilharWhatsApp() {
    if (_extratoData == null) return;
    final numFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    StringBuffer sb = StringBuffer();
    sb.writeln('*Relatório de Extrato Bancário*');
    sb.writeln('Período: ${dateFormat.format(_dataInicio)} a ${dateFormat.format(_dataFim)}');
    sb.writeln('Saldo Inicial: ${numFormat.format(_extratoData!['saldoInicial'])}');
    sb.writeln('--------------------------------');
    for (var t in _extratoData!['transacoes']) {
      final tipo = t['tipo'] == 'RECEITA' ? '🟢' : '🔴';
      sb.writeln('$tipo ${dateFormat.format(DateTime.parse(t['data']))} - ${t['descricao']}');
      sb.writeln('   Valor: ${numFormat.format(t['valor'])} | Saldo: ${numFormat.format(t['saldoAcumulado'])}');
    }
    sb.writeln('--------------------------------');
    sb.writeln('*Saldo Final: ${numFormat.format(_extratoData!['saldoFinal'])}*');
    
    WhatsAppHelper.shareText(sb.toString());
  }

  @override
  Widget build(BuildContext context) {
    final obrasAsync = ref.watch(obrasProvider);
    final numberFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extrato Bancário'),
        actions: [
          if (_extratoData != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              tooltip: 'Compartilhar no WhatsApp',
              onPressed: _compartilharWhatsApp,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Data Início', border: OutlineInputBorder()),
                            child: Text(dateFormat.format(_dataInicio)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Data Fim', border: OutlineInputBorder()),
                            child: Text(dateFormat.format(_dataFim)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  obrasAsync.when(
                    data: (obras) => DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Filtrar por Obra (Opcional)', border: OutlineInputBorder()),
                      value: _selectedObraId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todas as Obras / Geral')),
                        ...obras.map((o) => DropdownMenuItem(value: o.id, child: Text(o.nome))),
                      ],
                      onChanged: (val) => setState(() => _selectedObraId = val),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Erro ao carregar obras: $e'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _gerarRelatorio,
                      child: _isLoading ? const CircularProgressIndicator() : const Text('Gerar Relatório'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),

          // Tabela de Resultados
          if (_extratoData != null)
            Expanded(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blueGrey.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Saldo Inicial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(numberFormat.format(_extratoData!['saldoInicial']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Data')),
                              DataColumn(label: Text('Descrição')),
                              DataColumn(label: Text('Obra')),
                              DataColumn(label: Text('Valor')),
                              DataColumn(label: Text('Saldo Atual')),
                            ],
                            rows: (_extratoData!['transacoes'] as List).map((t) {
                              final isReceita = t['tipo'] == 'RECEITA';
                              return DataRow(cells: [
                                DataCell(Text(dateFormat.format(DateTime.parse(t['data'])))),
                                DataCell(Text(t['descricao'])),
                                DataCell(Text(t['obra'] ?? '-')),
                                DataCell(Text(
                                  numberFormat.format(t['valor']),
                                  style: TextStyle(color: isReceita ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                )),
                                DataCell(Text(numberFormat.format(t['saldoAcumulado']))),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blueGrey.shade100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Saldo Final do Período', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(numberFormat.format(_extratoData!['saldoFinal']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
