import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';

class ImportacaoCsvController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<Map<String, dynamic>> analisarCsv(String base64, String mimeType) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/financeiro/importacao-csv/analise', {
        'base64': 'data:$mimeType;base64,$base64',
      });
      state = const AsyncData(null);
      return response;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> efetivarImportacao(List<Map<String, dynamic>> rows) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/financeiro/importacao-csv/efetivar', {
        'rows': rows,
      });
      state = const AsyncData(null);
      return response;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final importacaoCsvProvider = NotifierProvider<ImportacaoCsvController, AsyncValue<void>>(() {
  return ImportacaoCsvController();
});
