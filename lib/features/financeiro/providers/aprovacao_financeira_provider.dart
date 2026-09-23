import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';

class AprovacaoFinanceiraState {
  final bool isLoading;
  final String? error;
  final List<dynamic> transacoesPendentes;

  AprovacaoFinanceiraState({
    this.isLoading = false,
    this.error,
    this.transacoesPendentes = const [],
  });

  AprovacaoFinanceiraState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? transacoesPendentes,
  }) {
    return AprovacaoFinanceiraState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      transacoesPendentes: transacoesPendentes ?? this.transacoesPendentes,
    );
  }
}

class AprovacaoFinanceiraNotifier extends Notifier<AprovacaoFinanceiraState> {
  @override
  AprovacaoFinanceiraState build() {
    return AprovacaoFinanceiraState();
  }

  Future<void> fetchPendentes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/financeiro/transacoes?statusAprovacao=PENDENTE');
      
      if (response != null && response['data'] != null) {
        final data = response['data'] as List;
        state = state.copyWith(isLoading: false, transacoesPendentes: data);
      } else {
        throw Exception('Formato de resposta inválido');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> aprovarTransacoes(List<String> ids) async {
    return _atualizarStatusMassa(ids, 'APROVADO');
  }

  Future<bool> rejeitarTransacoes(List<String> ids) async {
    return _atualizarStatusMassa(ids, 'REJEITADO');
  }

  Future<bool> _atualizarStatusMassa(List<String> ids, String acao) async {
    try {
      final api = ref.read(apiClientProvider);
      
      final response = await api.put(
        '/financeiro/transacoes/aprovacao-massa',
        {
          'transacoesIds': ids,
          'acao': acao,
        },
      );

      if (response != null) {
        // Remove as atualizadas da lista local
        final pendentesAtualizadas = state.transacoesPendentes
            .where((t) => !ids.contains(t['id']))
            .toList();
        state = state.copyWith(transacoesPendentes: pendentesAtualizadas);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final aprovacaoFinanceiraProvider = NotifierProvider<AprovacaoFinanceiraNotifier, AprovacaoFinanceiraState>(() {
  return AprovacaoFinanceiraNotifier();
});
