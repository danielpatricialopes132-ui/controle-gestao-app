import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/rh_provider.dart';

class FuncionarioModal {
  static void show(BuildContext context, {Map<String, dynamic>? funcionario}) {
    showDialog(
      context: context,
      builder: (ctx) => _FuncionarioForm(funcionario: funcionario),
    );
  }
}

class _FuncionarioForm extends ConsumerStatefulWidget {
  final Map<String, dynamic>? funcionario;

  const _FuncionarioForm({this.funcionario});

  @override
  ConsumerState<_FuncionarioForm> createState() => _FuncionarioFormState();
}

class _FuncionarioFormState extends ConsumerState<_FuncionarioForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _cargoController;
  late TextEditingController _cpfCnpjController;
  late TextEditingController _chavePixController;
  late TextEditingController _salarioController;
  late TextEditingController _valorDiariaController;

  String _tipoColaborador = 'CLT';
  String _tipoPagamento = 'MENSAL';

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.funcionario?['nome'] ?? '');
    _cargoController = TextEditingController(text: widget.funcionario?['cargo'] ?? '');
    _cpfCnpjController = TextEditingController(text: widget.funcionario?['cpfCnpj'] ?? '');
    _chavePixController = TextEditingController(text: widget.funcionario?['chavePix'] ?? '');
    _salarioController = TextEditingController(text: widget.funcionario?['salario']?.toString() ?? '');
    _valorDiariaController = TextEditingController(text: widget.funcionario?['valorDiaria']?.toString() ?? '');
    
    if (widget.funcionario != null) {
      _tipoColaborador = widget.funcionario!['tipoColaborador'] ?? 'CLT';
      _tipoPagamento = widget.funcionario!['tipoPagamento'] ?? 'MENSAL';
    }
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'nome': _nomeController.text,
        'cargo': _cargoController.text,
        'tipoColaborador': _tipoColaborador,
        'cpfCnpj': _cpfCnpjController.text,
        'chavePix': _chavePixController.text,
        'salario': _salarioController.text.isNotEmpty ? double.parse(_salarioController.text.replaceAll(',', '.')) : null,
        'valorDiaria': _valorDiariaController.text.isNotEmpty ? double.parse(_valorDiariaController.text.replaceAll(',', '.')) : null,
        'tipoPagamento': _tipoPagamento,
      };

      try {
        await ref.read(rhControllerProvider.notifier).saveFuncionario(data, id: widget.funcionario?['id']);
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
      title: Text(widget.funcionario == null ? 'Novo Colaborador' : 'Editar Colaborador'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _tipoColaborador,
                decoration: const InputDecoration(labelText: 'Tipo de Colaborador'),
                items: const [
                  DropdownMenuItem(value: 'CLT', child: Text('CLT')),
                  DropdownMenuItem(value: 'DIARISTA', child: Text('Diarista')),
                  DropdownMenuItem(value: 'EMPREITEIRO', child: Text('Empreiteiro (PJ/Terceiro)')),
                ],
                onChanged: (val) => setState(() => _tipoColaborador = val!),
              ),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome Completo / Razão Social'),
                validator: (val) => val == null || val.isEmpty ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: _cargoController,
                decoration: const InputDecoration(labelText: 'Cargo / Função'),
                validator: (val) => val == null || val.isEmpty ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: _cpfCnpjController,
                decoration: const InputDecoration(labelText: 'CPF / CNPJ'),
              ),
              TextFormField(
                controller: _chavePixController,
                decoration: const InputDecoration(labelText: 'Chave PIX'),
              ),
              DropdownButtonFormField<String>(
                value: _tipoPagamento,
                decoration: const InputDecoration(labelText: 'Frequência de Pagamento'),
                items: const [
                  DropdownMenuItem(value: 'MENSAL', child: Text('Mensal')),
                  DropdownMenuItem(value: 'QUINZENAL', child: Text('Quinzenal')),
                  DropdownMenuItem(value: 'SEMANAL', child: Text('Semanal')),
                  DropdownMenuItem(value: 'DIARIO', child: Text('Diário / Medição')),
                ],
                onChanged: (val) => setState(() => _tipoPagamento = val!),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salarioController,
                      decoration: const InputDecoration(labelText: 'Salário Base (R\$)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _valorDiariaController,
                      decoration: const InputDecoration(labelText: 'Valor Diária (R\$)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              )
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
