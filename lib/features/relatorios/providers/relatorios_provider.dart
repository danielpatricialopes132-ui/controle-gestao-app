import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/tenant_provider.dart';

class RelatoriosController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  RelatoriosController(this.ref) : super(const AsyncData(null));

  Future<Map<String, dynamic>> fetchDRE({int? mes, int? ano}) async {
    final token = ref.read(authTokenProvider);
    final tenant = ref.read(currentTenantProvider);
    
    String urlStr = 'http://localhost:3000/api/relatorios/gerencial';
    if (mes != null && ano != null) {
      urlStr += '?mes=$mes&ano=$ano';
    }
    
    final url = Uri.parse(urlStr);
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      if (tenant != null) 'x-tenant-override': tenant.id,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao carregar DRE: ${response.body}');
    }
  }

  Future<List<dynamic>> fetchFluxoCaixa({int meses = 6}) async {
    final token = ref.read(authTokenProvider);
    final tenant = ref.read(currentTenantProvider);
    
    final url = Uri.parse('http://localhost:3000/api/relatorios/fluxo-caixa?meses=$meses');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      if (tenant != null) 'x-tenant-override': tenant.id,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao carregar Fluxo de Caixa: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchLucratividade({int? mes, int? ano}) async {
    final token = ref.read(authTokenProvider);
    final tenant = ref.read(currentTenantProvider);
    
    String urlStr = 'http://localhost:3000/api/relatorios/lucratividade';
    if (mes != null && ano != null) {
      urlStr += '?mes=$mes&ano=$ano';
    }
    
    final url = Uri.parse(urlStr);
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      if (tenant != null) 'x-tenant-override': tenant.id,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao carregar Lucratividade: ${response.body}');
    }
  }
}

final relatoriosControllerProvider = StateNotifierProvider<RelatoriosController, AsyncValue<void>>((ref) {
  return RelatoriosController(ref);
});

// A simple state provider for current filter month/year
final relatorioMesAnoProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dreProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final date = ref.watch(relatorioMesAnoProvider);
  return ref.read(relatoriosControllerProvider.notifier).fetchDRE(mes: date.month, ano: date.year);
});

final fluxoCaixaProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(relatoriosControllerProvider.notifier).fetchFluxoCaixa(meses: 6);
});

final lucratividadeProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final date = ref.watch(relatorioMesAnoProvider);
  return ref.read(relatoriosControllerProvider.notifier).fetchLucratividade(mes: date.month, ano: date.year);
});
