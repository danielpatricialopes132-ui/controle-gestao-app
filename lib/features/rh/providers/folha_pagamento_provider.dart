import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';

class FolhaPagamentoState {
  final DateTime dataInicio;
  final DateTime dataFim;

  FolhaPagamentoState({
    required this.dataInicio,
    required this.dataFim,
  });

  FolhaPagamentoState copyWith({
    DateTime? dataInicio,
    DateTime? dataFim,
  }) {
    return FolhaPagamentoState(
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
    );
  }
}

class FolhaFiltersNotifier extends Notifier<FolhaPagamentoState> {
  @override
  FolhaPagamentoState build() {
    final now = DateTime.now();
    return FolhaPagamentoState(
      dataInicio: DateTime(now.year, now.month, 1),
      dataFim: DateTime(now.year, now.month + 1, 0),
    );
  }
}

final folhaFiltersProvider = NotifierProvider<FolhaFiltersNotifier, FolhaPagamentoState>(() {
  return FolhaFiltersNotifier();
});

final folhaPagamentoProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final filters = ref.watch(folhaFiltersProvider);
  
  final res = await api.get(
    '/rh/folha-pagamento?dataInicio=${filters.dataInicio.toIso8601String()}&dataFim=${filters.dataFim.toIso8601String()}'
  );
  
  return res['data'] ?? [];
});

class FolhaPagamentoController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> gerarPagamentos(List<dynamic> items, String descricaoMensagem) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/rh/folha-pagamento/gerar', {
        'items': items,
        'descricaoMensagem': descricaoMensagem,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final folhaPagamentoControllerProvider = NotifierProvider<FolhaPagamentoController, AsyncValue<void>>(() {
  return FolhaPagamentoController();
});
