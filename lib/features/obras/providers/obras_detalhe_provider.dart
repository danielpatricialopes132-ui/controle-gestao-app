import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';
import '../../../../core/network/api_client.dart';

// Modelos simples
class DashboardData {
  final double receitasContrato;
  final double receitasAdendos;
  final double receitasTotal;
  final double despesasPagas;
  final double despesasPendentes;
  final double despesasMaoDeObra;
  final double despesasTotal;
  final double lucroPresumido;

  DashboardData({
    required this.receitasContrato,
    required this.receitasAdendos,
    required this.receitasTotal,
    required this.despesasPagas,
    required this.despesasPendentes,
    required this.despesasMaoDeObra,
    required this.despesasTotal,
    required this.lucroPresumido,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      receitasContrato: (json['receitas']['contratoPrincipal'] ?? 0).toDouble(),
      receitasAdendos: (json['receitas']['adendos'] ?? 0).toDouble(),
      receitasTotal: (json['receitas']['total'] ?? 0).toDouble(),
      despesasPagas: (json['despesas']['pagas'] ?? 0).toDouble(),
      despesasPendentes: (json['despesas']['pendentes'] ?? 0).toDouble(),
      despesasMaoDeObra: (json['despesas']['maoDeObra'] ?? 0).toDouble(),
      despesasTotal: (json['despesas']['total'] ?? 0).toDouble(),
      lucroPresumido: (json['lucroPresumido'] ?? 0).toDouble(),
    );
  }
}

// Provider de leitura do Dashboard
final obraDashboardProvider = FutureProvider.family<DashboardData, String>((ref, obraId) async {
  final apiClient = ref.watch(apiClientProvider);
  
  final response = await apiClient.get('/obras/$obraId/dashboard');
  if (response['success'] == true) {
    return DashboardData.fromJson(response['data']['dashboard']);
  } else {
    throw Exception(response['error'] ?? 'Falha ao carregar dashboard da obra');
  }
});

// Controller para Adendos
class AdendoController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> addAdendo({
    required String obraId,
    required String descricao,
    required String valor,
  }) async {
    state = const AsyncLoading();
    try {
      final apiClient = ref.read(apiClientProvider);
      
      final body = {
        'descricao': descricao,
        'valor': double.parse(valor.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim()),
      };
      
      final response = await apiClient.post('/obras/$obraId/adendos', body);
      
      if (response['success'] == true) {
        state = const AsyncData(null);
        // Atualiza os dados do dashboard
        ref.invalidate(obraDashboardProvider(obraId));
      } else {
        throw Exception(response['error'] ?? 'Erro ao adicionar adendo');
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

final adendoControllerProvider = NotifierProvider<AdendoController, AsyncValue<void>>(() {
  return AdendoController();
});


