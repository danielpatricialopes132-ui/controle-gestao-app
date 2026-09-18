import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/rh_provider.dart';
import '../../../obras/providers/obras_provider.dart';

class ValeModal {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _ValeForm(),
    );
  }
}

class _ValeForm extends ConsumerStatefulWidget {
  const _ValeForm();

  @override
  ConsumerState<_ValeForm> createState() => _ValeFormState();
}

class _ValeFormState extends ConsumerState<_ValeForm> {
  final _formKey = GlobalKey<FormState>();
  String? _funcionarioSelecionado;
  String? _obraSelecionada;
  late TextEditingController _valorController;
  late TextEditingController _descricaoController;

  @override
  void initState() {
    super.initState();
    _valorController = TextEditingController();
    _descricaoController = TextEditingController(text: 'Adiantamento');
  }

  void _salvar() async {
    if (_formKey.currentState!.validate() && _funcionarioSelecionado != null && _obraSelecionada != null) {
      final data = {
        'funcionarioId': _funcionarioSelecionado,
        'obraId': _obraSelecionada,
        'valor': double.parse(_valorController.text.replaceAll(',', '.')),
        'descricao': _descricaoController.text,
      };

      try {
        await ref.read(rhControllerProvider.notifier).addVale(data);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vale gerado com sucesso!')));
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
    final funcAsync = ref.watch(funcionariosProvider);
    final obrasAsync = ref.watch(obrasProvider);

    return AlertDialog(
      title: const Text('Novo Vale / Adiantamento'),
      content: funcAsync.when(
        loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
        error: (e, st) => Text('Erro: $e'),
        data: (funcionarios) => obrasAsync.when(
          loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
          error: (e, st) => Text('Erro obras: $e'),
          data: (obras) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _funcionarioSelecionado,
                      decoration: const InputDecoration(labelText: 'Colaborador'),
                      items: funcionarios.map<DropdownMenuItem<String>>((f) => DropdownMenuItem(
                        value: f['id'],
                        child: Text('${f['nome']} (${f['tipoColaborador']})'),
                      )).toList(),
                      onChanged: (val) => setState(() => _funcionarioSelecionado = val),
                      validator: (val) => val == null ? 'Obrigatório' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: _obraSelecionada,
                      decoration: const InputDecoration(labelText: 'Obra de Custo'),
                      items: obras.map<DropdownMenuItem<String>>((o) => DropdownMenuItem(
                        value: o['id'],
                        child: Text(o['nome']),
                      )).toList(),
                      onChanged: (val) => setState(() => _obraSelecionada = val),
                      validator: (val) => val == null ? 'Obrigatório' : null,
                    ),
                    TextFormField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                      validator: (val) => val == null || val.isEmpty ? 'Obrigatório' : null,
                    ),
                    TextFormField(
                      controller: _valorController,
                      decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Obrigatório' : null,
                    ),
                  ],
                ),
              ),
            );
          }
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _salvar, child: const Text('Gerar Vale')),
      ],
    );
  }
}
