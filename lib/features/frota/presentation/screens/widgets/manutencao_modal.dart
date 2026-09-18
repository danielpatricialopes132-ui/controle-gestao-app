import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/frota_provider.dart';
import 'package:intl/intl.dart';

class ManutencaoModal {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _ManutencaoForm(),
    );
  }
}

class _ManutencaoForm extends ConsumerStatefulWidget {
  const _ManutencaoForm();

  @override
  ConsumerState<_ManutencaoForm> createState() => _ManutencaoFormState();
}

class _ManutencaoFormState extends ConsumerState<_ManutencaoForm> {
  final _formKey = GlobalKey<FormState>();
  String? _equipamentoSelecionado;
  late TextEditingController _descricaoController;
  late TextEditingController _dataController;
  late TextEditingController _custoController;

  @override
  void initState() {
    super.initState();
    _descricaoController = TextEditingController();
    _dataController = TextEditingController();
    _custoController = TextEditingController(text: '0');
  }

  void _salvar() async {
    if (_formKey.currentState!.validate() && _equipamentoSelecionado != null) {
      final parts = _dataController.text.split('/');
      final dataIso = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0])).toIso8601String();

      final data = {
        'equipamentoId': _equipamentoSelecionado,
        'dataProgramada': dataIso,
        'descricao': _descricaoController.text,
        'custoEstimado': double.tryParse(_custoController.text.replaceAll(',', '.')) ?? 0.0,
      };

      try {
        await ref.read(frotaControllerProvider.notifier).addManutencao(data);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manutenção agendada!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipAsync = ref.watch(equipamentosProvider);

    return AlertDialog(
      title: const Text('Agendar Manutenção'),
      content: equipAsync.when(
        loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
        error: (e, st) => Text('Erro: $e'),
        data: (equipamentos) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _equipamentoSelecionado,
                    decoration: const InputDecoration(labelText: 'Equipamento', border: OutlineInputBorder()),
                    items: equipamentos.map<DropdownMenuItem<String>>((e) => DropdownMenuItem(
                      value: e['id'],
                      child: Text('${e['identificador']} - ${e['modelo'] ?? ''}'),
                    )).toList(),
                    onChanged: (val) => setState(() => _equipamentoSelecionado = val),
                    validator: (val) => val == null ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dataController,
                    decoration: const InputDecoration(labelText: 'Data Programada (DD/MM/AAAA)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.datetime,
                    validator: (val) => val == null || val.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(labelText: 'Descrição (ex: Troca de óleo)', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _custoController,
                    decoration: const InputDecoration(labelText: 'Custo Estimado (R\$)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          );
        }
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
