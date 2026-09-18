import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';
import '../../../core/offline/sync_manager.dart';

class PontoParams {
  final String dataStr;
  final String? obraId;
  PontoParams({required this.dataStr, this.obraId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PontoParams &&
          runtimeType == other.runtimeType &&
          dataStr == other.dataStr &&
          obraId == other.obraId;

  @override
  int get hashCode => dataStr.hashCode ^ obraId.hashCode;
}

final pontoDataFuturoProvider = FutureProvider.family<Map<String, dynamic>, PontoParams>((ref, params) async {
  final api = ref.read(apiClientProvider);
  String url = '/rh/ponto?data=${params.dataStr}';
  if (params.obraId != null) url += '&obraId=${params.obraId}';
  final res = await api.get(url);
  return res;
});

final pontosPendentesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/rh/ponto/pendentes');
  return res as List<dynamic>;
});

final pontoControllerProvider = AsyncNotifierProvider<PontoController, void>(() {
  return PontoController();
});

class PontoController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> salvarDiario({required String dataStr, required String obraId, required List<dynamic> registros}) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/rh/ponto', {
        'data': dataStr,
        'obraId': obraId,
        'registros': registros,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      // Se for erro de conexão (ex: SocketException ou falha parecida), colocamos na fila
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused') || e.toString().contains('Erro na requisição')) {
        try {
          final syncManager = ref.read(syncManagerProvider);
          await syncManager.enqueue('POST', '/rh/ponto', {
            'data': dataStr,
            'obraId': obraId,
            'registros': registros,
          });
          state = const AsyncValue.data(null); // Sucesso "Offline"
          return;
        } catch (syncError) {
          state = AsyncValue.error(syncError, st);
          rethrow;
        }
      }
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> aprovarRejeitar(String id, String statusAprovacao) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/rh/ponto/aprovar', {
        'id': id,
        'statusAprovacao': statusAprovacao,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> aprovarEmLote(List<String> ids) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/rh/ponto/aprovar', {
        'ids': ids,
        'statusAprovacao': 'APROVADO',
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> salvarLoteWhatsapp(String obraId, List<dynamic> dias) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/rh/ponto/lote', {
        'obraId': obraId,
        'dias': dias,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> analisarTextoEscala(String texto, String obraId) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post('/rh/ponto/importar-texto', {
        'texto': texto,
        'obraId': obraId,
      });
      return res['data'];
    } catch (e) {
      rethrow;
    }
  }
}
