import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../../../../core/offline/sync_manager.dart';

class SuprimentosState {
  final List<dynamic> fornecedores;
  final List<dynamic> produtos;
  final List<dynamic> ordensCompra;
  final bool isLoading;

  SuprimentosState({
    this.fornecedores = const [],
    this.produtos = const [],
    this.ordensCompra = const [],
    this.isLoading = false,
  });

  SuprimentosState copyWith({
    List<dynamic>? fornecedores,
    List<dynamic>? produtos,
    List<dynamic>? ordensCompra,
    bool? isLoading,
  }) {
    return SuprimentosState(
      fornecedores: fornecedores ?? this.fornecedores,
      produtos: produtos ?? this.produtos,
      ordensCompra: ordensCompra ?? this.ordensCompra,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SuprimentosNotifier extends Notifier<SuprimentosState> {
  @override
  SuprimentosState build() {
    return SuprimentosState();
  }

  Future<void> fetchFornecedores() async {
    state = state.copyWith(isLoading: true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/suprimentos/fornecedores');
      if (response is List) {
        state = state.copyWith(fornecedores: response);
      }
    } catch (e) {
      if (kDebugMode) print("Erro ao carregar fornecedores: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> createFornecedor(Map<String, dynamic> fornecedor) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/suprimentos/fornecedores', fornecedor);
      await fetchFornecedores();
    } catch (e) {
      if (kDebugMode) print("Erro ao criar fornecedor: $e");
      rethrow;
    }
  }

  Future<void> fetchProdutos() async {
    state = state.copyWith(isLoading: true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/suprimentos/produtos');
      if (response is List) {
        state = state.copyWith(produtos: response);
      }
    } catch (e) {
      if (kDebugMode) print("Erro ao carregar produtos: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> createProduto(Map<String, dynamic> produto) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/suprimentos/produtos', produto);
      await fetchProdutos();
    } catch (e) {
      if (kDebugMode) print("Erro ao criar produto: $e");
      rethrow;
    }
  }

  Future<void> fetchOrdensCompra() async {
    state = state.copyWith(isLoading: true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/suprimentos/ordens-compra');
      if (response is List) {
        state = state.copyWith(ordensCompra: response);
      }
    } catch (e) {
      if (kDebugMode) print("Erro ao carregar ordens de compra: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> createOrdemCompra(Map<String, dynamic> ordem) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/suprimentos/ordens-compra', ordem);
      await fetchOrdensCompra();
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused') || e.toString().contains('Erro na requisição')) {
        final syncManager = ref.read(syncManagerProvider);
        await syncManager.enqueue('POST', '/suprimentos/ordens-compra', ordem);
        return;
      }
      if (kDebugMode) print("Erro ao criar ordem: $e");
      rethrow;
    }
  }

  Future<void> updateOrdemStatus(String id, String newStatus) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put('/suprimentos/ordens-compra/$id', {'status': newStatus});
      await fetchOrdensCompra();
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused') || e.toString().contains('Erro na requisição')) {
        final syncManager = ref.read(syncManagerProvider);
        await syncManager.enqueue('PUT', '/suprimentos/ordens-compra/$id', {'status': newStatus});
        return;
      }
      if (kDebugMode) print("Erro ao atualizar ordem: $e");
      rethrow;
    }
  }
}

final suprimentosProvider = NotifierProvider<SuprimentosNotifier, SuprimentosState>(() {
  return SuprimentosNotifier();
});
