import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/gerenciamento_terceiros_provider.dart';
import 'widgets/signature_pad_dialog.dart';
import 'widgets/terceiros/kpis_terceiros_header.dart';
import 'widgets/terceiros/mapa_visitas_semanal_card.dart';
import 'widgets/terceiros/terceiros_estagios_view.dart';
import 'widgets/terceiros/portaria_retiradas_view.dart';
import 'widgets/terceiros/punch_list_recebimento_view.dart';
import 'widgets/terceiros/agente_whatsapp_modal.dart';

class GerenciamentoTerceirosAba extends ConsumerStatefulWidget {
  final String obraId;
  final String obraNome;

  const GerenciamentoTerceirosAba({super.key, required this.obraId, required this.obraNome});

  @override
  ConsumerState<GerenciamentoTerceirosAba> createState() => _GerenciamentoTerceirosAbaState();
}

class _GerenciamentoTerceirosAbaState extends ConsumerState<GerenciamentoTerceirosAba> {
  int _modo = 0; // 0 = Empresas & Visitas, 1 = Portaria & Retirada de Itens, 2 = Vistorias & Recebimento
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

    // Contadores para o KPI Header
    final totalTerceiros = state.terceiros.length;
    final totalVisitasSemana = state.mapaVisitasSemanal.fold<int>(
      0,
      (sum, item) => sum + ((item['totalVisitasNaSemana'] as num?)?.toInt() ?? 0),
    );
    final totalRetiradasPendentes = state.termosRetirada.where((t) => t['status'] == 'RETIRADO').length;
    final punchListTotal = state.punchList.length;
    final punchListResolvidos = state.punchList.where((p) => p['status'] == 'RESOLVIDO').length;

    return Column(
      children: [
        // 1. Dashboard Superior de Métricas & KPIs
        KpisTerceirosHeader(
          totalTerceiros: totalTerceiros,
          totalVisitasSemana: totalVisitasSemana,
          totalRetiradasPendentes: totalRetiradasPendentes,
          punchListResolvidos: punchListResolvidos,
          punchListTotal: punchListTotal,
        ),

        // 2. Seletor de Modo (Abas da Coordenação)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('Interiores & Mapa Visitas'),
                      icon: Icon(Icons.architecture),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Portaria & Retirada de Itens'),
                      icon: Icon(Icons.shield_outlined),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text('Punch List & Recebimento'),
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
                  label: const Text('Novo Parceiro'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => AgenteWhatsappModal.show(context),
                  icon: const Icon(Icons.smart_toy),
                  label: const Text('Agente IA (WhatsApp)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                ),
              ] else if (_modo == 1) ...[
                ElevatedButton.icon(
                  onPressed: () => _showNovaPortariaModal(context, state.terceiros),
                  icon: const Icon(Icons.badge, size: 18),
                  label: const Text('Liberação de Portaria'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showNovaRetiradaModal(context, state.terceiros),
                  icon: const Icon(Icons.outbox, size: 18),
                  label: const Text('Nova Cautela de Itens'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => _showNovoTermoRecebimentoModal(context, state.punchList),
                  icon: const Icon(Icons.verified, size: 18),
                  label: const Text('Termo de Recebimento (Assinatura)'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4338CA), foregroundColor: Colors.white),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showNovoPunchItemModal(context, state.terceiros),
                  icon: const Icon(Icons.add_task),
                  label: const Text('Registrar Pendência'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange.shade800, foregroundColor: Colors.white),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),

        // 3. Conteúdo Dinâmico por Modo
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? Center(child: Text('Erro: ${state.error}'))
                  : _modo == 0
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            MapaVisitasSemanalCard(
                              mapaSemanal: state.mapaVisitasSemanal,
                              terceiros: state.terceiros,
                              onApontarEntrada: () => _showRegistrarVisitaModal(context, state.terceiros),
                            ),
                            TerceirosEstagiosView(
                              terceiros: state.terceiros,
                              estagiosCiclo: estagiosCiclo,
                              onUpdateStatus: (tId, status) {
                                ref.read(gerenciamentoTerceirosProvider.notifier).updateTerceiroStatus(widget.obraId, tId, status);
                              },
                              onDeleteTerceiro: (tId) {
                                ref.read(gerenciamentoTerceirosProvider.notifier).deleteTerceiro(widget.obraId, tId);
                              },
                              onNovoTerceiro: () => _showNovoTerceiroModal(context),
                            ),
                          ],
                        )
                      : _modo == 1
                          ? PortariaRetiradasView(
                              obraNome: widget.obraNome,
                              portariaLiberacoes: state.portariaLiberacoes,
                              termosRetirada: state.termosRetirada,
                              onDeleteLiberacao: (id) {
                                ref.read(gerenciamentoTerceirosProvider.notifier).deletePortariaLiberacao(widget.obraId, id);
                              },
                              onBaixarDevolucao: (id) {
                                ref.read(gerenciamentoTerceirosProvider.notifier).registrarDevolucaoRetirada(widget.obraId, id, 'DEVOLVIDO_TOTAL');
                              },
                              onNovaPortaria: () => _showNovaPortariaModal(context, state.terceiros),
                              onNovaRetirada: () => _showNovaRetiradaModal(context, state.terceiros),
                            )
                          : PunchListRecebimentoView(
                              obraNome: widget.obraNome,
                              punchList: state.punchList,
                              termosRecebimento: state.termosRecebimento,
                              onBaixarPunchItem: (id) {
                                ref.read(gerenciamentoTerceirosProvider.notifier).updatePunchItemStatus(widget.obraId, id, 'RESOLVIDO');
                              },
                              onDeletePunchItem: (id) {
                                ref.read(gerenciamentoTerceirosProvider.notifier).deletePunchItem(widget.obraId, id);
                              },
                              onNovoTermoRecebimento: () => _showNovoTermoRecebimentoModal(context, state.punchList),
                              onNovoPunchItem: () => _showNovoPunchItemModal(context, state.terceiros),
                            ),
        ),
      ],
    );
  }

  // =========================================================================
  // --- MODAIS DE CADASTRO E CAPTURA DE ASSINATURA DIGITAL ---
  // =========================================================================

  // 1. Modal: Novo Parceiro
  void _showNovoTerceiroModal(BuildContext context) {
    final nomeController = TextEditingController();
    final responsavelController = TextEditingController();
    final telefoneController = TextEditingController();
    final emailController = TextEditingController();
    final valorController = TextEditingController();
    String especialidade = 'MARCENARIA';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Cadastrar Parceiro do Cliente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome da Empresa *')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: especialidade,
                  decoration: const InputDecoration(labelText: 'Especialidade / Escopo'),
                  items: const [
                    DropdownMenuItem(value: 'MARCENARIA', child: Text('Marcenaria sob Medida')),
                    DropdownMenuItem(value: 'MARMORARIA', child: Text('Marmoraria & Bancadas')),
                    DropdownMenuItem(value: 'AUTOMACAO', child: Text('Automação & Áudio/Vídeo')),
                    DropdownMenuItem(value: 'CLIMATIZACAO', child: Text('Climatização / Ar Condicionado')),
                    DropdownMenuItem(value: 'ESQUADRIAS', child: Text('Esquadrias Especiais / Vidros')),
                    DropdownMenuItem(value: 'DECORACAO', child: Text('Decoração & Mobiliário')),
                    DropdownMenuItem(value: 'OUTROS', child: Text('Outros')),
                  ],
                  onChanged: (val) => setDialogState(() => especialidade = val!),
                ),
                const SizedBox(height: 12),
                TextField(controller: responsavelController, decoration: const InputDecoration(labelText: 'Nome do Responsável / Projetista')),
                const SizedBox(height: 12),
                TextField(controller: telefoneController, decoration: const InputDecoration(labelText: 'Telefone / WhatsApp')),
                const SizedBox(height: 12),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail')),
                const SizedBox(height: 12),
                TextField(controller: valorController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor do Contrato (R\$)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nomeController.text.isEmpty) return;
                final valor = double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0;
                await ref.read(gerenciamentoTerceirosProvider.notifier).createTerceiro(widget.obraId, {
                  'nomeEmpresa': nomeController.text,
                  'especialidade': especialidade,
                  'responsavel': responsavelController.text,
                  'telefone': telefoneController.text,
                  'email': emailController.text,
                  'valorContrato': valor,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Salvar Parceiro'),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Modal: Registrar Visita Semanal
  void _showRegistrarVisitaModal(BuildContext context, List<dynamic> terceiros) {
    String? selectedTerceiroId = terceiros.isNotEmpty ? terceiros.first['id'] : null;
    DateTime dataVisita = DateTime.now();
    String motivo = 'MONTAGEM';
    final responsavelController = TextEditingController();
    final obsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Apontar Entrada / Visita de Parceiro'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedTerceiroId,
                  decoration: const InputDecoration(labelText: 'Empresa Parceira *'),
                  items: terceiros.map<DropdownMenuItem<String>>((t) {
                    return DropdownMenuItem<String>(
                      value: t['id'],
                      child: Text('${t['nomeEmpresa']} (${t['especialidade']})'),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedTerceiroId = val),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Data da Visita'),
                  subtitle: Text(dateFormat.format(dataVisita)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dataVisita,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => dataVisita = picked);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: motivo,
                  decoration: const InputDecoration(labelText: 'Finalidade / Motivo'),
                  items: const [
                    DropdownMenuItem(value: 'MEDICAO', child: Text('Medição in loco')),
                    DropdownMenuItem(value: 'MONTAGEM', child: Text('Montagem / Instalação')),
                    DropdownMenuItem(value: 'VISTORIA', child: Text('Vistoria técnica / Conferência')),
                    DropdownMenuItem(value: 'ALINHAMENTO', child: Text('Alinhamento de projeto com arquiteto')),
                    DropdownMenuItem(value: 'OUTROS', child: Text('Outros')),
                  ],
                  onChanged: (val) => setDialogState(() => motivo = val!),
                ),
                const SizedBox(height: 12),
                TextField(controller: responsavelController, decoration: const InputDecoration(labelText: 'Nome do Técnico / Montador presente')),
                const SizedBox(height: 12),
                TextField(controller: obsController, decoration: const InputDecoration(labelText: 'Observações do dia')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (selectedTerceiroId == null) return;
                await ref.read(gerenciamentoTerceirosProvider.notifier).registrarVisita(widget.obraId, {
                  'terceiroClienteId': selectedTerceiroId,
                  'dataVisita': dataVisita.toIso8601String(),
                  'motivo': motivo,
                  'responsavel': responsavelController.text,
                  'observacoes': obsController.text,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Salvar Presença'),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Modal: Nova Liberação de Portaria
  void _showNovaPortariaModal(BuildContext context, List<dynamic> terceiros) {
    final empresaController = TextEditingController();
    final placaController = TextEditingController();
    final modeloController = TextEditingController();
    final horarioController = TextEditingController(text: '08:00 às 17:00 (Segunda a Sexta)');
    final regrasController = TextEditingController(
      text: '1. Uso obrigatório de crachá e calçado fechado.\n'
            '2. Entrada exclusivamente pela portaria de serviço.\n'
            '3. Proibido ruído antes das 08h e após 17h.\n'
            '4. Descarte de entulhos sob responsabilidade da contratada.',
    );
    DateTime dataInicio = DateTime.now();
    DateTime dataFim = DateTime.now().add(const Duration(days: 7));
    String tipoAcesso = 'TERCEIRO_CLIENTE';
    String? terceiroSelecionadoId;

    final List<Map<String, String>> colaboradores = [
      {'nome': '', 'rg': '', 'cpf': '', 'funcao': 'Montador'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Emitir Liberação de Portaria Condominial'),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (terceiros.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: terceiroSelecionadoId,
                      decoration: const InputDecoration(labelText: 'Vincular a Parceiro do Cliente (Opcional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Nenhum / Empresa Avulsa')),
                        ...terceiros.map<DropdownMenuItem<String>>((t) {
                          return DropdownMenuItem<String>(value: t['id'], child: Text('${t['nomeEmpresa']} (${t['especialidade']})'));
                        }),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          terceiroSelecionadoId = val;
                          if (val != null) {
                            final sel = terceiros.firstWhere((element) => element['id'] == val);
                            empresaController.text = sel['nomeEmpresa'] ?? '';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(controller: empresaController, decoration: const InputDecoration(labelText: 'Nome / Razão Social da Empresa *')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Data Início', style: TextStyle(fontSize: 12)),
                          subtitle: Text(dateFormat.format(dataInicio), style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () async {
                            final p = await showDatePicker(context: context, initialDate: dataInicio, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) setDialogState(() => dataInicio = p);
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('Data Término', style: TextStyle(fontSize: 12)),
                          subtitle: Text(dateFormat.format(dataFim), style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () async {
                            final p = await showDatePicker(context: context, initialDate: dataFim, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) setDialogState(() => dataFim = p);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: modeloController, decoration: const InputDecoration(labelText: 'Veículo (Ex: Van Master)'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: placaController, decoration: const InputDecoration(labelText: 'Placa do Veículo'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: horarioController, decoration: const InputDecoration(labelText: 'Horário Permitido')),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Colaboradores & Montadores Autorizados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            colaboradores.add({'nome': '', 'rg': '', 'cpf': '', 'funcao': 'Montador'});
                          });
                        },
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Adicionar'),
                      ),
                    ],
                  ),
                  ...colaboradores.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final colab = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: colab['nome'],
                              decoration: const InputDecoration(labelText: 'Nome Completo', isDense: true),
                              onChanged: (v) => colab['nome'] = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: colab['rg'],
                              decoration: const InputDecoration(labelText: 'RG', isDense: true),
                              onChanged: (v) => colab['rg'] = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: colab['cpf'],
                              decoration: const InputDecoration(labelText: 'CPF', isDense: true),
                              onChanged: (v) => colab['cpf'] = v,
                            ),
                          ),
                          if (colaboradores.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red, size: 18),
                              onPressed: () => setDialogState(() => colaboradores.removeAt(idx)),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  TextField(controller: regrasController, maxLines: 3, decoration: const InputDecoration(labelText: 'Regras Condominiais (Impressas no termo)')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (empresaController.text.isEmpty) return;
                await ref.read(gerenciamentoTerceirosProvider.notifier).createPortariaLiberacao(widget.obraId, {
                  'terceiroClienteId': terceiroSelecionadoId,
                  'tipoAcesso': tipoAcesso,
                  'empresaNome': empresaController.text,
                  'veiculoModelo': modeloController.text,
                  'veiculoPlaca': placaController.text,
                  'dataInicio': dataInicio.toIso8601String(),
                  'dataFim': dataFim.toIso8601String(),
                  'horarioPermitido': horarioController.text,
                  'colaboradores': colaboradores.where((c) => c['nome']!.isNotEmpty).toList(),
                  'regrasCondominio': regrasController.text,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Salvar & Liberar'),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Modal: Nova Retirada de Itens com Coleta de Assinatura Digital
  void _showNovaRetiradaModal(BuildContext context, List<dynamic> terceiros) {
    final empresaController = TextEditingController();
    final responsavelController = TextEditingController();
    final docController = TextEditingController();
    final obsController = TextEditingController();
    String motivo = 'USINAGEM_BANCADA';
    DateTime dataPrevisao = DateTime.now().add(const Duration(days: 5));
    String? assinaturaRetiranteBase64;
    String? assinaturaObraBase64;

    final List<Map<String, dynamic>> itens = [
      {'item': 'Cuba Inox Tramontina', 'quantidade': 1, 'unidade': 'un', 'estadoConservacao': 'Novo na caixa lacrada', 'observacao': 'Retirado p/ corte de granito'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Cautela de Retirada de Itens por Terceiros'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: empresaController, decoration: const InputDecoration(labelText: 'Empresa que está retirando (Ex: Marmoraria Real) *')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: responsavelController, decoration: const InputDecoration(labelText: 'Nome do Responsável pela Retirada *'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: docController, decoration: const InputDecoration(labelText: 'Documento (RG ou CPF)'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: motivo,
                          decoration: const InputDecoration(labelText: 'Finalidade'),
                          items: const [
                            DropdownMenuItem(value: 'USINAGEM_BANCADA', child: Text('Usinagem / furação de bancadas')),
                            DropdownMenuItem(value: 'CORTE_AJUSTE', child: Text('Corte e ajuste em oficina')),
                            DropdownMenuItem(value: 'PINTURA_OFICINA', child: Text('Pintura / laca em cabine')),
                            DropdownMenuItem(value: 'AMOSTRA', child: Text('Amostra de teste')),
                            DropdownMenuItem(value: 'OUTROS', child: Text('Outros')),
                          ],
                          onChanged: (val) => setDialogState(() => motivo = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListTile(
                          title: const Text('Previsão Retorno', style: TextStyle(fontSize: 12)),
                          subtitle: Text(dateFormat.format(dataPrevisao), style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () async {
                            final p = await showDatePicker(context: context, initialDate: dataPrevisao, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) setDialogState(() => dataPrevisao = p);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Itens / Peças a Retirar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            itens.add({'item': '', 'quantidade': 1, 'unidade': 'un', 'estadoConservacao': 'Em bom estado', 'observacao': ''});
                          });
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Adicionar Peça'),
                      ),
                    ],
                  ),
                  ...itens.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final it = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: TextFormField(
                                  initialValue: it['item'],
                                  decoration: const InputDecoration(labelText: 'Descrição do Item (Ex: Cuba Morgana Inox)', isDense: true),
                                  onChanged: (v) => it['item'] = v,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  initialValue: '${it['quantidade']}',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Qtd', isDense: true),
                                  onChanged: (v) => it['quantidade'] = int.tryParse(v) ?? 1,
                                ),
                              ),
                              if (itens.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red, size: 18),
                                  onPressed: () => setDialogState(() => itens.removeAt(idx)),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: it['estadoConservacao'],
                                  decoration: const InputDecoration(labelText: 'Estado de Conservação', isDense: true),
                                  onChanged: (v) => it['estadoConservacao'] = v,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: it['observacao'],
                                  decoration: const InputDecoration(labelText: 'Observação / Destino', isDense: true),
                                  onChanged: (v) => it['observacao'] = v,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text('Coleta de Assinaturas Digitais em Tela:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F766E))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final sig = await SignaturePadDialog.show(
                              context,
                              title: 'Assinatura do Retirante',
                              signerName: responsavelController.text.isNotEmpty ? responsavelController.text : 'Terceiro Responsável',
                              subtitle: 'Declaro ter recebido os itens descritos para transporte e usinagem.',
                            );
                            if (sig != null) {
                              setDialogState(() => assinaturaRetiranteBase64 = sig);
                            }
                          },
                          icon: Icon(assinaturaRetiranteBase64 != null ? Icons.check_circle : Icons.draw, color: assinaturaRetiranteBase64 != null ? Colors.green : Colors.teal),
                          label: Text(assinaturaRetiranteBase64 != null ? 'Retirante Assinou' : 'Assinar (Retirante)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final sig = await SignaturePadDialog.show(
                              context,
                              title: 'Assinatura da Engenharia da Obra',
                              signerName: 'Encarregado / Coordenação',
                              subtitle: 'Autorizo a saída provisória dos itens descritos sob cautela.',
                            );
                            if (sig != null) {
                              setDialogState(() => assinaturaObraBase64 = sig);
                            }
                          },
                          icon: Icon(assinaturaObraBase64 != null ? Icons.check_circle : Icons.draw, color: assinaturaObraBase64 != null ? Colors.green : Colors.teal),
                          label: Text(assinaturaObraBase64 != null ? 'Obra Assinou' : 'Assinar (Obra)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (empresaController.text.isEmpty || responsavelController.text.isEmpty) return;
                await ref.read(gerenciamentoTerceirosProvider.notifier).createTermoRetirada(widget.obraId, {
                  'empresaRetirante': empresaController.text,
                  'nomeResponsavelRetirada': responsavelController.text,
                  'documentoResponsavel': docController.text,
                  'motivoRetirada': motivo,
                  'previsaoDevolucao': dataPrevisao.toIso8601String(),
                  'itensRetirados': itens.where((it) => it['item'].toString().isNotEmpty).toList(),
                  'assinaturaDigitalRetirante': assinaturaRetiranteBase64,
                  'assinaturaDigitalResponsavelObra': assinaturaObraBase64,
                  'observacoes': obsController.text,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Emitir Termo de Cautela'),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Modal: Novo Termo de Recebimento de Interiores com Assinatura Digital do Cliente
  void _showNovoTermoRecebimentoModal(BuildContext context, List<dynamic> punchList) {
    final nomeClienteController = TextEditingController();
    final docClienteController = TextEditingController();
    final responsavelTecnicoController = TextEditingController(text: 'Coordenação e Engenharia de Interiores');
    final ressalvasController = TextEditingController();
    String? assinaturaClienteBase64;

    final totalItens = punchList.length;
    final totalResolvidos = punchList.where((p) => p['status'] == 'RESOLVIDO').length;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Emitir Termo de Recebimento de Interiores'),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.fact_check, color: Color(0xFF4338CA)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Status da Vistoria: $totalResolvidos de $totalItens itens sanados no Punch List.\n'
                            '${totalResolvidos == totalItens ? "Tudo 100% resolvido sem ressalvas!" : "Atenção: existem pendências em aberto que constarão como ressalvas."}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: nomeClienteController, decoration: const InputDecoration(labelText: 'Nome do Cliente / Proprietário *')),
                  const SizedBox(height: 12),
                  TextField(controller: docClienteController, decoration: const InputDecoration(labelText: 'CPF ou RG do Cliente')),
                  const SizedBox(height: 12),
                  TextField(controller: responsavelTecnicoController, decoration: const InputDecoration(labelText: 'Responsável Técnico da Obra')),
                  const SizedBox(height: 12),
                  TextField(controller: ressalvasController, maxLines: 2, decoration: const InputDecoration(labelText: 'Ressalvas ou Acordos Especiais (Opcional)')),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Assinatura Digital do Cliente:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4338CA))),
                        const SizedBox(height: 6),
                        const Text('O cliente pode assinar diretamente na tela usando touch ou mouse.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final sig = await SignaturePadDialog.show(
                              context,
                              title: 'Assinatura do Cliente Final',
                              signerName: nomeClienteController.text.isNotEmpty ? nomeClienteController.text : 'Cliente Proprietário',
                              subtitle: 'Declaro ter vistoriado e recebido as instalações e marcenarias entregues.',
                            );
                            if (sig != null) {
                              setDialogState(() => assinaturaClienteBase64 = sig);
                            }
                          },
                          icon: Icon(assinaturaClienteBase64 != null ? Icons.check_circle : Icons.draw),
                          label: Text(assinaturaClienteBase64 != null ? 'Assinatura Coletada com Sucesso' : 'Coletar Assinatura Digital do Cliente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: assinaturaClienteBase64 != null ? Colors.green : const Color(0xFF4338CA),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nomeClienteController.text.isEmpty) return;
                await ref.read(gerenciamentoTerceirosProvider.notifier).createTermoRecebimento(widget.obraId, {
                  'nomeCliente': nomeClienteController.text,
                  'documentoCliente': docClienteController.text,
                  'responsavelTecnico': responsavelTecnicoController.text,
                  'ressalvasObservacoes': ressalvasController.text,
                  'assinaturaDigitalCliente': assinaturaClienteBase64,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Emitir Termo Definitivo'),
            ),
          ],
        ),
      ),
    );
  }

  // 6. Modal: Registrar Pendência do Punch List
  void _showNovoPunchItemModal(BuildContext context, List<dynamic> terceiros) {
    final ambienteController = TextEditingController();
    final descricaoController = TextEditingController();
    DateTime? prazoCorrecao;
    String? selectedTerceiroId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Registrar Pendência de Vistoria (Punch List)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: ambienteController, decoration: const InputDecoration(labelText: 'Ambiente (Ex: Cozinha Gourmet, Suíte Master) *')),
                const SizedBox(height: 12),
                TextField(controller: descricaoController, maxLines: 2, decoration: const InputDecoration(labelText: 'Descrição da Não-Conformidade *')),
                const SizedBox(height: 12),
                if (terceiros.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedTerceiroId,
                    decoration: const InputDecoration(labelText: 'Empresa Responsável'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Geral / Não atribuído')),
                      ...terceiros.map<DropdownMenuItem<String>>((t) {
                        return DropdownMenuItem<String>(value: t['id'], child: Text('${t['nomeEmpresa']} (${t['especialidade']})'));
                      }),
                    ],
                    onChanged: (val) => setDialogState(() => selectedTerceiroId = val),
                  ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Prazo para Correção'),
                  subtitle: Text(prazoCorrecao != null ? dateFormat.format(prazoCorrecao!) : 'Não definido'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 3)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => prazoCorrecao = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (ambienteController.text.isEmpty || descricaoController.text.isEmpty) return;
                await ref.read(gerenciamentoTerceirosProvider.notifier).createPunchItem(widget.obraId, {
                  'ambiente': ambienteController.text,
                  'descricao': descricaoController.text,
                  'terceiroClienteId': selectedTerceiroId,
                  'prazoCorrecao': prazoCorrecao?.toIso8601String(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}

