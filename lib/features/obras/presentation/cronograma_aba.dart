import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/obra_ged_provider.dart';

class CronogramaAba extends ConsumerStatefulWidget {
  final String obraId;
  const CronogramaAba({super.key, required this.obraId});

  @override
  ConsumerState<CronogramaAba> createState() => _CronogramaAbaState();
}

class _CronogramaAbaState extends ConsumerState<CronogramaAba> {
  void _mostrarModalNovaEtapa() {
    showDialog(
      context: context,
      builder: (ctx) => _NovaEtapaModal(obraId: widget.obraId),
    );
  }

  void _atualizarPercentual(String etapaId, double valorAtual) {
    showDialog(
      context: context,
      builder: (ctx) {
        double novoValor = valorAtual;
        return AlertDialog(
          title: const Text('Atualizar Conclusão'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Progresso: ${novoValor.toInt()}%'),
              StatefulBuilder(
                builder: (context, setState) {
                  return Slider(
                    value: novoValor,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${novoValor.toInt()}%',
                    onChanged: (val) {
                      setState(() => novoValor = val);
                    },
                  );
                }
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(obraGedControllerProvider.notifier).updateEtapaPercentual(widget.obraId, etapaId, novoValor);
                  ref.invalidate(cronogramaObraProvider(widget.obraId));
                  if (mounted) {
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final cronoAsync = ref.watch(cronogramaObraProvider(widget.obraId));

    return Scaffold(
      body: cronoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro: $e')),
        data: (etapas) {
          if (etapas.isEmpty) {
            return const Center(child: Text('Nenhuma etapa do cronograma cadastrada.'));
          }

          return ListView.builder(
            itemCount: etapas.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (ctx, i) {
              final etapa = etapas[i];
              final dataInicio = DateTime.parse(etapa['dataInicioEstimada']);
              final dataFim = DateTime.parse(etapa['dataFimEstimada']);
              final percentual = double.parse(etapa['percentualConclusao'].toString());

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(etapa['nome'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${percentual.toInt()}% Concluído', style: TextStyle(color: percentual == 100 ? Colors.green : Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Período: ${DateFormat('dd/MM/yyyy').format(dataInicio)} a ${DateFormat('dd/MM/yyyy').format(dataFim)}'),
                      Text('Custo Previsto: R\$ ${double.parse(etapa['custoPrevisto'].toString()).toStringAsFixed(2)}'),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: percentual / 100,
                        backgroundColor: Colors.grey[300],
                        color: percentual == 100 ? Colors.green : Colors.blue,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _atualizarPercentual(etapa['id'], percentual),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Atualizar Progresso'),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarModalNovaEtapa,
        label: const Text('Nova Etapa'),
        icon: const Icon(Icons.add_task),
      ),
    );
  }
}

class _NovaEtapaModal extends ConsumerStatefulWidget {
  final String obraId;
  const _NovaEtapaModal({required this.obraId});

  @override
  ConsumerState<_NovaEtapaModal> createState() => _NovaEtapaModalState();
}

class _NovaEtapaModalState extends ConsumerState<_NovaEtapaModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _custoController;
  DateTime _inicio = DateTime.now();
  DateTime _fim = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _custoController = TextEditingController(text: '0');
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'nome': _nomeController.text,
        'dataInicioEstimada': _inicio.toIso8601String(),
        'dataFimEstimada': _fim.toIso8601String(),
        'custoPrevisto': double.parse(_custoController.text.replaceAll(',', '.')),
        'percentualConclusao': 0,
      };

      try {
        await ref.read(obraGedControllerProvider.notifier).saveEtapaCronograma(widget.obraId, data);
        ref.invalidate(cronogramaObraProvider(widget.obraId));
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Etapa do Cronograma'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome da Etapa (ex: Fundações)'),
                validator: (val) => val == null || val.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: _inicio, firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if (d != null) setState(() => _inicio = d);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Início'),
                        child: Text(DateFormat('dd/MM/yyyy').format(_inicio)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: _fim, firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if (d != null) setState(() => _fim = d);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fim Previsto'),
                        child: Text(DateFormat('dd/MM/yyyy').format(_fim)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _custoController,
                decoration: const InputDecoration(labelText: 'Custo Previsto (R\$)'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Obrigatório' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
