import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rh_provider.dart';

class FuncionarioModal extends ConsumerStatefulWidget {
  final Map<String, dynamic>? funcionario;

  const FuncionarioModal({super.key, this.funcionario});

  @override
  ConsumerState<FuncionarioModal> createState() => _FuncionarioModalState();

  static void show(BuildContext context, {Map<String, dynamic>? funcionario}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FuncionarioModal(funcionario: funcionario),
      ),
    );
  }
}

class _FuncionarioModalState extends ConsumerState<FuncionarioModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _cargoController;
  late TextEditingController _salarioController;
  late TextEditingController _diariaMotoristaController;
  
  bool _isMotorista = false;

  @override
  void initState() {
    super.initState();
    final f = widget.funcionario;
    _nomeController = TextEditingController(text: f?['nome'] ?? '');
    _cargoController = TextEditingController(text: f?['cargo'] ?? '');
    _salarioController = TextEditingController(text: f?['valorPadrao']?.toString() ?? f?['salario']?.toString() ?? '');
    _diariaMotoristaController = TextEditingController(text: f?['valorDiariaMotorista']?.toString() ?? '');
    _isMotorista = f?['valorDiariaMotorista'] != null;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cargoController.dispose();
    _salarioController.dispose();
    _diariaMotoristaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(rhControllerProvider);
    final isLoading = estado is AsyncLoading;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.funcionario != null ? 'Editar Funcionário' : 'Novo Funcionário',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome Completo *', border: OutlineInputBorder()),
              validator: (val) => (val == null || val.isEmpty) ? 'Obrigatório' : null,
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cargoController,
                    decoration: const InputDecoration(labelText: 'Cargo (Ex: Pedreiro)', border: OutlineInputBorder()),
                    enabled: !isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _salarioController,
                    decoration: const InputDecoration(labelText: 'Salário / Diária Base', border: OutlineInputBorder(), prefixText: 'R\$ '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Recebe Auxílio Motorista?'),
              subtitle: const Text('Será somado na diária quando houver viagem'),
              value: _isMotorista,
              onChanged: isLoading ? null : (val) {
                setState(() => _isMotorista = val);
              },
            ),
            if (_isMotorista) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _diariaMotoristaController,
                decoration: const InputDecoration(labelText: 'Valor Auxílio Motorista (Diário)', border: OutlineInputBorder(), prefixText: 'R\$ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: !isLoading,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    final data = {
                      'nome': _nomeController.text,
                      'cargo': _cargoController.text,
                      'salario': _salarioController.text,
                      'valorDiariaMotorista': _isMotorista ? _diariaMotoristaController.text : null,
                    };

                    if (widget.funcionario != null) {
                      await ref.read(rhControllerProvider.notifier).saveFuncionario(
                        data,
                        id: widget.funcionario!['id'],
                      );
                    } else {
                      await ref.read(rhControllerProvider.notifier).saveFuncionario(
                        data,
                      );
                    }
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(widget.funcionario != null ? 'Funcionário atualizado com sucesso!' : 'Funcionário cadastrado com sucesso!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro: ${e.toString()}'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(widget.funcionario != null ? 'Salvar Edição' : 'Salvar Funcionário'),
            ),
          ],
        ),
      ),
    );
  }
}
