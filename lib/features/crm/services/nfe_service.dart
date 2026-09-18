import 'package:dio/dio.dart';

class NfeService {
  final Dio _dio;

  NfeService(this._dio);

  Future<Map<String, dynamic>> emitirNfe({
    required String obraId,
    required String clienteId,
    required double valor,
  }) async {
    try {
      final response = await _dio.post('/nfe/emitir', data: {
        'obraId': obraId,
        'clienteId': clienteId,
        'valor': valor,
      });
      return response.data;
    } catch (e) {
      throw Exception('Erro ao emitir NFS-e: $e');
    }
  }

  Future<List<dynamic>> listarNotasDaObra(String obraId) async {
    try {
      final response = await _dio.get('/nfe/obra/$obraId');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao buscar notas fiscais: $e');
    }
  }
}
