import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../data/models/chat_model.dart';

// Provider para listar conversas
final chatConversasProvider =
    AsyncNotifierProvider<ChatConversasNotifier, List<ChatConversaModel>>(
        ChatConversasNotifier.new);

class ChatConversasNotifier extends AsyncNotifier<List<ChatConversaModel>> {
  Timer? _timerPolling;

  @override
  FutureOr<List<ChatConversaModel>> build() async {
    _iniciarPolling();
    ref.onDispose(() => _timerPolling?.cancel());
    return _carregarConversas();
  }

  void _iniciarPolling() {
    _timerPolling?.cancel();
    _timerPolling = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final conversas = await _carregarConversas();
        state = AsyncData(conversas);
      } catch (_) {}
    });
  }

  Future<List<ChatConversaModel>> _carregarConversas() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/chat/conversas');
    if (response is List) {
      return response.map((item) => ChatConversaModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> recarregar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _carregarConversas());
  }

  Future<ChatConversaModel?> criarConversaDireta(String destinatarioId) async {
    final api = ref.read(apiClientProvider);
    final response = await api.post('/chat/conversas', {
      'tipo': 'DIRETA',
      'destinatarioId': destinatarioId,
    });
    await recarregar();
    return ChatConversaModel.fromJson(response);
  }

  Future<ChatConversaModel?> criarGrupo({
    required String titulo,
    required List<String> participantesIds,
    String? obraId,
    String tipo = 'GRUPO',
  }) async {
    final api = ref.read(apiClientProvider);
    final response = await api.post('/chat/conversas', {
      'tipo': tipo,
      'titulo': titulo,
      'participantesIds': participantesIds,
      'obraId': obraId,
    });
    await recarregar();
    return ChatConversaModel.fromJson(response);
  }
}

// Controller de mensagens por conversa
final chatMensagensProvider =
    FutureProvider.family<List<ChatMensagemModel>, String>((ref, conversaId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/chat/conversas/$conversaId/mensagens');
  if (response is List) {
    return response.map((m) => ChatMensagemModel.fromJson(m)).toList();
  }
  return [];
});

// Ações no chat (enviar, marcar lida)
final chatActionsProvider = Provider<ChatActionsService>((ref) {
  return ChatActionsService(ref);
});

class ChatActionsService {
  final Ref _ref;

  ChatActionsService(this._ref);

  Future<void> enviarMensagem({
    required String conversaId,
    String? conteudo,
    String? tipoAnexo,
    String? urlAnexo,
    Map<String, dynamic>? dadosContexto,
  }) async {
    final api = _ref.read(apiClientProvider);
    await api.post('/chat/conversas/$conversaId/mensagens', {
      'conteudo': conteudo,
      'tipoAnexo': tipoAnexo,
      'urlAnexo': urlAnexo,
      'dadosContexto': dadosContexto,
    });
    // Invalida para atualizar a lista de mensagens imediatamente
    _ref.invalidate(chatMensagensProvider(conversaId));
    _ref.read(chatConversasProvider.notifier).recarregar();
  }

  Future<void> marcarLida(String conversaId) async {
    try {
      final api = _ref.read(apiClientProvider);
      await api.post('/chat/conversas/$conversaId/lida', {});
      _ref.read(chatConversasProvider.notifier).recarregar();
    } catch (_) {}
  }
}
