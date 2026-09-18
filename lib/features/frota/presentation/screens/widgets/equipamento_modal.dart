import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/frota_provider.dart';

class EquipamentoModal {
  static void show(BuildContext context, {Map<String, dynamic>? equipamento}) {
    showDialog(
      context: context,
      builder: (ctx) => _EquipamentoForm(equipamento: equipamento),
    );
  }
}

class _EquipamentoForm extends ConsumerStatefulWidget {
  final Map<String, dynamic>? equipamento;

  const _EquipamentoForm({this.equipamento});

  @override
  ConsumerState<_EquipamentoForm> createState() => _EquipamentoFormState();
}

class _EquipamentoFormState extends ConsumerState<_EquipamentoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _identificadorController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _anoController;
  late TextEditingController _custoDiarioController;

  @override
  void initState() {
    super.initState();
    _identificadorController = TextEditingController(text: widget.equipamento?['identificador'] ?? '');
    _marcaController = TextEditingController(text: widget.equipamento?['marca'] ?? '');
    _modeloController = TextEditingController(text: widget.equipamento?['modelo'] ?? '');
    _anoController = TextEditingController(text: widget.equipamento?['ano']?.toString() ?? '');
    _custoDiarioController = TextEditingController(text: widget.equipamento?['custoDiario']?.toString() ?? '0');
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'identificador': _identificadorController.text,
        'marca': _marcaController.text,
        'modelo': _modeloController.text,
        'ano': _anoController.text.isNotEmpty ? int.parse(_anoController.text) : null,
        'custoDiario': double.tryParse(_custoDiarioController.text.replaceAll(',', '.')) ?? 0.0,
      };

      try {
        if (widget.equipamento == null) {
          await ref.read(frotaControllerProvider.notifier).addEquipamento(data);
        } else {
          await ref.read(frotaControllerProvider.notifier).updateEquipamento(widget.equipamento!['id'], data);
        }
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvo com sucesso!')));
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
    return AlertDialog(
      title: Text(widget.equipamento == null ? 'Novo Equipamento' : 'Editar Equipamento'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _identificadorController,
                decoration: const InputDecoration(labelText: 'Identificador / Placa'),
                validator: (val) => val == null || val.isEmpty ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(labelText: 'Marca'),
              ),
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(labelText: 'Modelo'),
              ),
              TextFormField(
                controller: _anoController,
                decoration: const InputDecoration(labelText: 'Ano'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _custoDiarioController,
                decoration: const InputDecoration(labelText: 'Custo Diário (R\$)'),
                keyboardType: TextInputType.number,
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
