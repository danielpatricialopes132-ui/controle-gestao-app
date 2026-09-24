import 'package:flutter/foundation.dart';
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
    final fin = json['financeiro'] as Map<String, dynamic>? ?? {};
    final ob = json['obra'] as Map<String, dynamic>? ?? {};

    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return DashboardData(
      receitasTotal: parseNum(fin['totalReceitas']),
      despesasTotal: parseNum(fin['totalDespesas']),
      lucro: parseNum(fin['lucro']),
      margemLucro: parseNum(fin['margemLucro']),
      totalOrcado: parseNum(fin['totalOrcado']),
      percentualCustoOrcamento: parseNum(fin['percentualCustoOrcamento']),
      despesasPorCategoria: json['despesasPorCategoria'] as List<dynamic>? ?? [],
      obraNome: ob['nome'] as String? ?? json['nome'] as String? ?? '',
    );
  }
}

// Provider de leitura do Dashboard
final obraDashboardProvider = FutureProvider.family<DashboardData, String>((ref, obraId) async {
  final apiClient = ref.watch(apiClientProvider);
  
  try {
    final response = await apiClient.get('/obras/$obraId/dashboard');
    if (response != null) {
      if (response['success'] == true && response['data'] != null) {
        final d = response['data']['dashboard'] ?? response['data'];
        return DashboardData.fromJson(d);
      } else if (response is Map<String, dynamic>) {
        return DashboardData.fromJson(response);
      }
    }
    throw Exception(response?['error'] ?? 'Dados não encontrados no dashboard');
  } catch (e) {
    debugPrint('Erro em obraDashboardProvider: $e');
    rethrow;
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

// Provider para listar adendos e contrato da obra
final obraAdendosProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, obraId) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.get('/obras/$obraId/adendos');
    if (response != null && response['success'] == true) {
      return response['data'] as Map<String, dynamic>;
    }
  } catch (_) {}
  return {'contrato': null, 'adendos': []};
});


