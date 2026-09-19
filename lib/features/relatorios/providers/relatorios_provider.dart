import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../shared/providers/api_client_provider.dart';

class RelatoriosController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Map<String, dynamic>> fetchDRE({int? mes, int? ano}) async {
    String urlStr = '/relatorios/gerencial';
    if (mes != null && ano != null) {
      urlStr += '?mes=$mes&ano=$ano';
    }
    
    final api = ref.read(apiClientProvider);
    final response = await api.get(urlStr);
    return response as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchFluxoCaixa({int meses = 6}) async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/relatorios/fluxo-caixa?meses=$meses');
    return response as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchLucratividade({int? mes, int? ano}) async {
    String urlStr = '/relatorios/lucratividade';
    if (mes != null && ano != null) {
      urlStr += '?mes=$mes&ano=$ano';
    }
    
    final api = ref.read(apiClientProvider);
    final response = await api.get(urlStr);
    return response as Map<String, dynamic>;
  }
}

final relatoriosControllerProvider = AsyncNotifierProvider<RelatoriosController, void>(() {
  return RelatoriosController();
});

class RelatorioMesAnoNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
}

final relatorioMesAnoProvider = NotifierProvider<RelatorioMesAnoNotifier, DateTime>(() {
  return RelatorioMesAnoNotifier();
});

final dreProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final date = ref.watch(relatorioMesAnoProvider);
  return ref.read(relatoriosControllerProvider.notifier).fetchDRE(mes: date.month, ano: date.year);
});

final fluxoCaixaProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(relatoriosControllerProvider.notifier).fetchFluxoCaixa(meses: 6);
});

final lucratividadeProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final date = ref.watch(relatorioMesAnoProvider);
  return ref.read(relatoriosControllerProvider.notifier).fetchLucratividade(mes: date.month, ano: date.year);
});

class LivroCaixaFilters {
  final DateTime dataInicio;
  final DateTime dataFim;
  final String? contaBancariaId;

  LivroCaixaFilters({
    required this.dataInicio,
    required this.dataFim,
    this.contaBancariaId,
  });

  LivroCaixaFilters copyWith({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? contaBancariaId,
  }) {
    return LivroCaixaFilters(
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      // If we want to allow nulling contaBancariaId, we can't do it simply with copyWith unless we use a wrapper, 
      // but here we just assume value can be null in the argument. To allow setting to null when copyWith is called, 
      // wait, the dropdown passes null! So we should allow it. But Dart doesn't distinguish between absent and null well.
      // We will just do a simple check. Actually, in dropdown we just pass the new value.
      contaBancariaId: contaBancariaId, 
    );
  }
}

class LivroCaixaFiltersNotifier extends Notifier<LivroCaixaFilters> {
  @override
  LivroCaixaFilters build() {
    final now = DateTime.now();
    return LivroCaixaFilters(
      dataInicio: DateTime(now.year, now.month, 1),
      dataFim: DateTime(now.year, now.month + 1, 0),
    );
  }
}

final livroCaixaFiltersProvider = NotifierProvider<LivroCaixaFiltersNotifier, LivroCaixaFilters>(() {
  return LivroCaixaFiltersNotifier();
});

final livroCaixaProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final filters = ref.watch(livroCaixaFiltersProvider);
  final api = ref.watch(apiClientProvider);
  
  String url = '/relatorios/livro-caixa?inicio=${filters.dataInicio.toIso8601String()}&fim=${filters.dataFim.toIso8601String()}';
  if (filters.contaBancariaId != null) {
    url += '&contaBancariaId=${filters.contaBancariaId}';
  }
  
  final response = await api.get(url);
  if (response is Map<String, dynamic>) return response;
  // Fallback
  return {'saldoAnterior': 0, 'transacoes': []};
});

