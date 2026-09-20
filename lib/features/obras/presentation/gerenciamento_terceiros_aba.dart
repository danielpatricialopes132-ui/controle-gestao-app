import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/gerenciamento_terceiros_provider.dart';

class GerenciamentoTerceirosAba extends ConsumerStatefulWidget {
  final String obraId;
  final String obraNome;

  const GerenciamentoTerceirosAba({super.key, required this.obraId, required this.obraNome});

  @override
  ConsumerState<GerenciamentoTerceirosAba> createState() => _GerenciamentoTerceirosAbaState();
}

class _GerenciamentoTerceirosAbaState extends ConsumerState<GerenciamentoTerceirosAba> {
  int _modo = 0; // 0 = Empresas do Cliente (Estágios), 1 = Vistorias & Punch List
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final dateFormat = DateFormat('dd/MM/yyyy');

  final List<String> estagiosCiclo = [
    'CONTRATADO',
    'MEDICAO_IN_LOCO',
    'FABRICACAO',
    'PRONTO_ENTREGA',
    'MONTAGEM',
    'ENTREGUE_APROVADO',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(gerenciamentoTerceirosProvider.notifier).fetchAll(widget.obraId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gerenciamentoTerceirosProvider);

    return Column(
      children: [
        // Seletor de Modo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('Empresas do Cliente (Interiores)'),
                      icon: Icon(Icons.architecture),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Vistorias & Punch List'),
                      icon: Icon(Icons.fact_check),
                    ),
                  ],
                  selected: {_modo},
                  onSelectionChanged: (setVal) {
                    setState(() => _modo = setVal.first);
                  },
                ),
              ),
              const SizedBox(width: 12),
              if (_modo == 0) ...[
                if (state.terceiros.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _showRegistrarVisitaModal(context, state.terceiros),
                    icon: const Icon(Icons.event_available, size: 18),
                    label: const Text('Registrar Visita (S-T-Q-Q-S-S-D)'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showNovoTerceiroModal(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Parceiro do Cliente'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white),
                ),
              ]
              else
                ElevatedButton.icon(
                  onPressed: () => _showNovoPunchItemModal(context, state.terceiros),
                  icon: const Icon(Icons.add_task),
                  label: const Text('Registrar Pendência'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange.shade800, foregroundColor: Colors.white),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? Center(child: Text('Erro: ${state.error}'))
                  : _modo == 0
                      ? _buildTerceirosView(state.terceiros, state.mapaVisitasSemanal)
                      : _buildPunchListView(state.punchList),
        ),
      ],
    );
  }

  // --- SEÇÃO 1: EMPRESAS TERCEIRAS DO CLIENTE, ESTÁGIOS & MAPA SEMANAL ---
  Widget _buildTerceirosView(List<dynamic> terceiros, List<dynamic> mapaSemanal) {
    if (terceiros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Nenhum parceiro de interiores ou decoração cadastrado.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 8),
            const Text('Acompanhe marcenarias, marmorarias, automação e coordene os prazos de entrega do cliente.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showNovoTerceiroModal(context),
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar Primeiro Parceiro'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white),
            )
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMapaVisitasSemanalCard(mapaSemanal, terceiros),
        const Padding(
          padding: EdgeInsets.only(bottom: 12, top: 4),
          child: Text('Empresas Parceiras & Ciclo de Fabricação / Instalação',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ...terceiros.map((t) {
          final punchList = (t['punchList'] as List<dynamic>?) ?? [];
          final pendenciasAbertas = punchList.where((p) => p['status'] != 'RESOLVIDO').length;
          final statusAtual = t['status'] ?? 'CONTRATADO';
          final idxEstagio = estagiosCiclo.indexOf(statusAtual);

          return Card(
            elevation: 2.5,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getEspecialidadeColor(t['especialidade']).withValues(alpha: 0.15),
                        child: Icon(_getEspecialidadeIcon(t['especialidade']), color: _getEspecialidadeColor(t['especialidade'])),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['nomeEmpresa'] ?? 'Empresa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Especialidade: ${t['especialidade']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                          ],
                        ),
                      ),
                    _buildStatusEstagioChip(statusAtual),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () async {
                        await ref.read(gerenciamentoTerceirosProvider.notifier).deleteTerceiro(widget.obraId, t['id']);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (t['responsavel'] != null && t['responsavel'].toString().isNotEmpty)
                      Expanded(
                        child: Text('Responsável: ${t['responsavel']}', style: const TextStyle(fontSize: 12)),
                      ),
                    if (t['telefone'] != null && t['telefone'].toString().isNotEmpty)
                      Expanded(
                        child: Text('Contato: ${t['telefone']}', style: const TextStyle(fontSize: 12)),
                      ),
                    if (t['valorContrato'] != null && (t['valorContrato'] as num) > 0)
                      Text('Contrato: ${currencyFormat.format(t['valorContrato'])}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                // Linha de Progresso do Ciclo de Vida
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Estágio: ${_formatEstagioNome(statusAtual)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        if (pendenciasAbertas > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(10)),
                            child: Text('$pendenciasAbertas pendência(s) na vistoria', style: TextStyle(color: Colors.red.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        else
                          const Text('Nenhuma pendência', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (idxEstagio + 1) / estagiosCiclo.length,
                      backgroundColor: Colors.grey.shade200,
                      color: idxEstagio >= 4 ? Colors.green : Colors.teal,
                      minHeight: 6,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Botões de Ação de Estágio
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (idxEstagio > 0)
                      TextButton.icon(
                        onPressed: () {
                          final novoStatus = estagiosCiclo[idxEstagio - 1];
                          ref.read(gerenciamentoTerceirosProvider.notifier).updateTerceiroStatus(widget.obraId, t['id'], novoStatus);
                        },
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Voltar Estágio'),
                      ),
                    const SizedBox(width: 8),
                    if (idxEstagio < estagiosCiclo.length - 1)
                      ElevatedButton.icon(
                        onPressed: () {
                          final novoStatus = estagiosCiclo[idxEstagio + 1];
                          ref.read(gerenciamentoTerceirosProvider.notifier).updateTerceiroStatus(widget.obraId, t['id'], novoStatus);
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text('Avançar p/ ${_formatEstagioNome(estagiosCiclo[idxEstagio + 1])}'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade800, size: 16),
                            const SizedBox(width: 4),
                            Text('Serviço 100% Entregue & Aprovado', style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
        );
      }),
    ],
  );
}

  // --- SEÇÃO 2: VISTORIAS & PUNCH LIST ---
  Widget _buildPunchListView(List<dynamic> punchList) {
    if (punchList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text('Nenhuma pendência ou não-conformidade registrada.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 8),
            const Text('Realize vistorias de entrega de marcenaria, mármores e acabamentos com checklist de qualidade.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: punchList.length,
      itemBuilder: (context, index) {
        final p = punchList[index];
        final isResolvido = p['status'] == 'RESOLVIDO';
        final terceiro = p['terceiro'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isResolvido ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                isResolvido ? Icons.check : Icons.warning_amber_rounded,
                color: isResolvido ? Colors.green.shade800 : Colors.red.shade900,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '${p['ambiente'] ?? 'Ambiente'} - ${p['descricao']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: isResolvido ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                _buildPunchStatusChip(p['status']),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (terceiro != null)
                  Text('Empresa Responsável: ${terceiro['nomeEmpresa']} (${terceiro['especialidade']})',
                      style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                if (p['prazoCorrecao'] != null)
                  Text('Prazo p/ Correção: ${dateFormat.format(DateTime.parse(p['prazoCorrecao']))}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (isResolvido && p['dataResolucao'] != null)
                  Text('Resolvido em: ${dateFormat.format(DateTime.parse(p['dataResolucao']))}',
                      style: const TextStyle(fontSize: 11, color: Colors.green)),
              ],
            ),
            trailing: isResolvido
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                    onPressed: () {
                      ref.read(gerenciamentoTerceirosProvider.notifier).deletePunchItem(widget.obraId, p['id']);
                    },
                  )
                : ElevatedButton(
                    onPressed: () {
                      ref.read(gerenciamentoTerceirosProvider.notifier).updatePunchItemStatus(widget.obraId, p['id'], 'RESOLVIDO');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)),
                    child: const Text('Baixar'),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStatusEstagioChip(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;

    switch (status) {
      case 'CONTRATADO':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        break;
      case 'MEDICAO_IN_LOCO':
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade900;
        break;
      case 'FABRICACAO':
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        break;
      case 'PRONTO_ENTREGA':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
        break;
      case 'MONTAGEM':
        bg = Colors.teal.shade100;
        fg = Colors.teal.shade900;
        break;
      case 'ENTREGUE_APROVADO':
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(_formatEstagioNome(status), style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPunchStatusChip(String status) {
    Color bg = Colors.red.shade100;
    Color fg = Colors.red.shade900;
    String label = 'Pendente';

    if (status == 'EM_CORRECAO') {
      bg = Colors.amber.shade100;
      fg = Colors.amber.shade900;
      label = 'Em Correção';
    } else if (status == 'RESOLVIDO') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
      label = 'Resolvido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  String _formatEstagioNome(String status) {
    switch (status) {
      case 'CONTRATADO': return 'Contratado';
      case 'MEDICAO_IN_LOCO': return 'Medição in loco';
      case 'FABRICACAO': return 'Em Fabricação';
      case 'PRONTO_ENTREGA': return 'Pronto p/ Entrega';
      case 'MONTAGEM': return 'Em Montagem';
      case 'ENTREGUE_APROVADO': return 'Entregue & Aprovado';
      default: return status;
    }
  }

  Color _getEspecialidadeColor(String? esp) {
    switch (esp) {
      case 'MARCENARIA': return Colors.brown;
      case 'MARMORARIA': return Colors.blueGrey;
      case 'AUTOMACAO': return Colors.indigo;
      case 'CLIMATIZACAO': return Colors.cyan;
      case 'ESQUADRIAS': return Colors.deepPurple;
      case 'DECORACAO': return Colors.pink;
      default: return Colors.teal;
    }
  }

  IconData _getEspecialidadeIcon(String? esp) {
    switch (esp) {
      case 'MARCENARIA': return Icons.table_restaurant;
      case 'MARMORARIA': return Icons.square_foot;
      case 'AUTOMACAO': return Icons.settings_remote;
      case 'CLIMATIZACAO': return Icons.ac_unit;
      case 'ESQUADRIAS': return Icons.window;
      case 'DECORACAO': return Icons.chair;
      default: return Icons.handshake;
    }
  }

  void _showNovoTerceiroModal(BuildContext context) {
    final nomeController = TextEditingController();
    final responsavelController = TextEditingController();
    final telefoneController = TextEditingController();
    final emailController = TextEditingController();
    final valorController = TextEditingController();
    final obsController = TextEditingController();
    String especialidade = 'MARCENARIA';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20, left: 20, right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Novo Parceiro do Cliente (Interiores / Terceiros)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: especialidade,
                  decoration: const InputDecoration(labelText: 'Especialidade *', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'MARCENARIA', child: Text('Marcenaria Sob Medida')),
                    DropdownMenuItem(value: 'MARMORARIA', child: Text('Marmoraria & Rochas Nobres')),
                    DropdownMenuItem(value: 'AUTOMACAO', child: Text('Automação, Som & Iluminação')),
                    DropdownMenuItem(value: 'CLIMATIZACAO', child: Text('Climatização (Ar-condicionado VRF)')),
                    DropdownMenuItem(value: 'ESQUADRIAS', child: Text('Esquadrias Especiais & Vidros')),
                    DropdownMenuItem(value: 'DECORACAO', child: Text('Decoração, Cortinas & Mobiliário')),
                    DropdownMenuItem(value: 'OUTROS', child: Text('Outros Serviços Especializados')),
                  ],
                  onChanged: (val) => setModalState(() => especialidade = val ?? 'MARCENARIA'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome da Empresa / Prestador *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: responsavelController, decoration: const InputDecoration(labelText: 'Contato / Projetista', border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: telefoneController, decoration: const InputDecoration(labelText: 'Telefone / WhatsApp', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail de Contato', border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: valorController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Valor Contratado (R\$)', border: OutlineInputBorder(), prefixText: 'R\$ '),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: obsController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Observações / Restrições de Entrada', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (nomeController.text.trim().isEmpty) return;
                    try {
                      await ref.read(gerenciamentoTerceirosProvider.notifier).createTerceiro(widget.obraId, {
                        'nomeEmpresa': nomeController.text.trim(),
                        'especialidade': especialidade,
                        'responsavel': responsavelController.text.trim().isNotEmpty ? responsavelController.text.trim() : null,
                        'telefone': telefoneController.text.trim().isNotEmpty ? telefoneController.text.trim() : null,
                        'email': emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                        'valorContrato': double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0,
                        'observacoes': obsController.text.trim().isNotEmpty ? obsController.text.trim() : null,
                      });
                      if (context.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                  child: const Text('Cadastrar Parceiro'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNovoPunchItemModal(BuildContext context, List<dynamic> terceiros) {
    final ambienteController = TextEditingController();
    final descricaoController = TextEditingController();
    String? terceiroId;
    DateTime prazo = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20, left: 20, right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Registrar Não-Conformidade / Pendência de Vistoria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: ambienteController,
                  decoration: const InputDecoration(labelText: 'Ambiente / Cômodo * (Ex: Cozinha Gourmet, Suíte 02)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: terceiroId,
                  decoration: const InputDecoration(labelText: 'Empresa Terceira Responsável (Opcional)', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Não vinculada a parceiro específico')),
                    ...terceiros.map<DropdownMenuItem<String>>((t) => DropdownMenuItem(
                      value: t['id'] as String,
                      child: Text('${t['nomeEmpresa']} (${t['especialidade']})'),
                    )),
                  ],
                  onChanged: (val) => setModalState(() => terceiroId = val),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descricaoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descrição da Não-Conformidade *',
                    hintText: 'Ex: Quina da bancada de mármore com lasca; porta do armário desalinhada...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Prazo de Correção: ${dateFormat.format(prazo)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: prazo,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) setModalState(() => prazo = picked);
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Alterar Prazo'),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (ambienteController.text.trim().isEmpty || descricaoController.text.trim().isEmpty) return;
                    try {
                      await ref.read(gerenciamentoTerceirosProvider.notifier).createPunchItem(widget.obraId, {
                        'ambiente': ambienteController.text.trim(),
                        'terceiroClienteId': terceiroId,
                        'descricao': descricaoController.text.trim(),
                        'prazoCorrecao': prazo.toIso8601String(),
                      });
                      if (context.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                  child: const Text('Registrar Pendência na Vistoria'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapaVisitasSemanalCard(List<dynamic> mapaSemanal, List<dynamic> terceiros) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.date_range, color: Colors.indigo, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Mapa Semanal de Visitas dos Terceiros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Acompanhamento presencial no canteiro (S • T • Q • Q • S • S • D)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showRegistrarVisitaModal(context, terceiros),
                  icon: const Icon(Icons.add_location_alt, size: 16),
                  label: const Text('Registrar Visita'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (mapaSemanal.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: const Text('Nenhuma visita registrada nesta semana.', style: TextStyle(color: Colors.grey)),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columns: const [
                    DataColumn(label: Text('Parceiro', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Especialidade', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('S', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                    DataColumn(label: Text('T', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                    DataColumn(label: Text('Q', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                    DataColumn(label: Text('Q', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                    DataColumn(label: Text('S', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                    DataColumn(label: Text('S', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                    DataColumn(label: Text('D', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                    DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: mapaSemanal.map((item) {
                    final dias = (item['dias'] as Map<String, dynamic>?) ?? {};
                    Widget buildDiaCell(String diaKey) {
                      final visitasDia = dias[diaKey] as List<dynamic>?;
                      if (visitasDia == null || visitasDia.isEmpty) {
                        return const Center(child: Text('-', style: TextStyle(color: Colors.grey)));
                      }
                      final v = visitasDia.first;
                      final motivo = v['motivo']?.toString() ?? 'Visita';
                      return InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${item['nomeEmpresa']}: $motivo (${v['responsavel'] ?? 'Técnico'})')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            border: Border.all(color: Colors.teal.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            motivo.length > 7 ? '${motivo.substring(0, 6)}.' : motivo,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                          ),
                        ),
                      );
                    }

                    return DataRow(cells: [
                      DataCell(Text(item['nomeEmpresa'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      DataCell(Text(item['especialidade'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                      DataCell(buildDiaCell('seg')),
                      DataCell(buildDiaCell('ter')),
                      DataCell(buildDiaCell('qua')),
                      DataCell(buildDiaCell('qui')),
                      DataCell(buildDiaCell('sex')),
                      DataCell(buildDiaCell('sab')),
                      DataCell(buildDiaCell('dom')),
                      DataCell(Center(
                        child: Text(
                          '${item['totalVisitasNaSemana'] ?? 0}x',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                      )),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRegistrarVisitaModal(BuildContext context, List<dynamic> terceiros) {
    if (terceiros.isEmpty) return;
    String terceiroId = terceiros.first['id'];
    DateTime dataVisita = DateTime.now();
    String motivo = 'MEDICAO';
    final responsavelController = TextEditingController();
    final obsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20, left: 20, right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Registrar Entrada / Visita de Terceiro na Obra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: terceiroId,
                  decoration: const InputDecoration(labelText: 'Empresa Parceira *', border: OutlineInputBorder()),
                  items: terceiros.map<DropdownMenuItem<String>>((t) => DropdownMenuItem(
                    value: t['id'] as String,
                    child: Text('${t['nomeEmpresa']} (${t['especialidade']})'),
                  )).toList(),
                  onChanged: (val) => setModalState(() => terceiroId = val ?? terceiroId),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Data da Visita: ${dateFormat.format(dataVisita)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dataVisita,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) setModalState(() => dataVisita = picked);
                      },
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: const Text('Alterar Data'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: motivo,
                  decoration: const InputDecoration(labelText: 'Finalidade / Motivo da Visita *', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'MEDICAO', child: Text('Medição In Loco de Vãos')),
                    DropdownMenuItem(value: 'MONTAGEM', child: Text('Montagem / Instalação')),
                    DropdownMenuItem(value: 'VISTORIA', child: Text('Vistoria Prévia de Entrega')),
                    DropdownMenuItem(value: 'ALINHAMENTO', child: Text('Alinhamento com Cliente/Arquiteto')),
                    DropdownMenuItem(value: 'OUTROS', child: Text('Outros Serviços Especializados')),
                  ],
                  onChanged: (val) => setModalState(() => motivo = val ?? 'MEDICAO'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: responsavelController,
                  decoration: const InputDecoration(labelText: 'Técnico / Responsável Presente (Opcional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: obsController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Observações da Visita', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(gerenciamentoTerceirosProvider.notifier).registrarVisita(widget.obraId, {
                        'terceiroClienteId': terceiroId,
                        'dataVisita': dataVisita.toIso8601String(),
                        'motivo': motivo,
                        'responsavel': responsavelController.text.trim().isNotEmpty ? responsavelController.text.trim() : null,
                        'observacoes': obsController.text.trim().isNotEmpty ? obsController.text.trim() : null,
                      });
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Visita registrada com sucesso no Mapa Semanal!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                  child: const Text('Salvar Visita no Mapa Semanal'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
