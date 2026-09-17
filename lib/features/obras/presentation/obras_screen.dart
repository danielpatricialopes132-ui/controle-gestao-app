import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/obras_provider.dart';
import 'obra_modal.dart';
import 'obra_detalhes_screen.dart';

class ObrasScreen extends ConsumerWidget {
  const ObrasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obrasAsync = ref.watch(obrasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Obras'),
        elevation: 0,
      ),
      body: obrasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
        data: (obras) {
          if (obras.isEmpty) {
            return const Center(child: Text('Nenhuma obra cadastrada ainda.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: obras.length,
            itemBuilder: (context, index) {
              final obra = obras[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.construction, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text(obra['nome'] ?? 'Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(obra['endereco'] ?? 'Sem Endereço'),
                  trailing: Chip(
                    label: Text(
                      obra['status'] ?? '', 
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: _getStatusColor(obra['status']),
                    side: BorderSide.none,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ObraDetalhesScreen(
                          obraId: obra['id'],
                          obraNome: obra['nome'] ?? 'Obra sem nome',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ObraModal.show(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Obra'),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'EM_ANDAMENTO':
        return Colors.blue.shade100;
      case 'CONCLUIDA':
        return Colors.green.shade100;
      case 'CANCELADA':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }
}
