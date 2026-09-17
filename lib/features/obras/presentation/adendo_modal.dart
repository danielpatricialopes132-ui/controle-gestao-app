import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/obras_detalhe_provider.dart';

class AdendoModal extends ConsumerStatefulWidget {
  final String obraId;

  const AdendoModal({super.key, required this.obraId});

  @override
  ConsumerState<AdendoModal> createState() => _AdendoModalState();

  static void show(BuildContext context, String obraId) {
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
        child: AdendoModal(obraId: obraId),
      ),
    );
  }
}

class _AdendoModalState extends ConsumerState<AdendoModal> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _dataAprovacaoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final adendoState = ref.watch(adendoControllerProvider);
    final isLoading = adendoState is AsyncLoading;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Novo Aditivo/Contrato Extra',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição do Aditivo *', border: OutlineInputBorder()),
              validator: (val) => (val == null || val.isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _valorController,
                    decoration: const InputDecoration(labelText: 'Valor Cobrado *', border: OutlineInputBorder(), prefixText: 'R\$ '),
                    keyboardType: TextInputType.number,
                    validator: (val) => (val == null || val.isEmpty) ? 'Obrigatório' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _dataAprovacaoController,
                    decoration: const InputDecoration(labelText: 'Data de Aprovação', border: OutlineInputBorder()),
                    initialValue: null,
                    readOnly: true, // Aqui poderia ter um DatePicker
                    onTap: () {
                      _dataAprovacaoController.text = '15/09/2026';
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await ref.read(adendoControllerProvider.notifier).addAdendo(
                            obraId: widget.obraId,
                            descricao: _descricaoController.text,
                            valor: _valorController.text,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Aditivo registrado com sucesso!')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro: $e')),
                            );
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Salvar Aditivo'),
            ),
          ],
        ),
      ),
    );
  }
}
