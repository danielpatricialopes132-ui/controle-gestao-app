import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../shared/providers/api_client_provider.dart';

class RelatoriosService {
  final dynamic _api;
  RelatoriosService(this._api);

  Future<Map<String, dynamic>> getRelatorioGerencial({int? mes, int? ano}) async {
    String urlStr = '/relatorios/gerencial';
    if (mes != null && ano != null) {
      urlStr += '?mes=$mes&ano=$ano';
    }
    final response = await _api.get(urlStr);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGerencialObra(String obraId) async {
    final response = await _api.get('/relatorios/gerencial?obraId=$obraId');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFrequenciaPonto({String? obraId, int? mes, int? ano}) async {
    String urlStr = '/relatorios/frequencia-ponto?';
    if (obraId != null && obraId.isNotEmpty) urlStr += 'obraId=$obraId&';
    if (mes != null) urlStr += 'mes=$mes&';
    if (ano != null) urlStr += 'ano=$ano';
    final response = await _api.get(urlStr);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchDRE({int? mes, int? ano}) async {
    return getRelatorioGerencial(mes: mes, ano: ano);
  }

  Future<List<dynamic>> fetchFluxoCaixa({int meses = 6}) async {
    final response = await _api.get('/relatorios/fluxo-caixa?meses=$meses');
    return response as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchLucratividade({int? mes, int? ano}) async {
    String urlStr = '/relatorios/lucratividade';
    if (mes != null && ano != null) {
      urlStr += '?mes=$mes&ano=$ano';
    }
    final response = await _api.get(urlStr);
    return response as Map<String, dynamic>;
  }
}

final relatoriosProvider = Provider<RelatoriosService>((ref) {
  final api = ref.watch(apiClientProvider);
  return RelatoriosService(api);
});

class RelatoriosController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Map<String, dynamic>> fetchDRE({int? mes, int? ano}) async {
    return ref.read(relatoriosProvider).fetchDRE(mes: mes, ano: ano);
  }

  Future<List<dynamic>> fetchFluxoCaixa({int meses = 6}) async {
    return ref.read(relatoriosProvider).fetchFluxoCaixa(meses: meses);
  }

  Future<Map<String, dynamic>> fetchLucratividade({int? mes, int? ano}) async {
    return ref.read(relatoriosProvider).fetchLucratividade(mes: mes, ano: ano);
  }
}

final relatoriosControllerProvider = AsyncNotifierProvider<RelatoriosController, void>(() {
  return RelatoriosController();
});

class RelatorioMesAnoNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) {
    state = date;
  }
}

final relatorioMesAnoProvider = NotifierProvider<RelatorioMesAnoNotifier, DateTime>(() {
  return RelatorioMesAnoNotifier();
});

final dreProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final date = ref.watch(relatorioMesAnoProvider);
  return ref.read(relatoriosProvider).fetchDRE(mes: date.month, ano: date.year);
});

final fluxoCaixaProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(relatoriosProvider).fetchFluxoCaixa(meses: 6);
});

final lucratividadeProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final date = ref.watch(relatorioMesAnoProvider);
  return ref.read(relatoriosProvider).fetchLucratividade(mes: date.month, ano: date.year);
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
  return {'saldoAnterior': 0, 'transacoes': []};
});

class AuditoriaBuscaNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setBusca(String val) {
    state = val;
  }
}

final auditoriaConfirmarBuscaProvider = NotifierProvider<AuditoriaBuscaNotifier, String>(() {
  return AuditoriaBuscaNotifier();
});

final auditoriaConfirmarProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final busca = ref.watch(auditoriaConfirmarBuscaProvider);
  String url = '/financeiro/relatorios/auditoria-confirmar';
  if (busca.trim().isNotEmpty) {
    url += '?busca=${Uri.encodeComponent(busca.trim())}';
  }
  final response = await api.get(url);
  return response as Map<String, dynamic>;
});
