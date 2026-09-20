import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_client_provider.dart';

class DiarioParams {
  final String obraId;
  final String dataStr;

  const DiarioParams({required this.obraId, required this.dataStr});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiarioParams &&
          runtimeType == other.runtimeType &&
          obraId == other.obraId &&
          dataStr == other.dataStr;

  @override
  int get hashCode => obraId.hashCode ^ dataStr.hashCode;
}

class RevistasState {
  final List<dynamic> revistas;
  final bool isLoading;
  final String? error;

  const RevistasState({
    this.revistas = const [],
    this.isLoading = false,
    this.error,
  });

  RevistasState copyWith({
    List<dynamic>? revistas,
    bool? isLoading,
    String? error,
  }) {
    return RevistasState(
      revistas: revistas ?? this.revistas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RevistasNotifier extends Notifier<RevistasState> {
  @override
  RevistasState build() {
    return const RevistasState();
  }

  Future<void> fetchRevistas(String obraId, {String? tipoPeriodicidade}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      final query = tipoPeriodicidade != null ? '?tipoPeriodicidade=$tipoPeriodicidade' : '';
      final response = await api.get('/obras/$obraId/revistas$query');
      if (response is List) {
        state = state.copyWith(revistas: response, isLoading: false);
      } else {
        state = state.copyWith(revistas: [], isLoading: false);
      }
    } catch (e) {
      if (kDebugMode) print("Erro ao carregar revistas: $e");
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createRevista(String obraId, Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.post('/obras/$obraId/revistas', data);
    await fetchRevistas(obraId);
  }

  Future<void> deleteRevista(String obraId, String revistaId) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/obras/$obraId/revistas/$revistaId');
    await fetchRevistas(obraId);
  }
}

final revistasProvider = NotifierProvider<RevistasNotifier, RevistasState>(() {
  return RevistasNotifier();
});

final diarioObraTecnicoProvider =
    FutureProvider.family<Map<String, dynamic>, DiarioParams>((ref, params) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/obras/${params.obraId}/diario-obra?data=${params.dataStr}');
  return res as Map<String, dynamic>;
});
