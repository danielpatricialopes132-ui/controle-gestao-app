import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/gerenciamento_terceiros_provider.dart';
import '../services/termo_portaria_pdf_service.dart';
import '../services/termo_retirada_pdf_service.dart';
import '../services/termo_recebimento_pdf_service.dart';
import 'widgets/signature_pad_dialog.dart';

class GerenciamentoTerceirosAba extends ConsumerStatefulWidget {
  final String obraId;
  final String obraNome;

  const GerenciamentoTerceirosAba({super.key, required this.obraId, required this.obraNome});

  @override
  ConsumerState<GerenciamentoTerceirosAba> createState() => _GerenciamentoTerceirosAbaState();
}

class _GerenciamentoTerceirosAbaState extends ConsumerState<GerenciamentoTerceirosAba> {
  int _modo = 0; // 0 = Empresas & Visitas, 1 = Portaria & Retirada de Itens, 2 = Vistorias & Recebimento
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
                  label: const Text('Novo Parceiro do Cliente'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white),
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
                  label: const Text('Cautela / Retirada de Itens'),
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
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? Center(child: Text('Erro: ${state.error}'))
                  : _modo == 0
                      ? _buildTerceirosView(state.terceiros, state.mapaVisitasSemanal)
                      : _modo == 1
                          ? _buildPortariaERetiradasView(state.portariaLiberacoes, state.termosRetirada)
                          : _buildPunchListView(state.punchList, state.termosRecebimento),
        ),
      ],
    );
  }

  // =========================================================================
  // --- SEÇÃO 1: EMPRESAS TERCEIRAS DO CLIENTE, ESTÁGIOS & MAPA SEMANAL ---
  // =========================================================================
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
                        backgroundColor: _getEspecialidadeColor(t['especialidade']).withOpacity(0.15),
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
                  // Barra de Progresso do Ciclo
                  Row(
                    children: [
                      Text('Estágio: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (idxEstagio + 1) / estagiosCiclo.length,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              idxEstagio == estagiosCiclo.length - 1 ? Colors.green : Colors.teal,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${idxEstagio + 1}/${estagiosCiclo.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (pendenciasAbertas > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.shade200)),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Text('$pendenciasAbertas pendência(s) no Punch List', style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else
                        Text('Sem pendências no checklist', style: TextStyle(color: Colors.green.shade700, fontSize: 11)),
                      const Spacer(),
                      if (idxEstagio > 0)
                        OutlinedButton(
                          onPressed: () {
                            final ant = estagiosCiclo[idxEstagio - 1];
                            ref.read(gerenciamentoTerceirosProvider.notifier).updateTerceiroStatus(widget.obraId, t['id'], ant);
                          },
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                          child: const Text('Voltar Etapa', style: TextStyle(fontSize: 11)),
                        ),
                      const SizedBox(width: 8),
                      if (idxEstagio < estagiosCiclo.length - 1)
                        ElevatedButton(
                          onPressed: () {
                            final prox = estagiosCiclo[idxEstagio + 1];
                            ref.read(gerenciamentoTerceirosProvider.notifier).updateTerceiroStatus(widget.obraId, t['id'], prox);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          child: Text('Avançar p/ ${_formatEstagioNome(estagiosCiclo[idxEstagio + 1])}', style: const TextStyle(fontSize: 11)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // Card Mapa Semanal S-T-Q-Q-S-S-D
  Widget _buildMapaVisitasSemanalCard(List<dynamic> mapaSemanal, List<dynamic> terceiros) {
    if (mapaSemanal.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.date_range, color: Colors.indigo, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MAPA SEMANAL DE VISITAS A OBRA (S, T, Q, Q, S, S, D)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                      Text('Acessos das empresas contratadas pelo cliente ao longo da semana',
                          style: TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showRegistrarVisitaModal(context, terceiros),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Apontar Entrada'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
                columnSpacing: 14,
                columns: const [
                  DataColumn(label: Text('Empresa / Especialidade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('S', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('T', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Q', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Q', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('S', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('S', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('D', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: mapaSemanal.map((item) {
                  final dias = item['dias'] as Map<String, dynamic>? ?? {};
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getEspecialidadeIcon(item['especialidade']), size: 16, color: _getEspecialidadeColor(item['especialidade'])),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item['nomeEmpresa'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text(item['especialidade'] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(_buildDiaVisitaBadge(dias['seg'] as List<dynamic>?)),
                      DataCell(_buildDiaVisitaBadge(dias['ter'] as List<dynamic>?)),
                      DataCell(_buildDiaVisitaBadge(dias['qua'] as List<dynamic>?)),
                      DataCell(_buildDiaVisitaBadge(dias['qui'] as List<dynamic>?)),
                      DataCell(_buildDiaVisitaBadge(dias['sex'] as List<dynamic>?)),
                      DataCell(_buildDiaVisitaBadge(dias['sab'] as List<dynamic>?)),
                      DataCell(_buildDiaVisitaBadge(dias['dom'] as List<dynamic>?)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.indigo.shade100, borderRadius: BorderRadius.circular(10)),
                          child: Text('${item['totalVisitasNaSemana'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.indigo)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaVisitaBadge(List<dynamic>? visitas) {
    if (visitas == null || visitas.isEmpty) {
      return Text('-', style: TextStyle(color: Colors.grey.shade400));
    }
    final total = visitas.length;
    final primeira = visitas.first;
    final motivo = primeira['motivo'] ?? 'Visita';

    return Tooltip(
      message: '$total visita(s): $motivo',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(6)),
        child: Text(
          total > 1 ? '$total x' : 'SIM',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // =========================================================================
  // --- SEÇÃO 2: PORTARIA & RETIRADA DE ITENS DA OBRA ---
  // =========================================================================
  Widget _buildPortariaERetiradasView(List<dynamic> portariaLiberacoes, List<dynamic> termosRetirada) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Card 1: Portaria Condominial ---
        Card(
          elevation: 2.5,
          margin: const EdgeInsets.only(bottom: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.badge, color: Color(0xFF1E3A8A), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CONTROLE DE PORTARIA & ACESSO DE CONDOMÍNIO',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                          Text('Emissão de termos de liberação formal para montadores e equipes de interiores',
                              style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (portariaLiberacoes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blueGrey, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Nenhuma autorização de portaria emitida. Clique no botão acima para liberar a entrada de montadores no condomínio.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...portariaLiberacoes.map((lib) {
                    final dataInicio = lib['dataInicio'] != null ? dateFormat.format(DateTime.parse(lib['dataInicio'])) : '-';
                    final dataFim = lib['dataFim'] != null ? dateFormat.format(DateTime.parse(lib['dataFim'])) : '-';
                    final colaboradores = (lib['colaboradores'] as List<dynamic>?) ?? [];

                    return Card(
                      color: Colors.blue.shade50.withOpacity(0.4),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.blue.shade100)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.security, color: Color(0xFF1E3A8A), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(lib['empresaNome'] ?? 'Empresa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                                        child: Text(lib['tipoAcesso'] ?? 'TERCEIRO_CLIENTE', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Período: $dataInicio até $dataFim | Horário: ${lib['horarioPermitido'] ?? '08:00 às 17:00'}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                                  if (lib['veiculoPlaca'] != null)
                                    Text('Veículo: ${lib['veiculoModelo'] ?? ''} (Placa: ${lib['veiculoPlaca']})',
                                        style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: colaboradores.map((c) {
                                      return Chip(
                                        avatar: const Icon(Icons.person, size: 12),
                                        label: Text('${c['nome']} (RG: ${c['rg']})', style: const TextStyle(fontSize: 10)),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => TermoPortariaPdfService.exportarTermo(
                                    nomeObra: widget.obraNome,
                                    enderecoObra: null,
                                    autorizacao: lib,
                                  ),
                                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                                  label: const Text('PDF Portaria'),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () {
                                    ref.read(gerenciamentoTerceirosProvider.notifier).deletePortariaLiberacao(widget.obraId, lib['id']);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),

        // --- Card 2: Termos de Retirada & Cautela de Itens ---
        Card(
          elevation: 2.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.outbox, color: Color(0xFF0F766E), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TERMO DE CAUTELA & RETIRADA DE ITENS DA OBRA',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                          Text('Controle e rastreio de cubas, portas ou metais retirados por marmorarias e marcenarias com assinatura digital',
                              style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (termosRetirada.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: Colors.teal, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Nenhum item em posse de terceiros fora da obra. Para liberar cubas para marmoraria ou peças para ajuste, clique no botão acima.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...termosRetirada.map((termo) {
                    final dataRetirada = termo['dataRetirada'] != null ? dateFormat.format(DateTime.parse(termo['dataRetirada'])) : '-';
                    final previsao = termo['previsaoDevolucao'] != null ? dateFormat.format(DateTime.parse(termo['previsaoDevolucao'])) : 'Sem data';
                    final isRetirado = termo['status'] == 'RETIRADO';
                    final itens = (termo['itensRetirados'] as List<dynamic>?) ?? [];

                    return Card(
                      color: isRetirado ? Colors.amber.shade50.withOpacity(0.5) : Colors.green.shade50.withOpacity(0.5),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isRetirado ? Colors.amber.shade200 : Colors.green.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(isRetirado ? Icons.timelapse : Icons.check_circle, color: isRetirado ? Colors.orange.shade800 : Colors.green.shade700, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(termo['numeroTermo'] ?? 'RET-000', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(width: 8),
                                      Text('Empresa: ${termo['empresaRetirante']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: isRetirado ? Colors.orange.shade100 : Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                        child: Text(termo['status'] ?? 'RETIRADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isRetirado ? Colors.orange.shade900 : Colors.green.shade900)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Retirado em: $dataRetirada | Previsão de Retorno: $previsao', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                                  Text('Responsável: ${termo['nomeResponsavelRetirada']} (Doc: ${termo['documentoResponsavel'] ?? 'N/I'})', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: itens.map((it) {
                                      return Chip(
                                        backgroundColor: Colors.white,
                                        label: Text('${it['quantidade']}x ${it['item']} (${it['estadoConservacao'] ?? 'OK'})', style: const TextStyle(fontSize: 10)),
                                        visualDensity: VisualDensity.compact,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => TermoRetiradaPdfService.exportarTermo(
                                    nomeObra: widget.obraNome,
                                    enderecoObra: null,
                                    termo: termo,
                                  ),
                                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                                  label: const Text('PDF Cautela'),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                ),
                                const SizedBox(height: 6),
                                if (isRetirado)
                                  OutlinedButton(
                                    onPressed: () {
                                      ref.read(gerenciamentoTerceirosProvider.notifier).registrarDevolucaoRetirada(widget.obraId, termo['id'], 'DEVOLVIDO_TOTAL');
                                    },
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                    child: const Text('Baixar Devolução', style: TextStyle(fontSize: 11, color: Colors.green)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // --- SEÇÃO 3: VISTORIAS, PUNCH LIST & TERMO DE RECEBIMENTO ---
  // =========================================================================
  Widget _buildPunchListView(List<dynamic> punchList, List<dynamic> termosRecebimento) {
    final totalVistoriados = punchList.length;
    final totalResolvidos = punchList.where((p) => p['status'] == 'RESOLVIDO').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card de Auditoria e Termos de Recebimento Emitidos
        Card(
          elevation: 2.5,
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.verified, color: Color(0xFF4338CA), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AUDITORIA DE ENTREGA & RECEBIMENTO DE INTERIORES',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                          Text('Saneamento do checklist de qualidade: $totalResolvidos de $totalVistoriados itens resolvidos',
                              style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showNovoTermoRecebimentoModal(context, punchList),
                      icon: const Icon(Icons.draw, size: 16),
                      label: const Text('Emitir Termo com Assinatura'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4338CA), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    ),
                  ],
                ),
                if (termosRecebimento.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Termos de Recebimento Assinados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  ...termosRecebimento.map((rec) {
                    final dataEmissao = rec['dataEmissao'] != null ? dateFormat.format(DateTime.parse(rec['dataEmissao'])) : '-';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text('${rec['numeroTermo']} - ${rec['nomeCliente']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 8),
                          Text('($dataEmissao)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => TermoRecebimentoPdfService.exportarTermo(
                              nomeObra: widget.obraNome,
                              enderecoObra: null,
                              termo: rec,
                            ),
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: const Text('Exportar Certidão PDF'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF4338CA)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),

        const Padding(
          padding: EdgeInsets.only(bottom: 12, top: 4),
          child: Text('Itens do Checklist de Vistoria / Punch List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),

        if (punchList.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.task_alt, size: 48, color: Colors.green.shade400),
                  const SizedBox(height: 12),
                  const Text('Nenhuma pendência ou não-conformidade registrada.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
            ),
          )
        else
          ...punchList.map((p) {
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
          }),
      ],
    );
  }

  // --- HELPERS DE ESTILIZAÇÃO ---
  Widget _buildStatusEstagioChip(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;

    switch (status) {
      case 'CONTRATADO': bg = Colors.blue.shade100; fg = Colors.blue.shade900; break;
      case 'MEDICAO_IN_LOCO': bg = Colors.purple.shade100; fg = Colors.purple.shade900; break;
      case 'FABRICACAO': bg = Colors.amber.shade100; fg = Colors.amber.shade900; break;
      case 'PRONTO_ENTREGA': bg = Colors.orange.shade100; fg = Colors.orange.shade900; break;
      case 'MONTAGEM': bg = Colors.teal.shade100; fg = Colors.teal.shade900; break;
      case 'ENTREGUE_APROVADO': bg = Colors.green.shade100; fg = Colors.green.shade900; break;
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

  // =========================================================================
  // --- MODAIS DE CADASTRO E ASSINATURA DIGITAL ---
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
