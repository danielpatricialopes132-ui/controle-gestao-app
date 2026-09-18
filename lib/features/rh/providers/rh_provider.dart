import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';

final funcionariosProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/rh/funcionarios');
  return response as List<dynamic>;
});

final valesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/rh/vales');
  return response as List<dynamic>;
});

class RhController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> saveFuncionario(Map<String, dynamic> data, {String? id}) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      dynamic response;
      if (id == null) {
        response = await api.post('/rh/funcionarios', data);
      } else {
        response = await api.put('/rh/funcionarios/$id', data);
      }
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(funcionariosProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteFuncionario(String id) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.delete('/rh/funcionarios/$id');
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(funcionariosProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<List<dynamic>> getApontamentos(String obraId, String dataIso) async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/rh/apontamentos?obraId=$obraId&data=$dataIso');
    return response as List<dynamic>;
  }

  Future<void> saveApontamentosLote(String obraId, String dataIso, List<Map<String, dynamic>> apontamentos) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final payload = {
        'obraId': obraId,
        'data': dataIso,
        'apontamentos': apontamentos,
      };
      final response = await api.post('/rh/apontamentos', payload);
      if (response['success'] == true) {
        state = const AsyncData(null);
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
      final response = await api.post('/rh/vales', data);
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
}

final rhControllerProvider = NotifierProvider<RhController, AsyncValue<void>>(() {
  return RhController();
});
