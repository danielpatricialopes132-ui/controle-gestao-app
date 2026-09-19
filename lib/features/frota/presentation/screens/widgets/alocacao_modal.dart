import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/frota_provider.dart';
import '../../../../obras/providers/obras_provider.dart';

class AlocacaoModal {
  static void show(BuildContext context, String equipamentoId) {
    showDialog(
      context: context,
      builder: (ctx) => _AlocacaoForm(equipamentoId: equipamentoId),
    );
  }
}

class _AlocacaoForm extends ConsumerStatefulWidget {
  final String equipamentoId;

  const _AlocacaoForm({required this.equipamentoId});

  @override
  ConsumerState<_AlocacaoForm> createState() => _AlocacaoFormState();
}

class _AlocacaoFormState extends ConsumerState<_AlocacaoForm> {
  String? _obraSelecionada;

  void _alocar() async {
    if (_obraSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma obra')));
      return;
    }

    final data = {
      'equipamentoId': widget.equipamentoId,
      'obraId': _obraSelecionada,
      'dataInicio': DateTime.now().toIso8601String(),
    };

    try {
      await ref.read(frotaControllerProvider.notifier).alocarEquipamento(data);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipamento alocado!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final obrasAsync = ref.watch(obrasProvider);

    return AlertDialog(
      title: const Text('Alocar na Obra'),
      content: obrasAsync.when(
        loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
        error: (e, st) => Text('Erro ao carregar obras: $e'),
        data: (obras) {
          return DropdownButtonFormField<String>(
            value: _obraSelecionada,
            decoration: const InputDecoration(labelText: 'Selecione a Obra', border: OutlineInputBorder()),
            items: obras.map<DropdownMenuItem<String>>((o) => DropdownMenuItem(
              value: o['id'],
              child: Text(o['nome']),
            )).toList(),
            onChanged: (val) => setState(() => _obraSelecionada = val),
          );
        }
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _alocar, child: const Text('Alocar')),
      ],
    );
  }
}
