import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/tenant_provider.dart';

class ObraGedController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ObraGedController(this.ref) : super(const AsyncData(null));

  Future<List<dynamic>> getDocumentos(String obraId) async {
    final token = ref.read(authTokenProvider);
    final tenant = ref.read(currentTenantProvider);
    final url = Uri.parse('http://localhost:3000/api/obras/$obraId/documentos');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      if (tenant != null) 'x-tenant-override': tenant.id,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao carregar documentos: ${response.body}');
    }
  }

  Future<void> uploadDocumento(String obraId, String nome, String tipo, String base64, String mimeType) async {
    state = const AsyncLoading();
    try {
      final token = ref.read(authTokenProvider);
      final tenant = ref.read(currentTenantProvider);
      final url = Uri.parse('http://localhost:3000/api/obras/$obraId/documentos');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          if (tenant != null) 'x-tenant-override': tenant.id,
        },
        body: jsonEncode({
          'nome': nome,
          'tipo': tipo,
          'base64': base64,
          'mimeType': mimeType,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<List<dynamic>> getCronograma(String obraId) async {
    final token = ref.read(authTokenProvider);
    final tenant = ref.read(currentTenantProvider);
    final url = Uri.parse('http://localhost:3000/api/obras/$obraId/cronograma');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      if (tenant != null) 'x-tenant-override': tenant.id,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao carregar cronograma: ${response.body}');
    }
  }

  Future<void> saveEtapaCronograma(String obraId, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final token = ref.read(authTokenProvider);
      final tenant = ref.read(currentTenantProvider);
      final url = Uri.parse('http://localhost:3000/api/obras/$obraId/cronograma');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          if (tenant != null) 'x-tenant-override': tenant.id,
        },
        body: jsonEncode(data),
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateEtapaPercentual(String obraId, String etapaId, double percentual) async {
    try {
      final token = ref.read(authTokenProvider);
      final tenant = ref.read(currentTenantProvider);
      final url = Uri.parse('http://localhost:3000/api/obras/$obraId/cronograma/$etapaId');

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          if (tenant != null) 'x-tenant-override': tenant.id,
        },
        body: jsonEncode({'percentualConclusao': percentual}),
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> gerarLinkMagicoPortal(String clienteId) async {
    state = const AsyncLoading();
    try {
      final token = ref.read(authTokenProvider);
      final tenant = ref.read(currentTenantProvider);
      final url = Uri.parse('http://localhost:3000/api/portal/generate-token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          if (tenant != null) 'x-tenant-override': tenant.id,
        },
        body: jsonEncode({'clienteId': clienteId}),
      );

      if (response.statusCode == 200) {
        state = const AsyncData(null);
        final data = jsonDecode(response.body);
        return data['token'];
      } else {
        throw Exception('Erro ao gerar token: ${response.body}');
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final obraGedControllerProvider = StateNotifierProvider<ObraGedController, AsyncValue<void>>((ref) {
  return ObraGedController(ref);
});

final documentosObraProvider = FutureProvider.family<List<dynamic>, String>((ref, obraId) async {
  return ref.watch(obraGedControllerProvider.notifier).getDocumentos(obraId);
});

final cronogramaObraProvider = FutureProvider.family<List<dynamic>, String>((ref, obraId) async {
  return ref.watch(obraGedControllerProvider.notifier).getCronograma(obraId);
});
