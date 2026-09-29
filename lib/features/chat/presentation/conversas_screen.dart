import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import 'chat_sala_screen.dart';
import 'novo_chat_dialog.dart';

class ConversasScreen extends ConsumerWidget {
  const ConversasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversasAsync = ref.watch(chatConversasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.forum_outlined, size: 24),
            SizedBox(width: 8),
            Text('Mensageria Corporativa', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(chatConversasProvider.notifier).recarregar(),
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const NovoChatDialog(),
            ),
            tooltip: 'Novo Chat / Canal',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const NovoChatDialog(),
        ),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Nova Mensagem'),
      ),
      body: conversasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Erro ao carregar mensagens: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(chatConversasProvider.notifier).recarregar(),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
        data: (conversas) {
          if (conversas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhuma conversa ainda',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicie uma conversa direta ou crie um grupo por obra.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const NovoChatDialog(),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Iniciar Conversa'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: conversas.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = conversas[index];
              final isObra = item.tipo == 'OBRA';
              final isGrupo = item.tipo == 'GRUPO' || item.tipo == 'DEPARTAMENTO';

              IconData icone = Icons.person;
              Color iconeBg = Colors.blue.shade100;
              Color iconeCor = Colors.blue.shade800;

              if (isObra) {
                icone = Icons.apartment;
                iconeBg = Colors.orange.shade100;
                iconeCor = Colors.orange.shade800;
              } else if (isGrupo) {
                icone = Icons.groups;
                iconeBg = Colors.purple.shade100;
                iconeCor = Colors.purple.shade800;
              }

              final previewMsg = item.ultimaMensagem?.conteudo ??
                  (item.ultimaMensagem?.tipoAnexo != null ? '📎 Anexo' : 'Sem mensagens');

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: iconeBg,
                      child: Icon(icone, color: iconeCor),
                    ),
                    if (item.naoLidas > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            item.naoLidas.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.titulo,
                        style: TextStyle(
                          fontWeight: item.naoLidas > 0 ? FontWeight.bold : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatarHora(item.atualizadoEm),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                subtitle: Text(
                  previewMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.naoLidas > 0 ? Colors.black87 : Colors.grey.shade600,
                    fontWeight: item.naoLidas > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatSalaScreen(conversa: item),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatarHora(DateTime data) {
    final now = DateTime.now();
    if (data.day == now.day && data.month == now.month && data.year == now.year) {
      return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
    }
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
  }
}
