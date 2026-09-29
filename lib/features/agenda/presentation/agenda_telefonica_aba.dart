import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/providers/api_client_provider.dart';
import 'contato_modal.dart';

final contatosProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/contatos');
  if (response['success'] == true && response['data'] is List) {
    return response['data'];
  }
  return [];
});

class AgendaTelefonicaAba extends ConsumerStatefulWidget {
  const AgendaTelefonicaAba({super.key});

  @override
  ConsumerState<AgendaTelefonicaAba> createState() => _AgendaTelefonicaAbaState();
}

class _AgendaTelefonicaAbaState extends ConsumerState<AgendaTelefonicaAba> {
  final _buscaController = TextEditingController();
  String _filtroTexto = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _abrirWhatsApp(String telefone) async {
    final cleanPhone = telefone.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse('https://wa.me/55$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contatosAsync = ref.watch(contatosProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          ContatoModal.show(context);
          // Atualiza a lista após fechar o modal
          ref.invalidate(contatosProvider);
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Contato'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _buscaController,
              onChanged: (val) => setState(() => _filtroTexto = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por nome, especialidade ou telefone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filtroTexto.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscaController.clear();
                          setState(() => _filtroTexto = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: contatosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Erro ao carregar contatos: $err')),
                data: (contatos) {
                  final filtrados = contatos.where((c) {
                    final nome = (c['nome'] ?? '').toString().toLowerCase();
                    final tel = (c['telefone'] ?? '').toString().toLowerCase();
                    final esp = (c['especialidade'] ?? '').toString().toLowerCase();
                    final emp = (c['empresa'] ?? '').toString().toLowerCase();
                    return nome.contains(_filtroTexto) ||
                        tel.contains(_filtroTexto) ||
                        esp.contains(_filtroTexto) ||
                        emp.contains(_filtroTexto);
                  }).toList();

                  if (filtrados.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contact_phone_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhum contato encontrado',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cadastre profissionais, empreiteiros e fornecedores.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final contato = filtrados[index];
                      final telefone = contato['telefone'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade100,
                            child: Text(
                              (contato['nome']?[0] ?? '?').toUpperCase(),
                              style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            contato['nome'] ?? 'Sem nome',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${contato['telefone'] ?? 'Sem telefone'} • ${contato['especialidade'] ?? contato['empresa'] ?? 'Geral'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (telefone.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.message, color: Colors.green),
                                  tooltip: 'Conversar no WhatsApp',
                                  onPressed: () => _abrirWhatsApp(telefone),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
