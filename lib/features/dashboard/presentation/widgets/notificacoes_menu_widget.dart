import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/api_client_provider.dart';

final notificacoesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/notificacoes');
  return response is Map<String, dynamic> ? response : {'totalNaoLidas': 0, 'notificacoes': []};
});

class NotificacoesMenuWidget extends ConsumerWidget {
  final Function(int)? onNavigateTab;

  const NotificacoesMenuWidget({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificacoesAsync = ref.watch(notificacoesProvider);

    return notificacoesAsync.when(
      loading: () => const IconButton(
        icon: Icon(Icons.notifications_none),
        onPressed: null,
      ),
      error: (_, _) => const IconButton(
        icon: Icon(Icons.notifications_none),
        onPressed: null,
      ),
      data: (dados) {
        final total = (dados['totalNaoLidas'] ?? 0) as int;
        final List<dynamic> itens = dados['notificacoes'] ?? [];

        return PopupMenuButton<dynamic>(
          tooltip: 'Central de Notificações',
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, size: 24),
              if (total > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      total > 9 ? '9+' : total.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          itemBuilder: (context) {
            if (itens.isEmpty) {
              return [
                const PopupMenuItem(
                  enabled: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Tudo em dia! Nenhuma notificação pendente.', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
              ];
            }

            return [
              PopupMenuItem(
                enabled: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Notificações ($total)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    TextButton(
                      onPressed: () => ref.invalidate(notificacoesProvider),
                      child: const Text('Atualizar', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              ...itens.map((n) {
                final tipo = n['tipo'] ?? 'GERAL';
                IconData icone = Icons.info_outline;
                Color cor = Colors.blue;

                if (tipo == 'AGENDA') {
                  icone = Icons.calendar_month;
                  cor = Colors.orange;
                } else if (tipo == 'CHAT') {
                  icone = Icons.forum;
                  cor = Colors.purple;
                } else if (tipo == 'SUPRIMENTOS') {
                  icone = Icons.inventory_2;
                  cor = Colors.green;
                }

                return PopupMenuItem(
                  onTap: () {
                    if (n['rota'] == '/agenda' && onNavigateTab != null) {
                      onNavigateTab!(4);
                    } else if (n['rota'] == '/suprimentos' && onNavigateTab != null) {
                      onNavigateTab!(5);
                    } else if (n['rota'] == '/chat') {
                      context.push('/chat');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    width: 320,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: cor.withValues(alpha: 0.15),
                          child: Icon(icone, size: 16, color: cor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n['titulo'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n['descricao'] ?? '',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ];
          },
        );
      },
    );
  }
}
