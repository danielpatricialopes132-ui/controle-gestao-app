import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_client_provider.dart';

class GerenciamentoTerceirosState {
  final List<dynamic> terceiros;
  final List<dynamic> punchList;
  final List<dynamic> mapaVisitasSemanal;
  final Map<String, dynamic>? periodoVisitas;
  final bool isLoading;
  final String? error;

  const GerenciamentoTerceirosState({
    this.terceiros = const [],
    this.punchList = const [],
    this.mapaVisitasSemanal = const [],
    this.periodoVisitas,
    this.isLoading = false,
    this.error,
  });

  GerenciamentoTerceirosState copyWith({
    List<dynamic>? terceiros,
    List<dynamic>? punchList,
    List<dynamic>? mapaVisitasSemanal,
    Map<String, dynamic>? periodoVisitas,
    bool? isLoading,
    String? error,
  }) {
    return GerenciamentoTerceirosState(
      terceiros: terceiros ?? this.terceiros,
      punchList: punchList ?? this.punchList,
      mapaVisitasSemanal: mapaVisitasSemanal ?? this.mapaVisitasSemanal,
      periodoVisitas: periodoVisitas ?? this.periodoVisitas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class GerenciamentoTerceirosNotifier extends Notifier<GerenciamentoTerceirosState> {
  @override
  GerenciamentoTerceirosState build() {
    return const GerenciamentoTerceirosState();
  }

  Future<void> fetchAll(String obraId, {String? inicio, String? fim}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      final resTerceiros = await api.get('/obras/$obraId/terceiros-cliente');
      final resPunch = await api.get('/obras/$obraId/punch-list');

      String urlVisitas = '/obras/$obraId/visitas-terceiros';
      if (inicio != null && fim != null) {
        urlVisitas += '?inicio=$inicio&fim=$fim';
      }
      final resVisitas = await api.get(urlVisitas);

      state = state.copyWith(
        terceiros: resTerceiros is List ? resTerceiros : [],
        punchList: resPunch is List ? resPunch : [],
        mapaVisitasSemanal: resVisitas != null && resVisitas['mapaSemanal'] is List ? resVisitas['mapaSemanal'] : [],
        periodoVisitas: resVisitas != null && resVisitas['periodo'] is Map<String, dynamic> ? resVisitas['periodo'] : null,
        isLoading: false,
      );
    } catch (e) {
      if (kDebugMode) print("Erro ao carregar dados de terceiros/visitas: $e");
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> registrarVisita(String obraId, Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.post('/obras/$obraId/visitas-terceiros', data);
    await fetchAll(obraId);
  }

  Future<void> deleteVisita(String obraId, String visitaId) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/obras/$obraId/visitas-terceiros/$visitaId');
    await fetchAll(obraId);
  }

  Future<void> createTerceiro(String obraId, Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.post('/obras/$obraId/terceiros-cliente', data);
    await fetchAll(obraId);
  }

  Future<void> updateTerceiro(String obraId, String terceiroId, Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.put('/obras/$obraId/terceiros-cliente/$terceiroId', data);
    await fetchAll(obraId);
  }

  Future<void> updateTerceiroStatus(String obraId, String terceiroId, String status) async {
    await updateTerceiro(obraId, terceiroId, {'status': status});
  }

  Future<void> deleteTerceiro(String obraId, String terceiroId) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/obras/$obraId/terceiros-cliente/$terceiroId');
    await fetchAll(obraId);
  }

  Future<void> createPunchItem(String obraId, Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.post('/obras/$obraId/punch-list', data);
    await fetchAll(obraId);
  }

  Future<void> updatePunchItem(String obraId, String itemId, Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.put('/obras/$obraId/punch-list/$itemId', data);
    await fetchAll(obraId);
  }

  Future<void> updatePunchItemStatus(String obraId, String itemId, String status) async {
    await updatePunchItem(obraId, itemId, {
      'status': status,
      if (status == 'RESOLVIDO') 'dataResolucao': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deletePunchItem(String obraId, String itemId) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/obras/$obraId/punch-list/$itemId');
    await fetchAll(obraId);
  }
}

final gerenciamentoTerceirosProvider =
    NotifierProvider<GerenciamentoTerceirosNotifier, GerenciamentoTerceirosState>(() {
  return GerenciamentoTerceirosNotifier();
});
