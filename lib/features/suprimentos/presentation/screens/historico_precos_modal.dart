import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/providers/api_client_provider.dart';

class HistoricoPrecosModal extends ConsumerStatefulWidget {
  final String produtoId;
  final String produtoNome;

  const HistoricoPrecosModal({
    super.key,
    required this.produtoId,
    required this.produtoNome,
  });

  static void show(BuildContext context, String produtoId, String produtoNome) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: HistoricoPrecosModal(
            produtoId: produtoId,
            produtoNome: produtoNome,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<HistoricoPrecosModal> createState() => _HistoricoPrecosModalState();
}

class _HistoricoPrecosModalState extends ConsumerState<HistoricoPrecosModal> {
  bool _isLoading = true;
  Map<String, dynamic>? _dados;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/suprimentos/produtos/${widget.produtoId}/historico-precos');
      setState(() {
        _dados = res['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatMoeda(dynamic valor) {
    final v = double.tryParse(valor?.toString() ?? '0') ?? 0.0;
    return 'R\$ ${v.toStringAsFixed(2)}';
  }

  String _formatData(dynamic rawDate) {
    if (rawDate == null) return '-';
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return rawDate.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra superior de arrasto e fechar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.indigo, size: 26),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.produtoNome,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Inteligência de Preços & Comparativo',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _erro != null
                  ? Center(child: Text('Erro ao carregar dados: $_erro'))
                  : _buildConteudo(),
        ),
      ],
    );
  }

  Widget _buildConteudo() {
    final metricas = _dados?['metricas'] ?? {};
    final produto = _dados?['produto'] ?? {};
    final List<dynamic> fornecedores = _dados?['comparativoFornecedores'] ?? [];
    final List<dynamic> historico = _dados?['historico'] ?? [];
    final List<dynamic> orcados = _dados?['orcadoProposta'] ?? [];

    final alertaSobrepreco = metricas['alertaSobrepreco'] == true;
    final precoMedio = metricas['precoMedioPonderado'] ?? 0;
    final menorPreco = metricas['menorPreco'] ?? 0;
    final maiorPreco = metricas['maiorPreco'] ?? 0;
    final ultimoPreco = metricas['ultimoPreco'] ?? 0;
    final variacaoMedia = double.tryParse(metricas['variacaoSobreMedia']?.toString() ?? '0') ?? 0;
    final precoBase = produto['precoBase'] ?? 0;
    final un = produto['unidadeMedida'] ?? 'UN';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Alerta de Sobrepreço se detectado
        if (alertaSobrepreco)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alerta de Sobrepreço Detectado!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      Text(
                        'O último preço pago (${_formatMoeda(ultimoPreco)}) está ${variacaoMedia.abs().toStringAsFixed(1)}% acima da média histórica ponderada (${_formatMoeda(precoMedio)}).',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Grid com Indicadores Principais
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                titulo: 'Custo Médio',
                valor: '${_formatMoeda(precoMedio)} / $un',
                icone: Icons.balance,
                cor: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                titulo: 'Último Pago',
                valor: '${_formatMoeda(ultimoPreco)} / $un',
                icone: Icons.shopping_bag,
                cor: variacaoMedia > 5 ? Colors.red : Colors.green,
                subtitulo: '${variacaoMedia >= 0 ? '+' : ''}${variacaoMedia.toStringAsFixed(1)}% vs média',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                titulo: 'Menor Preço',
                valor: _formatMoeda(menorPreco),
                icone: Icons.arrow_downward,
                cor: Colors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                titulo: 'Preço Base Cadastrado',
                valor: _formatMoeda(precoBase),
                icone: Icons.price_check,
                cor: Colors.indigo,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                titulo: 'Maior Preço',
                valor: _formatMoeda(maiorPreco),
                icone: Icons.arrow_upward,
                cor: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Seção: Comparativo por Fornecedor (Melhor Compra)
        const Text(
          'Comparativo de Fornecedores',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (fornecedores.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Nenhuma compra registrada para comparar fornecedores.', style: TextStyle(color: Colors.grey)),
          )
        else
          ...fornecedores.asMap().entries.map((entry) {
            final idx = entry.key;
            final f = entry.value;
            final isMelhor = idx == 0; // Ordenado do menor preço médio para o maior

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: isMelhor ? const BorderSide(color: Colors.green, width: 1.5) : BorderSide.none,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isMelhor ? Colors.green.shade100 : Colors.grey.shade100,
                  child: Icon(
                    isMelhor ? Icons.star : Icons.store,
                    color: isMelhor ? Colors.green.shade800 : Colors.grey.shade700,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        f['fornecedorNome'] ?? 'Sem Nome',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isMelhor)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Melhor Média', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                subtitle: Text(
                  'Média: ${_formatMoeda(f['precoMedio'])} | Menor: ${_formatMoeda(f['menorPreco'])} | Comprados: ${f['quantidadeTotal']} $un',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  'Último: ${_formatMoeda(f['ultimoPreco'])}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            );
          }),

        const SizedBox(height: 16),

        // Seção: Histórico Cronológico de Compras
        const Text(
          'Histórico de Compras Realizadas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (historico.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Nenhuma ordem de compra finalizada.', style: TextStyle(color: Colors.grey)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: historico.length,
            itemBuilder: (context, index) {
              final item = historico[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('OC #${item['ordemNumero']} - ${item['fornecedorNome']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(_formatData(item['data']), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                  subtitle: Text('Obra: ${item['obraNome']} | Qtd: ${item['quantidade']} $un'),
                  trailing: Text(
                    _formatMoeda(item['precoUnitario']),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
                  ),
                ),
              );
            },
          ),

        if (orcados.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Valores Orçados em Propostas de Obras',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...orcados.map((orc) => Card(
            margin: const EdgeInsets.only(bottom: 6),
            color: Colors.amber.shade50,
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.description, color: Colors.amber),
              title: Text('Proposta: ${orc['propostaTitulo']} (${orc['obraNome']})'),
              subtitle: Text('${orc['descricao']} - Qtd: ${orc['quantidade']}'),
              trailing: Text(
                _formatMoeda(orc['valorUnitario']),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown),
              ),
            ),
          )),
        ]
      ],
    );
  }

  Widget _buildMetricCard({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
    String? subtitulo,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: cor, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cor),
          ),
          if (subtitulo != null)
            Text(
              subtitulo,
              style: TextStyle(fontSize: 10, color: cor.withValues(alpha: 0.8)),
            ),
        ],
      ),
    );
  }
}
