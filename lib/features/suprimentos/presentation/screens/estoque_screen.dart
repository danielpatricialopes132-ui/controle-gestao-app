import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_client_provider.dart';
import 'estoque_detalhe_screen.dart';

class EstoqueScreen extends ConsumerStatefulWidget {
  const EstoqueScreen({super.key});

  @override
  ConsumerState<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends ConsumerState<EstoqueScreen> {
  bool isLoading = true;
  List<dynamic> estoques = [];

  @override
  void initState() {
    super.initState();
    fetchEstoques();
  }

  Future<void> fetchEstoques() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/suprimentos/estoques');

      if (mounted) {
        setState(() {
          // No backend o endpoint retorna { data: [...] } ?
          // Vamos assumir que retorna apenas a lista ou um json normal.
          // Se for list, ok, se for map, acessamos 'data'.
          if (response is List) {
             estoques = response;
          } else {
             estoques = response['data'] ?? [];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque Local (Obras)'),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : estoques.isEmpty
          ? const Center(child: Text('Nenhum estoque/almoxarifado encontrado. Crie uma Obra para começar.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: estoques.length,
              itemBuilder: (context, index) {
                final est = estoques[index];
                final qteItens = est['_count']?['itens'] ?? 0;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.store, color: Colors.white),
                    ),
                    title: Text(est['nome'] ?? 'Estoque Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Obra vinculada: ${est['obra'] != null ? est['obra']['nome'] : 'Nenhuma'}'),
                    trailing: Chip(
                      label: Text('$qteItens produtos'),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EstoqueDetalheScreen(
                            estoqueId: est['id'],
                            estoqueNome: est['nome'],
                          )
                        ),
                      ).then((_) => fetchEstoques());
                    },
                  ),
                );
              },
            ),
    );
  }
}
