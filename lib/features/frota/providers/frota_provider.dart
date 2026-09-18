import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';

final equipamentosProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/equipamentos');
  return response as List<dynamic>;
});

class FrotaController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> addEquipamento(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/equipamentos', data);
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(equipamentosProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateEquipamento(String id, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.put('/equipamentos/$id', data);
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(equipamentosProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteEquipamento(String id) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.delete('/equipamentos/$id');
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(equipamentosProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> alocarEquipamento(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/equipamentos/alocacoes', data);
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(equipamentosProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> desalocarEquipamento(String id, String dataFim) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.put('/equipamentos/alocacoes', {
        'id': id,
        'dataFim': dataFim,
      });
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(equipamentosProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> addManutencao(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/equipamentos/manutencoes', data);
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(equipamentosProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateManutencaoStatus(String id, String status) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.put('/equipamentos/manutencoes', {
        'id': id,
        'status': status,
      });
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(equipamentosProvider);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

final frotaControllerProvider = NotifierProvider<FrotaController, AsyncValue<void>>(() {
  return FrotaController();
});
