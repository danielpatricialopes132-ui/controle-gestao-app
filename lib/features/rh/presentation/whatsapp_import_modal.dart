import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/ponto_provider.dart';
import '../providers/rh_provider.dart';
import './widgets/dialog_cadastro_rapido.dart';

class WhatsAppImportModal extends ConsumerStatefulWidget {
  const WhatsAppImportModal({super.key});

  @override
  ConsumerState<WhatsAppImportModal> createState() => _WhatsAppImportModalState();
}

class _WhatsAppImportModalState extends ConsumerState<WhatsAppImportModal> {
  final _textController = TextEditingController();
  bool _isParsed = false;
  bool _isLoading = false;
  
  String? _importedObraId;
  List<dynamic> _funcionariosGlobais = [];
  List<dynamic> _obras = [];
  
  List<Map<String, dynamic>> _parsedDays = [];
  List<String> _naoReconhecidos = [];

  @override
  void initState() {
    super.initState();
    // Carregar funcionarios e obras
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final res = await ref.read(pontoDataFuturoProvider(PontoParams(dataStr: DateFormat('yyyy-MM-dd').format(DateTime.now()))).future);
      setState(() {
        _funcionariosGlobais = res['funcionarios'] ?? [];
        _obras = res['obras'] ?? [];
      });
    });
  }

  Future<void> _parseText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (_importedObraId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma obra primeiro!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ref.read(pontoControllerProvider.notifier).analisarTextoEscala(text, _importedObraId!);
      
      final dias = res['dias'] as List;
      final naoReconhecidos = (res['naoReconhecidos'] as List).map((e) => e.toString()).toList();
      
      List<Map<String, dynamic>> finalDays = dias.map((d) {
        return {
          'dataStr': d['dataStr'],
          'rows': (d['reconhecidos'] as List).map((r) => {
            'funcionarioId': r['funcionarioId'],
            'nome': r['nomeEncontrado'],
            'cargo': '', // Pode não vir
            'tipoDia': r['status'],
            'horasTrabalhadas': r['horasTrabalhadas'].toString(),
            'percentualPago': r['percentualPago'].toString(),
            'observacoes': r['observacao'] ?? '',
          }).toList(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _parsedDays = finalDays;
          _naoReconhecidos = naoReconhecidos;
          _isParsed = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na IA: $e')));
      }
    }
  }

  Future<void> _salvarLote() async {
    if (_importedObraId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecione uma obra.')));
      return;
    }

    final dias = _parsedDays.map((d) => {
      'dataStr': d['dataStr'],
      'entries': d['rows'].map((r) => {
        'funcionarioId': r['funcionarioId'],
        'tipoDia': r['tipoDia'],
        'horasTrabalhadas': double.tryParse(r['horasTrabalhadas']) ?? 0,
        'percentualPago': double.tryParse(r['percentualPago']) ?? 100,
        'observacoes': r['observacoes'],
      }).toList()
    }).toList();

    try {
      await ref.read(pontoControllerProvider.notifier).salvarLoteWhatsapp(_importedObraId!, dias);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lote salvo com sucesso!')));
        Navigator.pop(context);
        ref.invalidate(pontoDataFuturoProvider);
        ref.invalidate(pontosPendentesProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(pontoControllerProvider) is AsyncLoading;

    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Importar Escala via WhatsApp', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            if (!_isParsed) ...[
              DropdownButtonFormField<String>(
                initialValue: _importedObraId,
                decoration: const InputDecoration(labelText: 'Obra Associada (Obrigatório)', border: OutlineInputBorder()),
                items: _obras.map((o) => DropdownMenuItem<String>(value: o['id'], child: Text(o['nome']))).toList(),
                onChanged: (val) => setState(() => _importedObraId = val),
              ),
              const SizedBox(height: 16),
              const Text('Cole o texto da escala recebida abaixo:'),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _parseText,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Analisar com IA'),
                ),
              )
            ] else ...[
              if (_naoReconhecidos.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pessoas não encontradas no sistema:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                      const SizedBox(height: 4),
                      ..._naoReconhecidos.map((nr) => Text('- $nr', style: const TextStyle(color: Colors.deepOrange))),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final firstNr = _naoReconhecidos.isNotEmpty ? _naoReconhecidos.first : '';
                          final success = await showDialog<bool>(
                            context: context,
                            builder: (_) => DialogCadastroRapido(nomeInicial: firstNr),
                          );
                          if (success == true) {
                            setState(() {
                              if (_naoReconhecidos.isNotEmpty) {
                                _naoReconhecidos.remove(firstNr);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Colaborador cadastrado! Atualize a análise se desejar inclui-lo no ponto.')));
                            });
                          }
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Cadastrar Novo(s)'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text('Obra Selecionada', style: Theme.of(context).textTheme.titleMedium),
              Text(_obras.firstWhere((o) => o['id'] == _importedObraId, orElse: () => {'nome': ''})['nome']),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _parsedDays.length,
                  itemBuilder: (context, index) {
                    final day = _parsedDays[index];
                    return ExpansionTile(
                      title: Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(day['dataStr']))),
                      initiallyExpanded: true,
                      children: (day['rows'] as List).map<Widget>((r) {
                        return ListTile(
                          title: Text(r['nome']),
                          subtitle: Text(r['cargo']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<String>(
                                value: r['tipoDia'],
                                items: const [
                                  DropdownMenuItem(value: 'TRABALHO', child: Text('Trabalho')),
                                  DropdownMenuItem(value: 'NA', child: Text('N/A')),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    r['tipoDia'] = val;
                                    r['horasTrabalhadas'] = val == 'TRABALHO' ? '8' : '0';
                                  });
                                },
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _isParsed = false),
                    child: const Text('Voltar e Editar Texto'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: isSaving ? null : _salvarLote,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmar e Salvar Lote'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  )
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}
