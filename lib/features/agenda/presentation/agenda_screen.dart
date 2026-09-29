import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/agenda_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'novo_evento_dialog.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(agendaFiltroProvider);
    final eventosAsync = ref.watch(agendaEventosProvider);
    final usuarioLogado = ref.watch(appUserProvider);
    final meuUserId = usuarioLogado?['id'];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.calendar_month, size: 24),
            SizedBox(width: 8),
            Text('Agenda de Compromissos', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(agendaEventosProvider),
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => _importarIcs(context, ref),
            tooltip: 'Importar convite .ics / iCal',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const NovoEventoDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo Compromisso'),
      ),
      body: Column(
        children: [
          // FILTRO: TODOS / PROFISSIONAL / PESSOAL
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'TODOS',
                        label: Text('Todos'),
                        icon: Icon(Icons.view_agenda_outlined),
                      ),
                      ButtonSegment(
                        value: 'PROFISSIONAL',
                        label: Text('Profissional'),
                        icon: Icon(Icons.business_center_outlined),
                      ),
                      ButtonSegment(
                        value: 'PESSOAL',
                        label: Text('Pessoal'),
                        icon: Icon(Icons.person_outline),
                      ),
                    ],
                    selected: {filtro.tipo},
                    onSelectionChanged: (set) {
                      ref.read(agendaFiltroProvider.notifier).mudarTipo(set.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // LISTA DE EVENTOS
          Expanded(
            child: eventosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erro ao carregar agenda: $err')),
              data: (eventos) {
                if (eventos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum compromisso agendado',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use a Agenda Inteligente ou crie um novo evento.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => const NovoEventoDialog(),
                          ),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Agendar com IA'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final ev = eventos[index];
                    final isPessoal = ev.tipo == 'PESSOAL';

                    // Busca se eu sou convidado e status do convite
                    final meuConvite = ev.participantes.where((p) => p.usuarioId == meuUserId).firstOrNull;
                    final convitePendente = meuConvite != null && meuConvite.statusConvite == 'PENDENTE';

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isPessoal ? Colors.purple.shade200 : Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: isPessoal ? Colors.purple.shade50 : Colors.blue.shade50,
                                  label: Text(
                                    isPessoal ? 'Pessoal' : 'Profissional',
                                    style: TextStyle(
                                      color: isPessoal ? Colors.purple.shade800 : Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (ev.obraNome != null) ...[
                                  const SizedBox(width: 6),
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: Colors.orange.shade50,
                                    label: Text(
                                      'Obra: ${ev.obraNome}',
                                      style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                Text(
                                  _formatarDataHora(ev.dataInicio, ev.dataFim),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ev.titulo,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (ev.descricao != null && ev.descricao!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(ev.descricao!, style: TextStyle(color: Colors.grey.shade700)),
                            ],
                            if (ev.local != null && ev.local!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      ev.local!,
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // LISTAGEM DE PARTICIPANTES / CONVITES
                            if (ev.participantes.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Divider(height: 16),
                              Text(
                                'Participantes (${ev.participantes.length}):',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: ev.participantes.map((p) {
                                  Color badgeCor = Colors.grey.shade200;
                                  Color textoCor = Colors.black87;
                                  IconData icone = Icons.hourglass_top;

                                  if (p.statusConvite == 'ACEITO') {
                                    badgeCor = Colors.green.shade100;
                                    textoCor = Colors.green.shade900;
                                    icone = Icons.check_circle_outline;
                                  } else if (p.statusConvite == 'RECUSADO') {
                                    badgeCor = Colors.red.shade100;
                                    textoCor = Colors.red.shade900;
                                    icone = Icons.cancel_outlined;
                                  }

                                  return Chip(
                                    avatar: Icon(icone, size: 14, color: textoCor),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: badgeCor,
                                    label: Text(
                                      '${p.nome ?? p.email ?? "Membro"} (${p.statusConvite})',
                                      style: TextStyle(fontSize: 11, color: textoCor),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],

                            // SE CONVITE ESTIVER PENDENTE PARA O USUÁRIO ATUAL
                            if (convitePendente) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Você foi convidado para esta reunião. Deseja participar?',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.check, color: Colors.green, size: 16),
                                      label: const Text('Aceitar', style: TextStyle(color: Colors.green)),
                                      onPressed: () {
                                        ref
                                            .read(agendaActionsProvider)
                                            .responderConvite(ev.id, 'ACEITO');
                                      },
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.close, color: Colors.red, size: 16),
                                      label: const Text('Recusar', style: TextStyle(color: Colors.red)),
                                      onPressed: () {
                                        ref
                                            .read(agendaActionsProvider)
                                            .responderConvite(ev.id, 'RECUSADO');
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _importarIcs(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ics'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final bytes = result.files.first.bytes;
      if (bytes != null) {
        final content = utf8.decode(bytes);
        try {
          final total = await ref.read(agendaActionsProvider).importarIcs(content);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ $total compromisso(s) importado(s) com sucesso!')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao importar convite .ics: $e')),
            );
          }
        }
      }
    }
  }

  String _formatarDataHora(DateTime inicio, DateTime fim) {
    return '${inicio.day.toString().padLeft(2, '0')}/${inicio.month.toString().padLeft(2, '0')} '
        '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')} - '
        '${fim.hour.toString().padLeft(2, '0')}:${fim.minute.toString().padLeft(2, '0')}';
  }
}
