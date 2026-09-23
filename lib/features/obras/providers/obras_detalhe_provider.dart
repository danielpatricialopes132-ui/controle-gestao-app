import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';
import '../../../../core/network/api_client.dart';

// Modelos simples
class DashboardData {
  final double receitasTotal;
  final double despesasTotal;
  final double lucro;
  final double margemLucro;
  final double totalOrcado;
  final double percentualCustoOrcamento;
  final List<dynamic> despesasPorCategoria;
  final String obraNome;

  DashboardData({
    required this.receitasTotal,
    required this.despesasTotal,
    required this.lucro,
    required this.margemLucro,
    required this.totalOrcado,
    required this.percentualCustoOrcamento,
    required this.despesasPorCategoria,
    required this.obraNome,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      receitasTotal: (json['financeiro']['totalReceitas'] ?? 0).toDouble(),
      despesasTotal: (json['financeiro']['totalDespesas'] ?? 0).toDouble(),
      lucro: (json['financeiro']['lucro'] ?? 0).toDouble(),
      margemLucro: (json['financeiro']['margemLucro'] ?? 0).toDouble(),
      totalOrcado: (json['financeiro']['totalOrcado'] ?? 0).toDouble(),
      percentualCustoOrcamento: (json['financeiro']['percentualCustoOrcamento'] ?? 0).toDouble(),
      despesasPorCategoria: json['despesasPorCategoria'] ?? [],
      obraNome: json['obra']['nome'] ?? '',
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


