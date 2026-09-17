import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../../providers/rh_provider.dart';

class DialogCadastroRapido extends ConsumerStatefulWidget {
  final String? nomeInicial;
  
  const DialogCadastroRapido({super.key, this.nomeInicial});

  @override
  ConsumerState<DialogCadastroRapido> createState() => _DialogCadastroRapidoState();
}

class _DialogCadastroRapidoState extends ConsumerState<DialogCadastroRapido> {
  late TextEditingController _nomeCtrl;
  final _cargoCtrl = TextEditingController(text: 'Ajudante'); // default
  final _salarioCtrl = TextEditingController();
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.nomeInicial ?? '');
  }

  Future<void> _salvar() async {
    final nome = _nomeCtrl.text.trim();
    final cargo = _cargoCtrl.text.trim();
    if (nome.isEmpty || cargo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome e cargo são obrigatórios')));
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final api = ref.read(apiClientProvider);
      
      // Cria o funcionário usando endpoint existente (ou um novo se necessário)
      // Assumindo que POST /rh/funcionarios cadastra um novo
      await api.post('/rh/funcionarios', {
        'nome': nome,
        'cargo': cargo,
        'salario': double.tryParse(_salarioCtrl.text.replaceAll(',', '.')) ?? 0,
      });

      if (mounted) {
        // Invalida o provider de funcionários para recarregar
        ref.invalidate(funcionariosProvider);
        Navigator.pop(context, true); // Retorna true indicando sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cadastrar Novo Colaborador'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cargoCtrl,
              decoration: const InputDecoration(labelText: 'Cargo (ex: Pedreiro, Ajudante)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _salarioCtrl,
              decoration: const InputDecoration(labelText: 'Salário (Opcional)', border: OutlineInputBorder(), prefixText: 'R\$ '),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isSaving ? null : _salvar,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
          child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Salvar'),
        ),
      ],
    );
  }
}
