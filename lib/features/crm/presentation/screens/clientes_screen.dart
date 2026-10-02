import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/crm_provider.dart';
import '../../data/models/cliente.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../obras/providers/obra_ged_provider.dart';

class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(crmProvider.notifier).fetchClientes());
  }

  void _showAddClienteModal() {
    final nomeController = TextEditingController();
    final cpfCnpjController = TextEditingController();
    final telefoneController = TextEditingController();
    final emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Novo Cliente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Cliente'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cpfCnpjController,
                decoration: const InputDecoration(labelText: 'CPF/CNPJ'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (nomeController.text.isEmpty) return;
                  try {
                    await ref.read(crmProvider.notifier).createCliente(
                      Cliente(
                        id: '',
                        nome: nomeController.text,
                        cpfCnpj: cpfCnpjController.text,
                        telefone: telefoneController.text,
                        email: emailController.text,
                      )
                    );
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                  }
                },
                child: const Text('Salvar Cliente'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(crmProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.clientes.length,
              itemBuilder: (context, index) {
                final cliente = provider.clientes[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(cliente.nome),
                  subtitle: Text(cliente.telefone ?? 'Sem telefone'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'portal') {
                        try {
                          final token = await ref.read(obraGedControllerProvider.notifier).gerarLinkMagicoPortal(cliente.id);
                          final baseUrl = kReleaseMode ? 'https://controle-gestao-api.onrender.com' : 'http://localhost:3000';
                          final link = '$baseUrl/portal?token=$token';
                          
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.workspace_premium, color: Colors.teal),
                                  SizedBox(width: 8),
                                  Text('Portal Minha Obra (Cliente)'),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Link exclusivo para o cliente ${cliente.nome} acompanhar o andamento, feed de fotos, cronograma e revistas executivas:',
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 12),
                                  SelectableText(
                                    link,
                                    style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: link));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Link do portal copiado!')),
                                    );
                                  },
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copiar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(dCtx),
                                  child: const Text('Fechar'),
                                ),
                              ],
                            ),
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'portal', child: Row(
                        children: [
                          Icon(Icons.public, size: 18, color: Colors.teal),
                          SizedBox(width: 8),
                          Text('Portal Minha Obra'),
                        ],
                      )),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(heroTag: null, 
        onPressed: _showAddClienteModal,
        tooltip: 'Adicionar Cliente',
        child: const Icon(Icons.add),
      ),
    );
  }
}
