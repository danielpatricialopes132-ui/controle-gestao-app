import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'contato_modal.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Connect to backend API via Riverpod Provider
    final List<Map<String, dynamic>> contatosSimulados = [
      {'nome': 'João Eletricista', 'telefone': '(11) 99999-9999', 'especialidade': 'Elétrica'},
      {'nome': 'Gesso & Cia', 'telefone': '(11) 88888-8888', 'especialidade': 'Gesso', 'empresa': 'Gesso & Cia LTDA'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda Telefônica'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar contatos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: contatosSimulados.length,
                itemBuilder: (context, index) {
                  final contato = contatosSimulados[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade100,
                        child: Text(contato['nome'][0], style: const TextStyle(color: Colors.indigo)),
                      ),
                      title: Text(contato['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${contato['telefone']} • ${contato['especialidade'] ?? 'Geral'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.message, color: Colors.green),
                        onPressed: () {
                          // TODO: Chamar WhatsApp API
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Em breve: Enviar mensagem no WhatsApp')),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => ContatoModal.show(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Contato'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}
