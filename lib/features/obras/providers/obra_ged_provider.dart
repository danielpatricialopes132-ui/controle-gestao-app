import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';
import '../../../shared/providers/api_client_provider.dart';
import '../../../core/offline/sync_manager.dart';

class ObraGedController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<List<dynamic>> getDocumentos(String obraId) async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/obras/$obraId/documentos');
    return response as List<dynamic>;
  }

  Future<void> uploadDocumento(String obraId, String nome, String tipo, String base64, String mimeType) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/obras/$obraId/documentos', {
        'nome': nome,
        'tipo': tipo,
        'base64': base64,
        'mimeType': mimeType,
      });
      state = const AsyncData(null);
    } catch (e, st) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        try {
          final syncManager = ref.read(syncManagerProvider);
          await syncManager.enqueue('POST', '/obras/$obraId/documentos', {
            'nome': nome,
            'tipo': tipo,
            'base64': base64,
            'mimeType': mimeType,
          });
          state = const AsyncData(null); // Sucesso "Offline"
          return;
        } catch (syncError) {
          state = AsyncError(syncError, st);
          rethrow;
        }
      }
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<List<dynamic>> getCronograma(String obraId) async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/obras/$obraId/cronograma');
    return response as List<dynamic>;
  }

  Future<void> saveEtapaCronograma(String obraId, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/obras/$obraId/cronograma', data);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateEtapaPercentual(String obraId, String etapaId, double percentual) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/obras/$obraId/cronograma/$etapaId', {'percentualConclusao': percentual});
    } catch (e) {
      rethrow;
    }
  }

  Future<String> gerarLinkMagicoPortal(String clienteId) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.post('/portal/generate-token', {'clienteId': clienteId});
      
      state = const AsyncData(null);
      return data['token'];
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final obraGedControllerProvider = AsyncNotifierProvider<ObraGedController, void>(() {
  return ObraGedController();
});

final documentosObraProvider = FutureProvider.family<List<dynamic>, String>((ref, obraId) async {
  return ref.watch(obraGedControllerProvider.notifier).getDocumentos(obraId);
});

final cronogramaObraProvider = FutureProvider.family<List<dynamic>, String>((ref, obraId) async {
  return ref.watch(obraGedControllerProvider.notifier).getCronograma(obraId);
});
