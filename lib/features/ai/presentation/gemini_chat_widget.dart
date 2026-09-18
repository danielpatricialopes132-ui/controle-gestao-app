import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_provider.dart';
import '../../auth/providers/auth_provider.dart';

class GeminiChatWidget extends ConsumerWidget {
  const GeminiChatWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(appUserProvider);
    if (userData?['role'] != 'MASTER') {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const GeminiChatDialog(),
        );
      },
      backgroundColor: Colors.blueAccent,
      tooltip: 'Assistente IA',
      child: const Icon(Icons.auto_awesome, color: Colors.white),
    );
  }
}

class GeminiChatDialog extends ConsumerStatefulWidget {
  const GeminiChatDialog({super.key});

  @override
  ConsumerState<GeminiChatDialog> createState() => _GeminiChatDialogState();
}

class _GeminiChatDialogState extends ConsumerState<GeminiChatDialog> {
  final _textController = TextEditingController();
  final List<Map<String, String>> _messages = []; // {'role': 'user'|'model', 'text': '...'}
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
    });
    _textController.clear();
    _scrollToBottom();

    // Formatar historico para API do Gemini (user e model, parts com text)
    final history = _messages.take(_messages.length - 1).map((m) {
      return {
        'role': m['role'] == 'user' ? 'user' : 'model',
        'parts': m['text']!,
      };
    }).toList();

    final response = await ref.read(aiProvider.notifier).sendMessage(text, history);

    if (response != null) {
      setState(() {
        _messages.add({'role': 'model', 'text': response});
      });
    } else {
      setState(() {
        _messages.add({'role': 'model', 'text': 'Ocorreu um erro ao conectar com o assistente.'});
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(aiProvider) is AsyncLoading;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.blueAccent),
                    SizedBox(width: 8),
                    Text('Assistente DPG Construtoras', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blueAccent : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['text']!,
                        style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: isLoading ? null : _sendMessage,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
