import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_sala_screen.dart';

class NovoChatDialog extends ConsumerStatefulWidget {
  const NovoChatDialog({super.key});

  @override
  ConsumerState<NovoChatDialog> createState() => _NovoChatDialogState();
}

class _NovoChatDialogState extends ConsumerState<NovoChatDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _usuarios = [];
  List<dynamic> _obras = [];
  bool _carregando = true;

  // Estado para criação de grupo
  final _tituloGrupoController = TextEditingController();
  final Set<String> _membrosSelecionados = {};
  String? _obraSelecionadaId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tituloGrupoController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      final api = ref.read(apiClientProvider);
      final usersRes = await api.get('/admin/users');
      final obrasRes = await api.get('/obras');

      setState(() {
        _usuarios = usersRes is List ? usersRes : (usersRes['users'] ?? []);
        _obras = obrasRes is List ? obrasRes : (obrasRes['obras'] ?? []);
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  void _iniciarChatDireto(String userId) async {
    Navigator.of(context).pop();
    final conversa = await ref.read(chatConversasProvider.notifier).criarConversaDireta(userId);
    if (conversa != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatSalaScreen(conversa: conversa)),
      );
    }
  }

  void _criarGrupo() async {
    final titulo = _tituloGrupoController.text.trim();
    if (titulo.isEmpty && _obraSelecionadaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um nome para o canal')),
      );
      return;
    }

    Navigator.of(context).pop();
    final conversa = await ref.read(chatConversasProvider.notifier).criarGrupo(
          titulo: titulo.isNotEmpty ? titulo : 'Canal de Obra',
          participantesIds: _membrosSelecionados.toList(),
          obraId: _obraSelecionadaId,
          tipo: _obraSelecionadaId != null ? 'OBRA' : 'GRUPO',
        );

    if (conversa != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatSalaScreen(conversa: conversa)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        height: 520,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.person), text: 'Conversa Direta'),
                Tab(icon: Icon(Icons.groups), text: 'Novo Grupo/Canal'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // ABA 1: CONVERSA DIRETA
                        _usuarios.isEmpty
                            ? const Center(child: Text('Nenhum colaborador encontrado.'))
                            : ListView.builder(
                                itemCount: _usuarios.length,
                                itemBuilder: (context, index) {
                                  final u = _usuarios[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text(u['nome']?[0]?.toUpperCase() ?? '?'),
                                    ),
                                    title: Text(u['nome'] ?? 'Sem Nome'),
                                    subtitle: Text(u['email'] ?? ''),
                                    trailing: const Icon(Icons.chat_bubble_outline),
                                    onTap: () => _iniciarChatDireto(u['id']),
                                  );
                                },
                              ),

                        // ABA 2: NOVO GRUPO OU CANAL DE OBRA
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _tituloGrupoController,
                                decoration: const InputDecoration(
                                  labelText: 'Nome do Grupo/Canal',
                                  hintText: 'Ex: Equipe de Engenharia',
                                  prefixIcon: Icon(Icons.edit_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_obras.isNotEmpty) ...[
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Vincular à Obra (Opcional)',
                                    prefixIcon: Icon(Icons.apartment),
                                  ),
                                  initialValue: _obraSelecionadaId,
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('Nenhuma (Grupo Geral)')),
                                    ..._obras.map(
                                      (o) => DropdownMenuItem(
                                        value: o['id'].toString(),
                                        child: Text(o['nome'] ?? 'Obra'),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) => setState(() => _obraSelecionadaId = val),
                                ),
                                const SizedBox(height: 12),
                              ],
                              const Text(
                                'Selecione os Membros:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ..._usuarios.map((u) {
                                final isSelected = _membrosSelecionados.contains(u['id']);
                                return CheckboxListTile(
                                  dense: true,
                                  title: Text(u['nome'] ?? ''),
                                  subtitle: Text(u['email'] ?? ''),
                                  value: isSelected,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _membrosSelecionados.add(u['id']);
                                      } else {
                                        _membrosSelecionados.remove(u['id']);
                                      }
                                    });
                                  },
                                );
                              }),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _criarGrupo,
                                  icon: const Icon(Icons.check),
                                  label: const Text('Criar Canal'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
