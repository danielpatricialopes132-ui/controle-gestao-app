// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../providers/agenda_provider.dart';

class NovoEventoDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? dadosPreenchidos;

  const NovoEventoDialog({super.key, this.dadosPreenchidos});

  @override
  ConsumerState<NovoEventoDialog> createState() => _NovoEventoDialogState();
}

class _NovoEventoDialogState extends ConsumerState<NovoEventoDialog> {
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _localController = TextEditingController();
  final _promptIaController = TextEditingController();

  String _tipo = 'PROFISSIONAL';
  DateTime _dataInicio = DateTime.now().add(const Duration(hours: 1));
  DateTime _dataFim = DateTime.now().add(const Duration(hours: 2));
  final bool _diaInteiro = false;
  String? _obraId;

  List<dynamic> _usuarios = [];
  List<dynamic> _obras = [];
  final Set<String> _participantesSelecionados = {};
  bool _carregandoIa = false;

  @override
  void initState() {
    super.initState();
    _carregarAuxiliares();
    if (widget.dadosPreenchidos != null) {
      _aplicarDadosIa(widget.dadosPreenchidos!);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _localController.dispose();
    _promptIaController.dispose();
    super.dispose();
  }

  void _carregarAuxiliares() async {
    try {
      final api = ref.read(apiClientProvider);
      final usersRes = await api.get('/admin/users');
      final obrasRes = await api.get('/obras');
      if (mounted) {
        setState(() {
          _usuarios = usersRes is List ? usersRes : (usersRes['users'] ?? []);
          _obras = obrasRes is List ? obrasRes : (obrasRes['obras'] ?? []);
        });
      }
    } catch (_) {}
  }

  void _aplicarDadosIa(Map<String, dynamic> dados) {
    if (dados['titulo'] != null) _tituloController.text = dados['titulo'];
    if (dados['descricao'] != null) _descricaoController.text = dados['descricao'];
    if (dados['local'] != null) _localController.text = dados['local'];
    if (dados['tipo'] != null) _tipo = dados['tipo'];
    if (dados['obraId'] != null) _obraId = dados['obraId'];
    if (dados['dataInicio'] != null) {
      _dataInicio = DateTime.tryParse(dados['dataInicio']) ?? _dataInicio;
    }
    if (dados['dataFim'] != null) {
      _dataFim = DateTime.tryParse(dados['dataFim']) ?? _dataFim;
    }
    if (dados['participantesIds'] is List) {
      for (var id in dados['participantesIds']) {
        _participantesSelecionados.add(id.toString());
      }
    }
    setState(() {});
  }

  void _processarComIa() async {
    final texto = _promptIaController.text.trim();
    if (texto.isEmpty) return;

    setState(() => _carregandoIa = true);
    try {
      final dados = await ref.read(agendaActionsProvider).interpretarAgendaInteligente(texto);
      _aplicarDadosIa(dados);
      _promptIaController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ IA interpretou e preencheu o compromisso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na IA: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _carregandoIa = false);
    }
  }

  void _salvar() async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o título do compromisso.')),
      );
      return;
    }

    final payload = {
      'titulo': titulo,
      'descricao': _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
      'local': _localController.text.trim().isEmpty ? null : _localController.text.trim(),
      'tipo': _tipo,
      'dataInicio': _dataInicio.toIso8601String(),
      'dataFim': _dataFim.toIso8601String(),
      'diaInteiro': _diaInteiro,
      'obraId': _obraId,
      'participantes': _participantesSelecionados.map((id) => {'usuarioId': id}).toList(),
      'lembretes': [15],
    };

    try {
      await ref.read(agendaActionsProvider).criarEvento(payload);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar evento: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 540,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.event, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Novo Compromisso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // CAMPO DA AGENDA INTELIGENTE COM IA
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.blue, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Agenda Inteligente (Preenchimento por IA)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promptIaController,
                            decoration: const InputDecoration(
                              hintText: 'Ex: "Reunião de alinhamento com engenheiro amanhã às 14h na Obra Alphaville"',
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _processarComIa(),
                          ),
                        ),
                        _carregandoIa
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Icons.send, color: Colors.blue),
                                onPressed: _processarComIa,
                                tooltip: 'Interpretar com IA',
                              ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // SELETOR TIPO (PROFISSIONAL / PESSOAL)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'PROFISSIONAL',
                    label: Text('Profissional'),
                    icon: Icon(Icons.work_outline),
                  ),
                  ButtonSegment(
                    value: 'PESSOAL',
                    label: Text('Pessoal'),
                    icon: Icon(Icons.person_outline),
                  ),
                ],
                selected: {_tipo},
                onSelectionChanged: (val) => setState(() => _tipo = val.first),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título do Compromisso *',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, size: 20),
                      title: const Text('Início', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(
                        '${_dataInicio.day}/${_dataInicio.month} ${_dataInicio.hour.toString().padLeft(2, '0')}:${_dataInicio.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () async {
                        final data = await showDatePicker(
                          context: context,
                          initialDate: _dataInicio,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (data == null) return;
                        if (!mounted) return;
                        final hora = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_dataInicio),
                        );
                        if (hora != null && mounted) {
                          setState(() {
                            _dataInicio = DateTime(
                              data.year,
                              data.month,
                              data.day,
                              hora.hour,
                              hora.minute,
                            );
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, size: 20),
                      title: const Text('Fim', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(
                        '${_dataFim.day}/${_dataFim.month} ${_dataFim.hour.toString().padLeft(2, '0')}:${_dataFim.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () async {
                        final data = await showDatePicker(
                          context: context,
                          initialDate: _dataFim,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (data == null) return;
                        if (!mounted) return;
                        final hora = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_dataFim),
                        );
                        if (hora != null && mounted) {
                          setState(() {
                            _dataFim = DateTime(
                              data.year,
                              data.month,
                              data.day,
                              hora.hour,
                              hora.minute,
                            );
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _localController,
                decoration: const InputDecoration(
                  labelText: 'Local ou Link da Reunião',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),

              if (_tipo == 'PROFISSIONAL') ...[
                if (_obras.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Vincular à Obra (Opcional)',
                      prefixIcon: Icon(Icons.apartment),
                    ),
                    initialValue: _obraId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Nenhuma Obra')),
                      ..._obras.map((o) => DropdownMenuItem(
                            value: o['id'].toString(),
                            child: Text(o['nome'] ?? 'Obra'),
                          )),
                    ],
                    onChanged: (val) => setState(() => _obraId = val),
                  ),
                  const SizedBox(height: 12),
                ],

                const Text('Convidar Membros da Equipe:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _usuarios.map((u) {
                    final isSel = _participantesSelecionados.contains(u['id']);
                    return FilterChip(
                      label: Text(u['nome'] ?? ''),
                      selected: isSel,
                      onSelected: (sel) {
                        setState(() {
                          if (sel) {
                            _participantesSelecionados.add(u['id']);
                          } else {
                            _participantesSelecionados.remove(u['id']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                controller: _descricaoController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descrição / Pauta',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _salvar,
                  icon: const Icon(Icons.check),
                  label: const Text('Salvar Compromisso'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
