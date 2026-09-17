import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/relatorios_provider.dart';

class PontoPorObraScreen extends ConsumerStatefulWidget {
  const PontoPorObraScreen({super.key});

  @override
  ConsumerState<PontoPorObraScreen> createState() => _PontoPorObraScreenState();
}

class _PontoPorObraScreenState extends ConsumerState<PontoPorObraScreen> {
  int _mes = DateTime.now().month;
  int _ano = DateTime.now().year;
  String _obraId = ''; // Idealmente selecionada num dropdown
  
  // Como simplificação, você precisará buscar as obras. Aqui assumimos uma obra digitada ou mockada se vazia,
  // mas o ideal é ter o dropdown de obras. Para o exemplo, vamos assumir que o usuário insere o ID ou escolhe

  Future<Map<String, dynamic>>? _relatorioFuture;

  @override
  void initState() {
    super.initState();
    // Você chamará _fetchDados() quando selecionar a obra
  }

  void _fetchDados(String obraId) {
    if (obraId.isEmpty) return;
    setState(() {
      _obraId = obraId;
      _relatorioFuture = ref.read(relatoriosProvider).getFrequenciaPonto(
        obraId: _obraId,
        mes: _mes,
        ano: _ano,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ponto por Obra'),
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: _obraId.isEmpty
              ? const Center(child: Text('Insira ou selecione uma obra para visualizar.'))
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
                if (data == null || data['funcionarios'] == null) {
                  return const Center(child: Text('Nenhum dado encontrado.'));
                }

                final funcionarios = List.from(data['funcionarios']);

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: funcionarios.length,
                  itemBuilder: (context, index) {
                    final f = funcionarios[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f['funcionario'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(f['cargo'] ?? 'Funcionário', style: const TextStyle(color: Colors.grey)),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Dias Trabalhados:'),
                                Text('${f['diasTrabalhados']?.toStringAsFixed(1)} dias'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Valor Bruto:'),
                                Text('R\$ ${f['valorBruto']?.toStringAsFixed(2)}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Adiantamentos (Vales):', style: TextStyle(color: Colors.red)),
                                Text('R\$ ${f['vales']?.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('LÍQUIDO A RECEBER:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('R\$ ${f['liquidoAReceber']?.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)),
                              ],
                            ),
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
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'ID da Obra (Exemplo para testes)'),
            onFieldSubmitted: (val) {
              _fetchDados(val);
            },
          ),
          const SizedBox(height: 16),
          Row(
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
                      if (_obraId.isNotEmpty) _fetchDados(_obraId);
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
                      if (_obraId.isNotEmpty) _fetchDados(_obraId);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
