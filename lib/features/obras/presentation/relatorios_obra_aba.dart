import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/revistas_provider.dart';
import '../services/revista_pdf_service.dart';
import '../services/rdo_pdf_service.dart';

class RelatoriosObraAba extends ConsumerStatefulWidget {
  final String obraId;
  final String obraNome;

  const RelatoriosObraAba({super.key, required this.obraId, required this.obraNome});

  @override
  ConsumerState<RelatoriosObraAba> createState() => _RelatoriosObraAbaState();
}

class _RelatoriosObraAbaState extends ConsumerState<RelatoriosObraAba> {
  int _modoSelecionado = 0; // 0 = Revista (Semanal/Mensal), 1 = Diário Técnico (RDO)
  String _filtroPeriodicidade = 'TODOS'; // 'TODOS' | 'MENSAL' | 'SEMANAL'
  DateTime _dataRdoSelecionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(revistasProvider.notifier).fetchRevistas(widget.obraId));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Seletor de Modo: Revista vs Diário Técnico
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
                      label: Text('Revista da Obra'),
                      icon: Icon(Icons.menu_book),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Diário Técnico (RDO)'),
                      icon: Icon(Icons.assignment),
                    ),
                  ],
                  selected: {_modoSelecionado},
                  onSelectionChanged: (setVal) {
                    setState(() => _modoSelecionado = setVal.first);
                  },
                ),
              ),
              const SizedBox(width: 12),
              if (_modoSelecionado == 0)
                ElevatedButton.icon(
                  onPressed: () => _showNovaRevistaModal(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nova Revista / Boletim'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _gerarRdoPdfDoDia(),
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimir RDO do Dia'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _modoSelecionado == 0 ? _buildRevistasView() : _buildDiarioTecnicoView(),
        ),
      ],
    );
  }

  // --- SEÇÃO 1: REVISTAS EXECUTIVAS (SEMANAL E MENSAL) ---
  Widget _buildRevistasView() {
    final state = ref.watch(revistasProvider);

    final revistasFiltradas = state.revistas.where((r) {
      if (_filtroPeriodicidade == 'TODOS') return true;
      return r['tipoPeriodicidade'] == _filtroPeriodicidade;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Formato da Edição: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Todos'),
                selected: _filtroPeriodicidade == 'TODOS',
                onSelected: (_) => setState(() => _filtroPeriodicidade = 'TODOS'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Revista Mensal'),
                selected: _filtroPeriodicidade == 'MENSAL',
                selectedColor: Colors.indigo.shade100,
                onSelected: (_) => setState(() => _filtroPeriodicidade = 'MENSAL'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Boletim Semanal'),
                selected: _filtroPeriodicidade == 'SEMANAL',
                selectedColor: Colors.teal.shade100,
                onSelected: (_) => setState(() => _filtroPeriodicidade = 'SEMANAL'),
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
                  : revistasFiltradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_stories, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text('Nenhuma revista ou boletim gerado ainda.',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                              const SizedBox(height: 8),
                              const Text('Compile relatórios estilo revista com fotos, editorial e métricas.',
                                  style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => _showNovaRevistaModal(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Compilar Primeira Edição'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                              )
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: revistasFiltradas.length,
                          itemBuilder: (context, index) {
                            final rev = revistasFiltradas[index];
                            final isSemanal = rev['tipoPeriodicidade'] == 'SEMANAL';
                            final corTema = isSemanal ? Colors.teal : Colors.indigo;
                            final fotos = (rev['fotosSelecionadas'] as List<dynamic>?) ?? [];
                            final avanco = (rev['percentualAvanco'] as num?)?.toDouble() ?? 0.0;

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: corTema.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: corTema.withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            isSemanal ? 'BOLETIM SEMANAL' : 'REVISTA MENSAL',
                                            style: TextStyle(color: corTema, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(rev['periodoReferencia'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                          tooltip: 'Excluir edição',
                                          onPressed: () async {
                                            await ref.read(revistasProvider.notifier).deleteRevista(widget.obraId, rev['id']);
                                          },
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      rev['titulo'] ?? 'Relatório de Obra',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      rev['editorial'] ?? '',
                                      style: TextStyle(color: Colors.blueGrey.shade800, fontSize: 13, height: 1.4),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    // Indicadores
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildMiniIndicator('Avanço Físico', '${avanco.toStringAsFixed(0)}%', Colors.indigo),
                                          _buildMiniIndicator('Dias de Sol', '${rev['climaDiasSol']} dias', Colors.green.shade700),
                                          _buildMiniIndicator('Dias de Chuva', '${rev['climaDiasChuva']} dias', Colors.blueGrey),
                                          _buildMiniIndicator('Fotos Anexadas', '${fotos.length} fotos', Colors.deepOrange),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _showVisualizarRevistaModal(context, rev),
                                          icon: const Icon(Icons.visibility, size: 18),
                                          label: const Text('Visualizar Conteúdo'),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton.icon(
                                          onPressed: () => _exportarRevistaPdf(rev),
                                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                                          label: const Text('Exportar Revista (PDF)'),
                                          style: ElevatedButton.styleFrom(backgroundColor: corTema, foregroundColor: Colors.white),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  // --- SEÇÃO 2: DIÁRIO DE OBRA TÉCNICO TRADICIONAL (RDO) ---
  Widget _buildDiarioTecnicoView() {
    final dataStr = DateFormat('yyyy-MM-dd').format(_dataRdoSelecionada);
    final rdoAsync = ref.watch(diarioObraTecnicoProvider(DiarioParams(obraId: widget.obraId, dataStr: dataStr)));

    return Column(
      children: [
        // Seletor de Data
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blueGrey.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _dataRdoSelecionada = _dataRdoSelecionada.subtract(const Duration(days: 1))),
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dataRdoSelecionada,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _dataRdoSelecionada = picked);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy (EEEE)', 'pt_BR').format(_dataRdoSelecionada).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _dataRdoSelecionada = _dataRdoSelecionada.add(const Duration(days: 1))),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: rdoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Erro ao carregar Diário: $err')),
            data: (data) {
              final presencas = (data['presencas'] as List<dynamic>?) ?? [];
              final fotos = (data['fotos'] as List<dynamic>?) ?? [];
              final clima = data['condicaoClimatica'] ?? 'Tempo Bom';
              final totalEfetivo = data['totalEfetivo'] ?? 0;
              final totalHoras = data['totalHoras'] ?? 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Cabeçalho do RDO Técnico
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blueGrey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRdoMetric('Condição Climática', clima, Icons.wb_sunny, Colors.amber.shade800),
                          _buildRdoMetric('Efetivo Presente', '$totalEfetivo pessoas', Icons.groups, Colors.indigo),
                          _buildRdoMetric('Total Horas', '${totalHoras}h', Icons.access_time, Colors.teal),
                          _buildRdoMetric('Registros Fotográficos', '${fotos.length} fotos', Icons.camera_alt, Colors.deepPurple),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Equipe Presente no Canteiro (Trabalhadores e Terceirizados):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    if (presencas.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        child: Text('Nenhuma presença apontada nesta data.', style: TextStyle(color: Colors.grey.shade600)),
                      )
                    else
                      ...presencas.map((p) {
                        final func = p['funcionario'] ?? {};
                        final forn = func['fornecedor'];
                        final ehSub = forn != null && (forn['tipoFornecedor'] == 'SUBCONTRATADO' || forn['empreiteiroPai'] != null);
                        final ehEmp = forn != null && !ehSub;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: p['status'] == 'TRABALHO' ? Colors.green.shade100 : Colors.amber.shade100,
                              child: Icon(
                                p['status'] == 'TRABALHO' ? Icons.check : Icons.warning_amber,
                                color: p['status'] == 'TRABALHO' ? Colors.green.shade800 : Colors.amber.shade900,
                                size: 18,
                              ),
                            ),
                            title: Text(func['nome'] ?? 'Colaborador', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${func['cargo'] ?? 'Operacional'} | Status: ${p['status']} (${p['horasTrabalhadas']}h)'),
                                if (ehSub)
                                  Text('↳ Subcontratada: ${forn['nomeRazao'] ?? forn['nome']}', style: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold))
                                else if (ehEmp)
                                  Text('↳ Empreiteiro: ${forn['nomeRazao'] ?? forn['nome']}', style: const TextStyle(color: Colors.indigo, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            trailing: Text(p['observacao'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
                    const Text('Fotos Registradas no Dia:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    if (fotos.isEmpty)
                      const Text('Nenhuma foto cadastrada na aba GED/Fotos para este dia.', style: TextStyle(color: Colors.grey))
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: fotos.map((f) {
                          return Container(
                            width: 140,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              children: [
                                Container(
                                  height: 80,
                                  color: Colors.grey.shade200,
                                  child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                                ),
                                const SizedBox(height: 4),
                                Text(f['descricao'] ?? 'Foto do dia', style: const TextStyle(fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiniIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildRdoMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _exportarRevistaPdf(Map<String, dynamic> rev) {
    final obra = rev['obra'] ?? {};
    final proposta = obra['proposta'] ?? {};
    final cliente = proposta['cliente'] ?? {};

    RevistaPdfService.exportarRevista(
      nomeObra: widget.obraNome,
      clienteNome: cliente['nome'] ?? 'Cliente do Empreendimento',
      tipoPeriodicidade: rev['tipoPeriodicidade'] ?? 'MENSAL',
      titulo: rev['titulo'] ?? 'Relatório de Obra',
      periodoReferencia: rev['periodoReferencia'] ?? '',
      editorial: rev['editorial'] ?? '',
      destaques: rev['destaques'] ?? '',
      lookahead: rev['lookahead'] ?? '',
      climaDiasSol: rev['climaDiasSol'] ?? 0,
      climaDiasChuva: rev['climaDiasChuva'] ?? 0,
      percentualAvanco: (rev['percentualAvanco'] as num?)?.toDouble() ?? 0.0,
      fotos: (rev['fotosSelecionadas'] as List<dynamic>?) ?? [],
    );
  }

  Future<void> _gerarRdoPdfDoDia() async {
    final dataStr = DateFormat('yyyy-MM-dd').format(_dataRdoSelecionada);
    final data = await ref.read(diarioObraTecnicoProvider(DiarioParams(obraId: widget.obraId, dataStr: dataStr)).future);
    final presencas = (data['presencas'] as List<dynamic>?) ?? [];
    final fotos = (data['fotos'] as List<dynamic>?) ?? [];

    final apontamentosFormatados = presencas.map<Map<String, dynamic>>((p) {
      final func = p['funcionario'] ?? {};
      return {
        'nome': func['nome'] ?? 'Colaborador',
        'tipo': func['cargo'] ?? 'Operacional',
        'status': p['status'] ?? 'TRABALHO',
        'horasTrabalhadas': p['horasTrabalhadas'] ?? 8,
        'observacao': p['observacao'] ?? '',
      };
    }).toList();

    await RdoPdfService.imprimirRdo(
      widget.obraNome,
      _dataRdoSelecionada,
      apontamentosFormatados,
      fotos,
    );
  }

  void _showNovaRevistaModal(BuildContext context) {
    String tipo = 'MENSAL';
    final tituloController = TextEditingController();
    final periodoController = TextEditingController(text: DateFormat('MM/yyyy').format(DateTime.now()));
    final editorialController = TextEditingController();
    final destaquesController = TextEditingController();
    final lookaheadController = TextEditingController();

    DateTime dtInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime dtFim = DateTime.now();

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
                const Text('Compilar Nova Edição de Revista de Obra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: tipo,
                  decoration: const InputDecoration(labelText: 'Formato da Publicação *', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'MENSAL', child: Text('Revista Mensal Executiva (30 dias)')),
                    DropdownMenuItem(value: 'SEMANAL', child: Text('Boletim Semanal de Evolução (7 dias)')),
                  ],
                  onChanged: (val) {
                    setModalState(() {
                      tipo = val ?? 'MENSAL';
                      if (tipo == 'SEMANAL') {
                        periodoController.text = 'Semana ${DateFormat('w/yyyy').format(DateTime.now())}';
                        dtInicio = DateTime.now().subtract(const Duration(days: 7));
                      } else {
                        periodoController.text = DateFormat('MM/yyyy').format(DateTime.now());
                        dtInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: tituloController,
                        decoration: InputDecoration(
                          labelText: 'Título da Edição',
                          hintText: tipo == 'SEMANAL' ? 'Ex: Boletim Semanal da Estrutura' : 'Ex: Edição Especial de Acabamentos',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: periodoController,
                        decoration: const InputDecoration(labelText: 'Período *', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: editorialController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Editorial / Carta do Engenheiro *',
                    hintText: 'Apresente os principais avanços, soluções técnicas e destaques do período...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: destaquesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Marcos & Destaques Concluídos',
                    hintText: '• Conclusão da laje do 4º pavimento\n• Término das prumadas hidráulicas',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lookaheadController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Lookahead (Metas do Próximo Ciclo)',
                    hintText: '• Início do contrapiso e impermeabilização da cobertura',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (periodoController.text.isEmpty) return;
                    try {
                      await ref.read(revistasProvider.notifier).createRevista(widget.obraId, {
                        'tipoPeriodicidade': tipo,
                        'titulo': tituloController.text.trim().isNotEmpty ? tituloController.text.trim() : null,
                        'periodoReferencia': periodoController.text.trim(),
                        'dataInicio': dtInicio.toIso8601String(),
                        'dataFim': dtFim.toIso8601String(),
                        'editorial': editorialController.text.trim().isNotEmpty ? editorialController.text.trim() : null,
                        'destaques': destaquesController.text.trim().isNotEmpty ? destaquesController.text.trim() : null,
                        'lookahead': lookaheadController.text.trim().isNotEmpty ? lookaheadController.text.trim() : null,
                      });
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Revista compilada com sucesso!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao compilar: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                  child: const Text('Compilar e Publicar Edição'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVisualizarRevistaModal(BuildContext context, Map<String, dynamic> rev) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(rev['titulo'] ?? 'Revista da Obra'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Período: ${rev['periodoReferencia']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              const Text('Mensagem do Engenheiro (Editorial):', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(rev['editorial'] ?? '', style: const TextStyle(fontSize: 13, height: 1.4)),
              const SizedBox(height: 12),
              const Text('Destaques da Edição:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(rev['destaques'] ?? '', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              const Text('Lookahead (Próximos Passos):', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(rev['lookahead'] ?? '', style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _exportarRevistaPdf(rev);
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Baixar PDF'),
          ),
        ],
      ),
    );
  }
}
