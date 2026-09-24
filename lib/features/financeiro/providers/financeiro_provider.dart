import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';

final transacoesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/financeiro/transacoes');
  return response['data'] as List<dynamic>;
});

final valesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/financeiro/vales');
  return response['data'] as List<dynamic>;
});

final contasBancariasProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/financeiro/contas-bancarias');
  return response as List<dynamic>;
});

final auditoriaFinanceiraProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/financeiro/super-auditor');
  return response as Map<String, dynamic>;
});

class FinanceiroController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> reclassificarTransacao(String transacaoId, String categoriaId, {String? obraId}) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/financeiro/super-auditor', {
        'acao': 'RECLASSIFICAR',
        'transacaoId': transacaoId,
        'categoriaId': categoriaId,
        'obraId': obraId,
      });
      state = const AsyncData(null);
      ref.invalidate(transacoesProvider);
      ref.invalidate(auditoriaFinanceiraProvider);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> excluirTransacao(String transacaoId) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/financeiro/transacoes/$transacaoId');
      state = const AsyncData(null);
      ref.invalidate(transacoesProvider);
      ref.invalidate(auditoriaFinanceiraProvider);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> scanConta(String base64, String mimeType) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/financeiro/scan', {
        'base64': base64,
        'mimeType': mimeType,
      });
      state = const AsyncData(null);
      return response;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<String> uploadComprovante(String base64, String mimeType, String fileName) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/financeiro/upload-comprovante', {
        'base64': base64,
        'mimeType': mimeType,
        'fileName': fileName,
      });
      state = const AsyncData(null);
      return response['url'];
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> gerarPrevisaoIa() async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/financeiro/previsao');
      state = const AsyncData(null);
      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(response['error'] ?? 'Erro desconhecido ao gerar previsão IA');
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> addTransacao(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/financeiro/transacoes', data);
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(transacoesProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateTransacao(String id, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.put('/financeiro/transacoes/$id', data);
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(transacoesProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteTransacao(String id) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.delete('/financeiro/transacoes/$id');
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(transacoesProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> addVale(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/financeiro/vales', data);
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(valesProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateVale(String id, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.put('/financeiro/vales/$id', data);
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(valesProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteVale(String id) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.delete('/financeiro/vales/$id');
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(valesProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<List<dynamic>> uploadOfx(String base64, String mimeType, String fileName) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/financeiro/ofx', {
        'base64': base64,
        'mimeType': mimeType,
        'fileName': fileName,
      });
      state = const AsyncData(null);
      return response['transactions'] as List<dynamic>;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> conciliarTransacao(String transacaoId, String ofxId, String data) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/financeiro/conciliar', {
        'transacaoId': transacaoId,
        'ofxId': ofxId,
        'data': data,
      });
      state = const AsyncData(null);
      ref.invalidate(transacoesProvider);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

final financeiroControllerProvider = NotifierProvider<FinanceiroController, AsyncValue<void>>(() {
  return FinanceiroController();
});


