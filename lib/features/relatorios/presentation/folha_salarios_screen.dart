import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/relatorios_provider.dart';

class FolhaSalariosScreen extends ConsumerStatefulWidget {
  const FolhaSalariosScreen({super.key});

  @override
  ConsumerState<FolhaSalariosScreen> createState() => _FolhaSalariosScreenState();
}

class _FolhaSalariosScreenState extends ConsumerState<FolhaSalariosScreen> {
  int _mes = DateTime.now().month;
  int _ano = DateTime.now().year;

  Future<Map<String, dynamic>>? _relatorioFuture;

  @override
  void initState() {
    super.initState();
    _fetchDados();
  }

  void _fetchDados() {
    _relatorioFuture = ref.read(relatoriosProvider).getFolhaDeSalarios(
      mes: _mes,
      ano: _ano,
    );
  }

  Future<void> _compartilharWhatsApp() async {
    final data = await _relatorioFuture;
    if (data == null) return;
    final folha = List.from(data['detalhamento'] ?? []);
    
    final StringBuffer sb = StringBuffer();
    sb.writeln('*FOLHA DE SALÁRIOS - ${_mes.toString().padLeft(2, '0')}/$_ano*');
    sb.writeln('====================');
    for (var f in folha) {
      sb.writeln('Func: ${f['nome']}');
      sb.writeln('Líquido: R\$ ${f['liquidoAReceber']?.toStringAsFixed(2)}');
      sb.writeln('--------------------');
    }
    sb.writeln('Total: R\$ ${data['resumoGeral']?['totalLiquido']?.toStringAsFixed(2)}');

    final url = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(sb.toString())}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp não instalado.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folha de Salários'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            color: Colors.green,
            onPressed: _compartilharWhatsApp,
          )
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

                final resumoGeral = data['resumoGeral'];
                final detalhamento = List.from(data['detalhamento'] ?? []);

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildResumoGeralCard(resumoGeral),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final func = detalhamento[index];
                            return _buildFuncionarioCard(func);
                          },
                          childCount: detalhamento.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
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

  Widget _buildResumoGeralCard(dynamic resumo) {
    if (resumo == null) return const SizedBox.shrink();
    
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('TOTAL DA FOLHA', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'R\$ ${resumo['totalLiquido']?.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bruto: R\$ ${resumo['totalBruto']?.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                Text('Vales: R\$ ${resumo['totalVales']?.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFuncionarioCard(dynamic func) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(func['nome'] ?? 'Desconhecido', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(func['cargo'] ?? 'Sem cargo'),
        trailing: Text(
          'R\$ ${func['liquidoAReceber']?.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Dias Trabalhados (Total):'),
                    Text('${func['diasTrabalhados']?.toStringAsFixed(1)} dias'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Valor Bruto:'),
                    Text('R\$ ${func['valorBruto']?.toStringAsFixed(2)}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Vales / Adiantamentos:', style: TextStyle(color: Colors.red)),
                    Text('- R\$ ${func['totalVales']?.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
