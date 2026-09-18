import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../data/models/fornecedor.dart';
import '../data/models/produto.dart';
import '../data/models/ordem_compra.dart';

final suprimentosProvider = ChangeNotifierProvider((ref) => SuprimentosProvider());

class SuprimentosProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Fornecedor> fornecedores = [];
  List<Produto> produtos = [];
  List<OrdemCompra> ordensCompra = [];
  bool isLoading = false;

  Future<void> fetchFornecedores() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/suprimentos/fornecedores');
      if (response is List) {
        fornecedores = response.map((json) => Fornecedor.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) print("Erro ao carregar fornecedores: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createFornecedor(Fornecedor fornecedor) async {
    try {
      await _apiClient.post('/api/suprimentos/fornecedores', body: fornecedor.toJson());
      await fetchFornecedores();
    } catch (e) {
      if (kDebugMode) print("Erro ao criar fornecedor: $e");
      rethrow;
    }
  }

  Future<void> fetchProdutos() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/suprimentos/produtos');
      if (response is List) {
        produtos = response.map((json) => Produto.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) print("Erro ao carregar produtos: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createProduto(Produto produto) async {
    try {
      await _apiClient.post('/api/suprimentos/produtos', body: produto.toJson());
      await fetchProdutos();
    } catch (e) {
      if (kDebugMode) print("Erro ao criar produto: $e");
      rethrow;
    }
  }

  Future<void> fetchOrdensCompra() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/suprimentos/ordens-compra');
      if (response is List) {
        ordensCompra = response.map((json) => OrdemCompra.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) print("Erro ao carregar ordens de compra: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createOrdemCompra(OrdemCompra ordem) async {
    try {
      await _apiClient.post('/api/suprimentos/ordens-compra', body: ordem.toJson());
      await fetchOrdensCompra();
    } catch (e) {
      if (kDebugMode) print("Erro ao criar ordem: $e");
      rethrow;
    }
  }

  Future<void> updateOrdemStatus(String id, String newStatus) async {
    try {
      await _apiClient.put('/api/suprimentos/ordens-compra/$id', body: {'status': newStatus});
      await fetchOrdensCompra();
    } catch (e) {
      if (kDebugMode) print("Erro ao atualizar ordem: $e");
      rethrow;
    }
  }
}
