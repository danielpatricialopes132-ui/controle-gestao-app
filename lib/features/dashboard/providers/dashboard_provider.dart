import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';

final dashboardSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/dashboard/summary');
  return response['data'];
});

final dreRelatorioProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, query) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/financeiro/relatorios/dre?$query');
  return response;
});

final extratoProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, query) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/financeiro/relatorios/extrato?$query');
  return response;
});
