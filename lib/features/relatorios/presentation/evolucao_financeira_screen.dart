import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/relatorios_provider.dart';
import '../../obras/providers/obras_provider.dart';
import '../../../shared/utils/whatsapp_helper.dart';
import 'package:intl/intl.dart';

class EvolucaoFinanceiraScreen extends ConsumerStatefulWidget {
  const EvolucaoFinanceiraScreen({super.key});

  @override
  ConsumerState<EvolucaoFinanceiraScreen> createState() => _EvolucaoFinanceiraScreenState();
}

class _EvolucaoFinanceiraScreenState extends ConsumerState<EvolucaoFinanceiraScreen> {
  String? _selectedObraId;
  String _periodo = 'MENSAL';
  int _ano = DateTime.now().year;
  int? _mes = DateTime.now().month;

  Map<String, dynamic>? _relatorioData;
  bool _isLoading = false;
  String? _error;

  Future<void> _gerarRelatorio() async {
    if (_selectedObraId == null) {
      setState(() => _error = "Selecione uma obra.");
      return;
    }
    if (_periodo == 'SEMANAL' && _mes == null) {
      setState(() => _error = "Para relatório semanal, selecione o mês.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(relatoriosProvider);
      final data = await service.getEvolucaoFinanceiraObra(
        obraId: _selectedObraId!,
        periodo: _periodo,
        ano: _ano,
        mes: _periodo == 'SEMANAL' ? _mes : _mes, // Pode ser null no MENSAL se quiser o ano todo
      );
      setState(() {
        _relatorioData = data;
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

  void _compartilharWhatsApp() {
    if (_relatorioData == null) return;
    final numFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    StringBuffer sb = StringBuffer();
    sb.writeln('*Evolução Financeira da Obra*');
    sb.writeln('Obra: ${_relatorioData!['obra']}');
    sb.writeln('Período: $_periodo ($_ano)');
    sb.writeln('--------------------------------');
    sb.writeln('Resumo do Período:');
    sb.writeln('Receitas: ${numFormat.format(_relatorioData!['resumoPeriodo']['totalReceitas'])}');
    sb.writeln('Despesas: ${numFormat.format(_relatorioData!['resumoPeriodo']['totalDespesas'])}');
    sb.writeln('Saldo Total: ${numFormat.format(_relatorioData!['resumoPeriodo']['saldo'])}');
    sb.writeln('--------------------------------');
    
    final agrupamento = _relatorioData!['agrupamento'] as Map<String, dynamic>;
    for (var entry in agrupamento.entries) {
      sb.writeln('*${entry.key}*');
      sb.writeln('Rec: ${numFormat.format(entry.value['receitas'])} | Desp: ${numFormat.format(entry.value['despesas'])}');
      sb.writeln('Saldo: ${numFormat.format(entry.value['saldo'])}');
      sb.writeln('');
    }
    
    WhatsAppHelper.shareText(sb.toString());
  }

  @override
  Widget build(BuildContext context) {
    final obrasAsync = ref.watch(obrasProvider);
    final numberFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolução Financeira da Obra'),
        actions: [
          if (_relatorioData != null)
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
                  obrasAsync.when(
                    data: (obras) => DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Selecione a Obra', border: OutlineInputBorder()),
                      value: _selectedObraId,
                      items: obras.map<DropdownMenuItem<String>>((o) => DropdownMenuItem<String>(value: o.id, child: Text(o.nome))).toList(),
                      onChanged: (val) => setState(() => _selectedObraId = val),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Erro ao carregar obras: $e'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Agrupamento', border: OutlineInputBorder()),
                          value: _periodo,
                          items: const [
                            DropdownMenuItem(value: 'MENSAL', child: Text('Mensal')),
                            DropdownMenuItem(value: 'SEMANAL', child: Text('Semanal')),
                          ],
                          onChanged: (val) => setState(() => _periodo = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Ano', border: OutlineInputBorder()),
                          initialValue: _ano.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => _ano = int.tryParse(val) ?? _ano,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(labelText: 'Mês (Obrigatório para Semanal)', border: OutlineInputBorder()),
                    value: _mes,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos os Meses (Apenas Mensal)')),
                      ...List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1}'))),
                    ],
                    onChanged: (val) => setState(() => _mes = val),
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
          if (_relatorioData != null)
            Expanded(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.green.shade50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Obra: ${_relatorioData!['obra']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Receitas: ${numberFormat.format(_relatorioData!['resumoPeriodo']['totalReceitas'])}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              Text('Total Despesas: ${numberFormat.format(_relatorioData!['resumoPeriodo']['totalDespesas'])}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Saldo do Período: ${numberFormat.format(_relatorioData!['resumoPeriodo']['saldo'])}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Período')),
                            DataColumn(label: Text('Receitas')),
                            DataColumn(label: Text('Despesas')),
                            DataColumn(label: Text('Saldo')),
                          ],
                          rows: (_relatorioData!['agrupamento'] as Map<String, dynamic>).entries.map((e) {
                            final periodoLabel = e.key;
                            final data = e.value;
                            return DataRow(cells: [
                              DataCell(Text(periodoLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(numberFormat.format(data['receitas']), style: const TextStyle(color: Colors.green))),
                              DataCell(Text(numberFormat.format(data['despesas']), style: const TextStyle(color: Colors.red))),
                              DataCell(Text(numberFormat.format(data['saldo']), style: const TextStyle(fontWeight: FontWeight.bold))),
                            ]);
                          }).toList(),
                        ),
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
