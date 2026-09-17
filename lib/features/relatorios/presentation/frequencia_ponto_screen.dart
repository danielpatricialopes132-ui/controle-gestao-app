import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/relatorios_provider.dart';

class FrequenciaPontoScreen extends ConsumerStatefulWidget {
  const FrequenciaPontoScreen({super.key});

  @override
  ConsumerState<FrequenciaPontoScreen> createState() => _FrequenciaPontoScreenState();
}

class _FrequenciaPontoScreenState extends ConsumerState<FrequenciaPontoScreen> {
  int _mes = DateTime.now().month;
  int _ano = DateTime.now().year;
  String _obraId = ''; // Opcional

  Future<Map<String, dynamic>>? _relatorioFuture;

  @override
  void initState() {
    super.initState();
    _fetchDados();
  }

  void _fetchDados() {
    setState(() {
      _relatorioFuture = ref.read(relatoriosProvider).getFrequenciaPonto(
        obraId: _obraId.isNotEmpty ? _obraId : null,
        mes: _mes,
        ano: _ano,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequência de Ponto'),
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
                if (data == null || data['funcionarios'] == null || (data['funcionarios'] as List).isEmpty) {
                  return const Center(child: Text('Nenhum dado encontrado para o período.'));
                }

                final funcionarios = List.from(data['funcionarios']);
                
                // Pegar último dia do mês para montar a matriz de 1 a 31
                final lastDay = DateTime(_ano, _mes + 1, 0).day;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Theme.of(context).colorScheme.surfaceVariant),
                      columns: [
                        const DataColumn(label: Text('Funcionário', style: TextStyle(fontWeight: FontWeight.bold))),
                        for (int i = 1; i <= lastDay; i++)
                          DataColumn(label: Text(i.toString().padLeft(2, '0'))),
                        const DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: funcionarios.map((f) {
                        final diasMap = f['dias'] as Map<String, dynamic>? ?? {};
                        final total = f['totalDiasTrabalhados'] ?? 0;
                        
                        return DataRow(
                          cells: [
                            DataCell(Text(f['nome'] ?? 'Sem Nome')),
                            for (int i = 1; i <= lastDay; i++)
                              DataCell(
                                Text(
                                  diasMap[i.toString()] ?? '-',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getColorForStatus(diasMap[i.toString()]),
                                  ),
                                ),
                              ),
                            DataCell(Text(total.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Color _getColorForStatus(String? sigla) {
    if (sigla == 'T') return Colors.green;
    if (sigla == 'V') return Colors.blue;
    if (sigla == 'CH') return Colors.orange;
    if (sigla == '-') return Colors.red;
    return Colors.grey;
  }

  Widget _buildFiltros() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'ID da Obra (Opcional - deixe vazio para todas)',
                prefixIcon: Icon(Icons.business),
              ),
              onFieldSubmitted: (val) {
                _obraId = val;
                _fetchDados();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _mes,
                    decoration: const InputDecoration(labelText: 'Mês', isDense: true, prefixIcon: Icon(Icons.calendar_month)),
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
          ],
        ),
      ),
    );
  }
}
