import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';

// Obras
final obrasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  
  try {
    final response = await apiClient.get('/obras');
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data']);
    }
    throw Exception(response['error'] ?? 'Erro desconhecido');
  } catch (e) {
    throw Exception('Falha ao carregar obras: $e');
  }
});

// Funcionários
final funcionariosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  
  try {
    final response = await apiClient.get('/funcionarios');
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data']);
    }
    throw Exception(response['error'] ?? 'Erro desconhecido');
  } catch (e) {
    throw Exception('Falha ao carregar funcionários: $e');
  }
});

class FuncionarioController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> addFuncionario({
    required String nome,
    required String cargo,
    String? salario,
    String? valorDiariaMotorista,
  }) async {
    state = const AsyncLoading();
    try {
      final apiClient = ref.read(apiClientProvider);
      
      final body = {
        'nome': nome,
        'cargo': cargo,
        if (salario != null && salario.isNotEmpty) 'salario': salario.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim(),
        if (valorDiariaMotorista != null && valorDiariaMotorista.isNotEmpty) 'valorDiariaMotorista': valorDiariaMotorista.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim(),
      };
      
      final response = await apiClient.post('/funcionarios', body);
      
      if (response['success'] == true) {
        state = const AsyncData(null);
        // Atualiza a lista
        ref.invalidate(funcionariosProvider);
      } else {
        throw Exception(response['error'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateFuncionario({
    required String id,
    required String nome,
    required String cargo,
    String? salario,
    String? valorDiariaMotorista,
  }) async {
    state = const AsyncLoading();
    try {
      final apiClient = ref.read(apiClientProvider);
      
      final body = {
        'nome': nome,
        'cargo': cargo,
        if (salario != null && salario.isNotEmpty) 'valorPadrao': salario.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim(),
        if (valorDiariaMotorista != null && valorDiariaMotorista.isNotEmpty) 'valorPadrao': valorDiariaMotorista.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim(),
      };
      
      final response = await apiClient.put('/rh/funcionarios/$id', body);
      
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(funcionariosProvider);
      } else {
        throw Exception(response['error'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteFuncionario(String id) async {
    state = const AsyncLoading();
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.delete('/rh/funcionarios/$id');
      
      if (response['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(funcionariosProvider);
      } else {
        throw Exception(response['error'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

final funcionarioControllerProvider = NotifierProvider<FuncionarioController, AsyncValue<void>>(() {
  return FuncionarioController();
});

class DiarioObraController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> salvarDiarioBatch({
    required String obraId,
    required DateTime data,
    required List<Map<String, dynamic>> presencas,
  }) async {
    state = const AsyncLoading();
    try {
      final apiClient = ref.read(apiClientProvider);
      
      final dataIso = data.toIso8601String();
      
      final body = {
        'presencas': presencas.map((p) => {
          'funcionarioId': p['funcionarioId'],
          'status': p['status'],
          'obraId': obraId,
          'data': dataIso,
        }).toList()
      };
      
      final response = await apiClient.post('/presencas/batch', body);
      
      if (response['success'] == true) {
        state = const AsyncData(null);
      } else {
        throw Exception(response['error'] ?? 'Erro desconhecido ao salvar diário');
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

final diarioObraControllerProvider = NotifierProvider<DiarioObraController, AsyncValue<void>>(() {
  return DiarioObraController();
});


