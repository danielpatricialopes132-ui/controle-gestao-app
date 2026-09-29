import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../agenda/presentation/novo_evento_dialog.dart';

class ChatSalaScreen extends ConsumerStatefulWidget {
  final ChatConversaModel conversa;

  const ChatSalaScreen({super.key, required this.conversa});

  @override
  ConsumerState<ChatSalaScreen> createState() => _ChatSalaScreenState();
}

class _ChatSalaScreenState extends ConsumerState<ChatSalaScreen> {
  final _textoController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _timerPolling;

  @override
  void initState() {
    super.initState();
    // Marcar lida ao abrir
    ref.read(chatActionsProvider).marcarLida(widget.conversa.id);
    // Polling de 3s enquanto a tela estiver aberta
    _timerPolling = Timer.periodic(const Duration(seconds: 3), (_) {
      ref.invalidate(chatMensagensProvider(widget.conversa.id));
    });
  }

  @override
  void dispose() {
    _timerPolling?.cancel();
    _textoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enviarTexto() async {
    final texto = _textoController.text.trim();
    if (texto.isEmpty) return;

    _textoController.clear();
    await ref.read(chatActionsProvider).enviarMensagem(
          conversaId: widget.conversa.id,
          conteudo: texto,
        );

    _scrollParaFim();
  }

  void _scrollParaFim() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mensagensAsync = ref.watch(chatMensagensProvider(widget.conversa.id));
    final usuarioLogado = ref.watch(appUserProvider);
    final meuUserId = usuarioLogado?['id'];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                widget.conversa.tipo == 'OBRA'
                    ? Icons.apartment
                    : widget.conversa.tipo == 'DIRETA'
                        ? Icons.person
                        : Icons.groups,
                size: 20,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversa.titulo,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.conversa.tipo == 'DIRETA'
                        ? 'Conversa Direta'
                        : '${widget.conversa.participantes.length} participantes',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Agendar Reunião',
            onPressed: () {
              final participantesIds = widget.conversa.participantes
                  .map((p) => (p is Map ? p['usuarioId'] : null))
                  .where((id) => id != null)
                  .toList();

              showDialog(
                context: context,
                builder: (_) => NovoEventoDialog(
                  dadosPreenchidos: {
                    'titulo': 'Reunião: ${widget.conversa.titulo}',
                    'obraId': widget.conversa.obra?['id'],
                    'participantesIds': participantesIds,
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: mensagensAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erro: $err')),
              data: (mensagens) {
                if (mensagens.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma mensagem ainda.\nDiga olá!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollParaFim());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final msg = mensagens[index];
                    final isMinha = msg.remetenteId == meuUserId;

                    return Align(
                      alignment: isMinha ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMinha
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMinha ? 16 : 2),
                            bottomRight: Radius.circular(isMinha ? 2 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMinha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMinha && msg.remetenteNome != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  msg.remetenteNome!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            if (msg.conteudo != null)
                              Text(
                                msg.conteudo!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isMinha ? Colors.white : Colors.black87,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${msg.criadoEm.hour.toString().padLeft(2, '0')}:${msg.criadoEm.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMinha ? Colors.white70 : Colors.grey.shade600,
                                  ),
                                ),
                                if (isMinha) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    msg.status == 'LIDO'
                                        ? Icons.done_all
                                        : Icons.done,
                                    size: 13,
                                    color: msg.status == 'LIDO'
                                        ? Colors.cyanAccent
                                        : Colors.white70,
                                  ),
                                ],
                              ],
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
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textoController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviarTexto(),
                decoration: InputDecoration(
                  hintText: 'Digite uma mensagem...',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _enviarTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
