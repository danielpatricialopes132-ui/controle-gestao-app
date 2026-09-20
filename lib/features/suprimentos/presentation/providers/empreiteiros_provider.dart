import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_client_provider.dart';

class ContratosEmpreiteiroState {
  final List<dynamic> contratos;
  final bool isLoading;
  final String? error;

  ContratosEmpreiteiroState({
    this.contratos = const [],
    this.isLoading = false,
    this.error,
  });

  ContratosEmpreiteiroState copyWith({
    List<dynamic>? contratos,
    bool? isLoading,
    String? error,
  }) {
    return ContratosEmpreiteiroState(
      contratos: contratos ?? this.contratos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ContratosEmpreiteiroNotifier extends Notifier<ContratosEmpreiteiroState> {
  @override
  ContratosEmpreiteiroState build() {
    return ContratosEmpreiteiroState();
  }

  Future<void> fetchContratos({String? obraId, String? fornecedorId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      final queryParams = <String, String>{};
      if (obraId != null && obraId.isNotEmpty) queryParams['obraId'] = obraId;
      if (fornecedorId != null && fornecedorId.isNotEmpty) queryParams['fornecedorId'] = fornecedorId;

      final queryStr = queryParams.isNotEmpty 
          ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}' 
          : '';

      final response = await api.get('/empreiteiros/contratos$queryStr');
      if (response is List) {
        state = state.copyWith(contratos: response, isLoading: false);
      } else {
        state = state.copyWith(contratos: [], isLoading: false);
      }
    } catch (e) {
      if (kDebugMode) print("Erro ao carregar contratos de empreiteiros: $e");
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createContrato(Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.post('/empreiteiros/contratos', data);
    await fetchContratos();
  }

  Future<void> createAdendo(String contratoId, Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.post('/empreiteiros/contratos/$contratoId/adendos', data);
    await fetchContratos();
  }

  Future<void> createMedicao(String contratoId, Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.post('/empreiteiros/contratos/$contratoId/medicoes', data);
    await fetchContratos();
  }
}

final contratosEmpreiteiroProvider =
    NotifierProvider<ContratosEmpreiteiroNotifier, ContratosEmpreiteiroState>(() {
  return ContratosEmpreiteiroNotifier();
});
