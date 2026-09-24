import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';

final obrasProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/obras');
  return response['data'] as List<dynamic>;
});


class ObrasController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> addObra(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/obras', data);
      ref.invalidate(obrasProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateObra(String id, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      await api.put('/obras/$id', data);
      ref.invalidate(obrasProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteObra(String id) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/obras/$id');
      ref.invalidate(obrasProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final obrasControllerProvider = NotifierProvider<ObrasController, AsyncValue<void>>(() {
  return ObrasController();
});
