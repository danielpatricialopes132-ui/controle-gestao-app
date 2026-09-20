import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/empreiteiros_provider.dart';
import '../providers/suprimentos_provider.dart';
import '../../../obras/providers/obras_provider.dart';

class ContratosEmpreiteiroScreen extends ConsumerStatefulWidget {
  final String? initialObraId;
  final String? initialFornecedorId;

  const ContratosEmpreiteiroScreen({
    super.key,
    this.initialObraId,
    this.initialFornecedorId,
  });

  @override
  ConsumerState<ContratosEmpreiteiroScreen> createState() => _ContratosEmpreiteiroScreenState();
}

class _ContratosEmpreiteiroScreenState extends ConsumerState<ContratosEmpreiteiroScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final dateFormat = DateFormat('dd/MM/yyyy');

  String? _filtroObraId;
  String? _filtroStatus;

  @override
  void initState() {
    super.initState();
    _filtroObraId = widget.initialObraId;
    Future.microtask(() {
      ref.read(contratosEmpreiteiroProvider.notifier).fetchContratos(
        obraId: widget.initialObraId,
        fornecedorId: widget.initialFornecedorId,
      );
      ref.read(suprimentosProvider.notifier).fetchFornecedores();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contratosEmpreiteiroProvider);
    final obrasAsync = ref.watch(obrasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contratos de Empreiteiros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(contratosEmpreiteiroProvider.notifier).fetchContratos(
                obraId: _filtroObraId,
                fornecedorId: widget.initialFornecedorId,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Regras de Retenção e Subcontratação',
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(obrasAsync),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text('Erro ao carregar contratos: ${state.error}'))
                    : state.contratos.isEmpty
                        ? _buildEmptyState()
                        : _buildContratosList(state.contratos),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNovoContratoModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo Contrato'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterBar(AsyncValue<List<dynamic>> obrasAsync) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: obrasAsync.when(
              data: (obras) => DropdownButtonFormField<String?>(
                value: _filtroObraId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por Obra',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas as Obras')),
                  ...obras.map((o) => DropdownMenuItem(
                        value: o['id'] as String,
                        child: Text(o['nome'] ?? 'Sem nome', overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (val) {
                  setState(() => _filtroObraId = val);
                  ref.read(contratosEmpreiteiroProvider.notifier).fetchContratos(
                    obraId: val,
                    fornecedorId: widget.initialFornecedorId,
                  );
                },
              ),
              loading: () => const SizedBox(height: 20, child: LinearProgressIndicator()),
              error: (_, _) => const Text('Erro ao carregar obras'),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String?>(
            value: _filtroStatus,
            hint: const Text('Status'),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'ATIVO', child: Text('Ativo')),
              DropdownMenuItem(value: 'CONCLUIDO', child: Text('Concluído')),
              DropdownMenuItem(value: 'SUSPENSO', child: Text('Suspenso')),
            ],
            onChanged: (val) {
              setState(() => _filtroStatus = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.engineering_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Nenhum contrato de empreiteiro encontrado.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          const Text('Cadastre contratos iniciais, registre adendos e acompanhe as medições.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showNovoContratoModal(context),
            icon: const Icon(Icons.add),
            label: const Text('Cadastrar Primeiro Contrato'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContratosList(List<dynamic> contratos) {
    final filtrados = _filtroStatus == null
        ? contratos
        : contratos.where((c) => c['status'] == _filtroStatus).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final c = filtrados[index];
        return _buildContratoCard(c);
      },
    );
  }

  Widget _buildContratoCard(Map<String, dynamic> c) {
    final valorTotal = (c['valorTotalAtualizado'] as num?)?.toDouble() ?? 0.0;
    final totalMedido = (c['totalMedido'] as num?)?.toDouble() ?? 0.0;
    final saldo = (c['saldoAExecutar'] as num?)?.toDouble() ?? 0.0;
    final percentual = (c['percentualExecutado'] as num?)?.toDouble() ?? 0.0;
    final adendos = (c['adendos'] as List<dynamic>?) ?? [];
    final medicoes = (c['medicoes'] as List<dynamic>?) ?? [];
    final fornecedor = c['fornecedor'] ?? {};
    final subcontratados = (fornecedor['subcontratados'] as List<dynamic>?) ?? [];
    final ehSub = fornecedor['empreiteiroPai'] != null;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: c['status'] == 'ATIVO' ? Colors.green.shade100 : Colors.grey.shade200,
          child: Icon(
            Icons.handshake,
            color: c['status'] == 'ATIVO' ? Colors.green.shade800 : Colors.grey.shade700,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Contrato #${c['numeroContrato'] ?? 'S/N'} - ${fornecedor['nomeRazao'] ?? fornecedor['nome'] ?? 'Empreiteiro'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            _buildStatusChip(c['status']),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Objeto: ${c['objeto'] ?? 'Serviço de Empreitada'}',
                maxLines: 2, overflow: TextOverflow.ellipsis),
            if (c['obra'] != null)
              Text('Obra: ${c['obra']['nome']}', style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13)),
            if (ehSub)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right, size: 14, color: Colors.purple),
                    const SizedBox(width: 4),
                    Text(
                      'Subcontratado de: ${fornecedor['empreiteiroPai']['nomeRazao'] ?? fornecedor['empreiteiroPai']['nome']}',
                      style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            if (subcontratados.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Possui ${subcontratados.length} subcontratado(s) vinculado(s)',
                  style: const TextStyle(color: Colors.teal, fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: valorTotal > 0 ? (percentual / 100).clamp(0.0, 1.0) : 0,
              backgroundColor: Colors.grey.shade200,
              color: percentual > 90 ? Colors.orange : Colors.indigo,
              minHeight: 6,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Executado: ${percentual.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('Saldo: ${currencyFormat.format(saldo)}', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Painel de Métricas Financeiras
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricColumn('Valor Original', currencyFormat.format(c['valorOriginal'] ?? 0)),
                      _buildMetricColumn('Aditivos', '+ ${currencyFormat.format(valorTotal - ((c['valorOriginal'] as num?)?.toDouble() ?? 0.0))}'),
                      _buildMetricColumn('Total Atualizado', currencyFormat.format(valorTotal), isBold: true),
                      _buildMetricColumn('Total Medido', currencyFormat.format(totalMedido), color: Colors.green.shade800),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Chip(
                      label: Text('INSS: ${c['retencaoInss'] ?? 11}%'),
                      backgroundColor: Colors.grey.shade100,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('ISS: ${c['retencaoIss'] ?? 5}%'),
                      backgroundColor: Colors.grey.shade100,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('IRRF: ${c['retencaoIrrf'] ?? 1.5}%'),
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showNovoAdendoModal(context, c['id']),
                      icon: const Icon(Icons.post_add, size: 18),
                      label: const Text('Novo Adendo / Aditivo'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showNovaMedicaoModal(context, c),
                      icon: const Icon(Icons.rule, size: 18),
                      label: const Text('Registrar Medição'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    ),
                  ],
                ),
                const Divider(height: 32),
                // Seção de Adendos
                Text('Histórico de Adendos Contratuais (${adendos.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                if (adendos.isEmpty)
                  const Text('Nenhum aditivo registrado. O valor e prazos originais permanecem inalterados.',
                      style: TextStyle(color: Colors.grey, fontSize: 12))
                else
                  ...adendos.map((ad) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.assignment, color: Colors.indigo, size: 20),
                        title: Text('${ad['numeroAdendo'] ?? 'Adendo'} - ${ad['descricao']}'),
                        subtitle: Text(
                            'Tipo: ${ad['tipoAdendo']} | Data: ${dateFormat.format(DateTime.parse(ad['dataAdendo']))}'),
                        trailing: Text(
                          '+ ${currencyFormat.format(ad['valorAcrescimo'] ?? 0)}',
                          style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                        ),
                      )),
                const Divider(height: 32),
                // Seção de Medições
                Text('Medições Realizadas (${medicoes.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                if (medicoes.isEmpty)
                  const Text('Nenhuma medição registrada até o momento.',
                      style: TextStyle(color: Colors.grey, fontSize: 12))
                else
                  ...medicoes.map((m) {
                    final liquido = (m['valorLiquido'] as num?)?.toDouble() ?? 0.0;
                    final inss = (m['valorInss'] as num?)?.toDouble() ?? 0.0;
                    final iss = (m['valorIss'] as num?)?.toDouble() ?? 0.0;
                    final deducaoSub = (m['valorDeducaoSubcontratados'] as num?)?.toDouble() ?? 0.0;

                    return Card(
                      color: Colors.grey.shade50,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Medição #${m['numeroMedicao']} - ${currencyFormat.format(m['valorBruto'])} (Bruto)',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Líquido: ${currencyFormat.format(liquido)}',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Retenções: INSS: ${currencyFormat.format(inss)} | ISS: ${currencyFormat.format(iss)}${deducaoSub > 0 ? ' | Ded. Subcontratados: ${currencyFormat.format(deducaoSub)}' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (m['observacoes'] != null && m['observacoes'].toString().isNotEmpty)
                              Text('Obs: ${m['observacoes']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, {bool isBold = false, Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String? status) {
    Color bg = Colors.green.shade100;
    Color fg = Colors.green.shade800;
    if (status == 'CONCLUIDO') {
      bg = Colors.blue.shade100;
      fg = Colors.blue.shade800;
    } else if (status == 'SUSPENSO' || status == 'CANCELADO') {
      bg = Colors.red.shade100;
      fg = Colors.red.shade800;
    }
    return Chip(
      label: Text(status ?? 'ATIVO', style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: bg,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gavel, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Gestão de Empreiteiros e Adendos'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Contrato Inicial & Adendos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Registre o valor inicial contratado. Conforme o avanço ou alterações no projeto, inclua Adendos de Acréscimo/Supressão de Valor ou Prorrogação de Prazo, mantendo o histórico legal imutável.\n',
              ),
              Text(
                '2. Subcontratação & Dedução de INSS:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Conforme o Art. 31 da Lei 8.212/91 e Instrução Normativa da Receita Federal, quando o Empreiteiro Principal subcontrata etapas de obra, os valores já tributados e retidos dos subempreiteiros podem ser deduzidos da base de cálculo de INSS da medição principal, evitando a bitributação.\n',
              ),
              Text(
                '3. Integração Financeira:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Ao registrar a medição com retenções (INSS, ISS, IRRF), o sistema gera automaticamente a respectiva despesa no módulo Financeiro (Contas a Pagar).',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }

  void _showNovoContratoModal(BuildContext context) {
    final fornecedoresState = ref.read(suprimentosProvider);
    final obrasState = ref.read(obrasProvider);

    final numeroController = TextEditingController();
    final objetoController = TextEditingController();
    final valorOriginalController = TextEditingController();
    final inssController = TextEditingController(text: '11');
    final issController = TextEditingController(text: '5');
    final irrfController = TextEditingController(text: '1.5');

    String? fornecedorId;
    String? obraId = _filtroObraId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Novo Contrato de Empreiteiro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: fornecedorId,
                  decoration: const InputDecoration(labelText: 'Empreiteiro / Subcontratado *', border: OutlineInputBorder()),
                  items: fornecedoresState.fornecedores.map<DropdownMenuItem<String>>((f) {
                    final tipo = f['tipoFornecedor'] ?? 'FORNECEDOR';
                    return DropdownMenuItem<String>(
                      value: f['id'] as String,
                      child: Text('${f['nomeRazao'] ?? f['nome']} ($tipo)'),
                    );
                  }).toList(),
                  onChanged: (val) => setModalState(() => fornecedorId = val),
                ),
                const SizedBox(height: 12),
                obrasState.when(
                  data: (obras) => DropdownButtonFormField<String>(
                    value: obraId,
                    decoration: const InputDecoration(labelText: 'Obra / Canteiro *', border: OutlineInputBorder()),
                    items: obras.map<DropdownMenuItem<String>>((o) => DropdownMenuItem(
                      value: o['id'] as String,
                      child: Text(o['nome'] ?? 'Sem nome'),
                    )).toList(),
                    onChanged: (val) => setModalState(() => obraId = val),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('Erro ao carregar obras'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: numeroController,
                        decoration: const InputDecoration(labelText: 'Nº Contrato * (Ex: CT-001/2026)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: valorOriginalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Valor Original (R\$) *', border: OutlineInputBorder(), prefixText: 'R\$ '),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: objetoController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Objeto do Contrato (Escopo dos Serviços)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: inssController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Retenção INSS %', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: issController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Retenção ISS %', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: irrfController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Retenção IRRF %', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (fornecedorId == null || obraId == null || numeroController.text.isEmpty || valorOriginalController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preencha os campos obrigatórios (*).'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    try {
                      await ref.read(contratosEmpreiteiroProvider.notifier).createContrato({
                        'fornecedorId': fornecedorId,
                        'obraId': obraId,
                        'numeroContrato': numeroController.text.trim(),
                        'objeto': objetoController.text.trim(),
                        'valorOriginal': double.tryParse(valorOriginalController.text.replaceAll(',', '.')) ?? 0.0,
                        'retencaoInss': double.tryParse(inssController.text) ?? 11.0,
                        'retencaoIss': double.tryParse(issController.text) ?? 5.0,
                        'retencaoIrrf': double.tryParse(irrfController.text) ?? 1.5,
                      });
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contrato cadastrado com sucesso!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                  child: const Text('Salvar Contrato'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNovoAdendoModal(BuildContext context, String contratoId) {
    final numeroController = TextEditingController();
    final descricaoController = TextEditingController();
    final valorAcrescimoController = TextEditingController(text: '0');
    String tipoAdendo = 'VALOR';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Registrar Adendo / Aditivo Contratual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: tipoAdendo,
                decoration: const InputDecoration(labelText: 'Tipo de Adendo', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'VALOR', child: Text('Acréscimo de Valor')),
                  DropdownMenuItem(value: 'PRAZO', child: Text('Prorrogação de Prazo')),
                  DropdownMenuItem(value: 'ESCOPO', child: Text('Alteração de Escopo Técnico')),
                  DropdownMenuItem(value: 'MISTO', child: Text('Misto (Valor + Prazo + Escopo)')),
                ],
                onChanged: (val) => setModalState(() => tipoAdendo = val ?? 'VALOR'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numeroController,
                decoration: const InputDecoration(labelText: 'Identificação (Ex: Termo Aditivo 01)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descricaoController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Justificativa / Descrição do Aditivo *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valorAcrescimoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor de Acréscimo Contratual (R\$)',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                  helperText: 'Informe 0 se o aditivo for somente de prazo ou escopo',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (descricaoController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Informe a descrição do aditivo.'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  try {
                    await ref.read(contratosEmpreiteiroProvider.notifier).createAdendo(contratoId, {
                      'tipoAdendo': tipoAdendo,
                      'numeroAdendo': numeroController.text.trim().isNotEmpty ? numeroController.text.trim() : null,
                      'descricao': descricaoController.text.trim(),
                      'valorAcrescimo': double.tryParse(valorAcrescimoController.text.replaceAll(',', '.')) ?? 0.0,
                    });
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Adendo registrado com sucesso!'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao registrar adendo: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                child: const Text('Confirmar Aditivo'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showNovaMedicaoModal(BuildContext context, Map<String, dynamic> contrato) {
    final numeroMedicao = ((contrato['medicoes'] as List<dynamic>?)?.length ?? 0) + 1;
    final valorBrutoController = TextEditingController();
    final deducaoSubController = TextEditingController(text: '0');
    final deducaoAdiantamentoController = TextEditingController(text: '0');
    final observacoesController = TextEditingController();

    final retInssPerc = (contrato['retencaoInss'] as num?)?.toDouble() ?? 11.0;
    final retIssPerc = (contrato['retencaoIss'] as num?)?.toDouble() ?? 5.0;
    final retIrrfPerc = (contrato['retencaoIrrf'] as num?)?.toDouble() ?? 1.5;

    double valorBruto = 0.0;
    double deducaoSub = 0.0;
    double deducaoAdiant = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final baseCalculoInss = (valorBruto - deducaoSub).clamp(0.0, double.infinity);
          final valInss = baseCalculoInss * (retInssPerc / 100.0);
          final valIss = valorBruto * (retIssPerc / 100.0);
          final valIrrf = valorBruto * (retIrrfPerc / 100.0);
          final totalRetencoes = valInss + valIss + valIrrf;
          final valorLiquido = (valorBruto - totalRetencoes - deducaoAdiant).clamp(0.0, double.infinity);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Lançar Medição #$numeroMedicao - ${contrato['numeroContrato']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: valorBrutoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor Bruto Medido (R\$) *',
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        valorBruto = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deducaoSubController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dedução de Serviços Subcontratados (R\$)',
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                      helperText: 'Art. 31 Lei 8.212/91: Abate da base de INSS p/ evitar bitributação',
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        deducaoSub = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deducaoAdiantamentoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dedução de Adiantamentos Concedidos (R\$)',
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        deducaoAdiant = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Simulador de Retenções
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cálculo Automático de Retenções Tributárias:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('INSS ($retInssPerc% s/ base ${currencyFormat.format(baseCalculoInss)}):'),
                            Text('- ${currencyFormat.format(valInss)}', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ISS ($retIssPerc%):'),
                            Text('- ${currencyFormat.format(valIss)}', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('IRRF ($retIrrfPerc%):'),
                            Text('- ${currencyFormat.format(valIrrf)}', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Valor Líquido a Pagar:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(currencyFormat.format(valorLiquido),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: observacoesController,
                    decoration: const InputDecoration(labelText: 'Observações da Medição', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (valorBruto <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Informe um valor bruto válido.'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      try {
                        await ref.read(contratosEmpreiteiroProvider.notifier).createMedicao(contrato['id'], {
                          'numeroMedicao': numeroMedicao,
                          'dataMedicao': DateTime.now().toIso8601String(),
                          'valorBruto': valorBruto,
                          'valorDeducaoSubcontratados': deducaoSub,
                          'valorDeducaoAdiantamento': deducaoAdiant,
                          'observacoes': observacoesController.text.trim(),
                        });
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Medição lançada com sucesso! Despesa enviada ao Financeiro.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao salvar medição: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                    child: const Text('Salvar Medição e Gerar Contas a Pagar'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
