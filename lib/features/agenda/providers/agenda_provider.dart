import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../data/models/agenda_model.dart';

class AgendaFiltroState {
  final String tipo; // 'TODOS', 'PROFISSIONAL', 'PESSOAL'
  final DateTime dataReferencia;

  AgendaFiltroState({
    this.tipo = 'TODOS',
    required this.dataReferencia,
  });

  AgendaFiltroState copyWith({String? tipo, DateTime? dataReferencia}) {
    return AgendaFiltroState(
      tipo: tipo ?? this.tipo,
      dataReferencia: dataReferencia ?? this.dataReferencia,
    );
  }
}

final agendaFiltroProvider = NotifierProvider<AgendaFiltroNotifier, AgendaFiltroState>(
  AgendaFiltroNotifier.new,
);

class AgendaFiltroNotifier extends Notifier<AgendaFiltroState> {
  @override
  AgendaFiltroState build() {
    return AgendaFiltroState(dataReferencia: DateTime.now());
  }

  void mudarTipo(String novoTipo) {
    state = state.copyWith(tipo: novoTipo);
  }

  void mudarData(DateTime novaData) {
    state = state.copyWith(dataReferencia: novaData);
  }
}

final agendaEventosProvider = FutureProvider<List<AgendaEventoModel>>((ref) async {
  final filtro = ref.watch(agendaFiltroProvider);
  final api = ref.read(apiClientProvider);

  final query = '/agenda/eventos?tipo=${filtro.tipo}';
  final response = await api.get(query);

  if (response is List) {
    return response.map((item) => AgendaEventoModel.fromJson(item)).toList();
  }
  return [];
});

final agendaActionsProvider = Provider<AgendaActionsService>((ref) {
  return AgendaActionsService(ref);
});

class AgendaActionsService {
  final Ref _ref;

  AgendaActionsService(this._ref);

  Future<void> criarEvento(Map<String, dynamic> payload) async {
    final api = _ref.read(apiClientProvider);
    await api.post('/agenda/eventos', payload);
    _ref.invalidate(agendaEventosProvider);
  }

  Future<void> responderConvite(String eventoId, String status) async {
    final api = _ref.read(apiClientProvider);
    await api.post('/agenda/eventos/$eventoId/resposta', {'status': status});
    _ref.invalidate(agendaEventosProvider);
  }

  Future<Map<String, dynamic>> interpretarAgendaInteligente(String texto) async {
    final api = _ref.read(apiClientProvider);
    final response = await api.post('/agenda/inteligente', {
      'promptTexto': texto,
      'dataReferencia': DateTime.now().toIso8601String(),
    });
    return response['dadosExtraidos'] ?? {};
  }

  Future<int> importarIcs(String icsContent) async {
    final api = _ref.read(apiClientProvider);
    final response = await api.post('/agenda/import-ics', {
      'icsString': icsContent,
    });
    _ref.invalidate(agendaEventosProvider);
    return response['totalImportados'] ?? 0;
  }
}
