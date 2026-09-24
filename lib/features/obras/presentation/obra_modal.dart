import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/obras_provider.dart';

class ObraModal extends ConsumerStatefulWidget {
  final Map<String, dynamic>? obra;

  const ObraModal({super.key, this.obra});

  @override
  ConsumerState<ObraModal> createState() => _ObraModalState();

  static void show(BuildContext context, {Map<String, dynamic>? obra}) {
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
        child: ObraModal(obra: obra),
      ),
    );
  }
}

class _ObraModalState extends ConsumerState<ObraModal> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _enderecoController = TextEditingController();
  String _status = 'EM_ANDAMENTO';

  @override
  void initState() {
    super.initState();
    if (widget.obra != null) {
      _nomeController.text = widget.obra!['nome'] ?? '';
      _enderecoController.text = widget.obra!['endereco'] ?? '';
      _status = widget.obra!['status'] ?? 'EM_ANDAMENTO';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.obra == null ? 'Nova Obra' : 'Editar Obra',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome da Obra',
                border: OutlineInputBorder(),
              ),
              validator: (val) => (val == null || val.isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _enderecoController,
              decoration: const InputDecoration(
                labelText: 'Endereço (Opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'EM_ANDAMENTO', child: Text('Em Andamento')),
                DropdownMenuItem(value: 'CONCLUIDA', child: Text('Concluída')),
                DropdownMenuItem(value: 'CANCELADA', child: Text('Cancelada')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final payload = {
                    'nome': _nomeController.text,
                    'endereco': _enderecoController.text,
                    'status': _status,
                  };

                  try {
                    if (widget.obra == null) {
                      await ref.read(obrasControllerProvider.notifier).addObra(payload);
                    } else {
                      await ref.read(obrasControllerProvider.notifier).updateObra(widget.obra!['id'], payload);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(widget.obra == null ? 'Obra cadastrada com sucesso!' : 'Obra atualizada com sucesso!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao salvar obra: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Salvar Obra'),
            ),
          ],
        ),
      ),
    );
  }
}
