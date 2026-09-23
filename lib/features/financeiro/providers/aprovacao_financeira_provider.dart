import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../../core/config/env_config.dart';
import '../models/transacao_financeira.dart';

class AprovacaoFinanceiraState {
  final bool isLoading;
  final String? error;
  final List<TransacaoFinanceira> transacoesPendentes;

  AprovacaoFinanceiraState({
    this.isLoading = false,
    this.error,
    this.transacoesPendentes = const [],
  });

  AprovacaoFinanceiraState copyWith({
    bool? isLoading,
    String? error,
    List<TransacaoFinanceira>? transacoesPendentes,
  }) {
    return AprovacaoFinanceiraState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      transacoesPendentes: transacoesPendentes ?? this.transacoesPendentes,
    );
  }
}

class AprovacaoFinanceiraNotifier extends StateNotifier<AprovacaoFinanceiraState> {
  final Ref ref;

  AprovacaoFinanceiraNotifier(this.ref) : super(AprovacaoFinanceiraState());

  Future<void> fetchPendentes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await ref.read(authProvider.notifier).getToken();
      if (token == null) throw Exception('Usuário não autenticado');

      final url = Uri.parse('${EnvConfig.apiUrl}/financeiro/transacoes?statusAprovacao=PENDENTE');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        final list = data.map((e) => TransacaoFinanceira.fromJson(e)).toList();
        state = state.copyWith(isLoading: false, transacoesPendentes: list);
      } else {
        throw Exception('Erro ao buscar transações pendentes: ${response.body}');
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
      final token = await ref.read(authProvider.notifier).getToken();
      if (token == null) return false;

      final url = Uri.parse('${EnvConfig.apiUrl}/financeiro/transacoes/aprovacao-massa');
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'transacoesIds': ids,
          'acao': acao,
        }),
      );

      if (response.statusCode == 200) {
        // Remove as atualizadas da lista local
        final pendentesAtualizadas = state.transacoesPendentes
            .where((t) => !ids.contains(t.id))
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

final aprovacaoFinanceiraProvider =
    StateNotifierProvider<AprovacaoFinanceiraNotifier, AprovacaoFinanceiraState>((ref) {
  return AprovacaoFinanceiraNotifier(ref);
});
