import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';

final dashboardSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/dashboard/summary');
  return response['data'];
});

final dreProvider = FutureProvider.family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final api = ref.watch(apiClientProvider);
  String query = '';
  if (params['dataInicio'] != null) query += 'dataInicio=${params['dataInicio']}&';
  if (params['dataFim'] != null) query += 'dataFim=${params['dataFim']}';
  final response = await api.get('/financeiro/relatorios/dre?$query');
  return response;
});

final extratoProvider = FutureProvider.family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final api = ref.watch(apiClientProvider);
  String query = '';
  if (params['contaBancariaId'] != null) query += 'contaBancariaId=${params['contaBancariaId']}&';
  if (params['dataInicio'] != null) query += 'dataInicio=${params['dataInicio']}&';
  if (params['dataFim'] != null) query += 'dataFim=${params['dataFim']}';
  final response = await api.get('/financeiro/relatorios/extrato?$query');
  return response;
});
