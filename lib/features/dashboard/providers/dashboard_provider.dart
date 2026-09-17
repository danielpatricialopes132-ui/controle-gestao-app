import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/tenant_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/providers/api_client_provider.dart';

final dashboardSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/dashboard/summary');
  return response['data'];
});
