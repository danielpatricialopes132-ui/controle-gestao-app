import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

// Provider to hold filter state
class LivroCaixaFilters {
  final DateTime dataInicio;
  final DateTime dataFim;
  final String? contaBancariaId;

  LivroCaixaFilters({
    required this.dataInicio,
    required this.dataFim,
    this.contaBancariaId,
  });

  LivroCaixaFilters copyWith({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? contaBancariaId,
  }) {
    return LivroCaixaFilters(
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      contaBancariaId: contaBancariaId ?? this.contaBancariaId,
    );
  }
}

class LivroCaixaFiltersNotifier extends Notifier<LivroCaixaFilters> {
  @override
  LivroCaixaFilters build() {
    final now = DateTime.now();
    return LivroCaixaFilters(
      dataInicio: DateTime(now.year, now.month, 1),
      dataFim: DateTime(now.year, now.month + 1, 0),
    );
  }
}

final livroCaixaFiltersProvider = NotifierProvider<LivroCaixaFiltersNotifier, LivroCaixaFilters>(() {
  return LivroCaixaFiltersNotifier();
});

// Provider to fetch data
final livroCaixaProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final filters = ref.watch(livroCaixaFiltersProvider);

  String url = '/financeiro/relatorios/livro-caixa?dataInicio=${filters.dataInicio.toIso8601String()}&dataFim=${filters.dataFim.toIso8601String()}';
  if (filters.contaBancariaId != null && filters.contaBancariaId!.isNotEmpty) {
    url += '&contaBancariaId=${filters.contaBancariaId}';
  }

  final response = await api.get(url);
  return response as Map<String, dynamic>;
});

final relatoriosProvider = Provider((ref) => RelatoriosService(ref));

class RelatoriosService {
  final Ref ref;
  RelatoriosService(this.ref);

  Future<Map<String, dynamic>> getExtratoBancario({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? obraId,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    
    String query = '?dataInicio=${dataInicio.toIso8601String()}&dataFim=${dataFim.toIso8601String()}';
    if (obraId != null && obraId.isNotEmpty) {
      query += '&obraId=$obraId';
    }

    final response = await apiClient.get('/api/relatorios/extrato$query');
    return response['data'];
  }

  Future<Map<String, dynamic>> getEvolucaoFinanceiraObra({
    required String obraId,
    required String periodo,
    required int ano,
    int? mes,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    
    String query = '?obraId=$obraId&periodo=$periodo&ano=$ano';
    if (mes != null) {
      query += '&mes=$mes';
    }

    final response = await apiClient.get('/api/relatorios/obra-financeiro$query');
    return response['data'];
  }

  Future<Map<String, dynamic>> getFrequenciaPonto({
    int? mes,
    int? ano,
    String? obraId,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    String query = '?';
    if (mes != null) query += 'mes=$mes&';
    if (ano != null) query += 'ano=$ano&';
    if (obraId != null) query += 'obraId=$obraId';

    final response = await apiClient.get('/api/relatorios/frequencia$query');
    return {'funcionarios': response['data'] ?? []};
  }

  Future<Map<String, dynamic>> getFolhaPagamento({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    String query = '?dataInicio=${dataInicio.toIso8601String()}&dataFim=${dataFim.toIso8601String()}';

    final response = await apiClient.get('/api/relatorios/folha-pagamento$query');
    return {'funcionarios': response['data'] ?? []};
  }
  
  Future<void> pagarFolha(List<Map<String, dynamic>> pagamentos) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.post('/api/relatorios/folha-pagamento/pagar', {
      'pagamentos': pagamentos,
    });
  }

  Future<Map<String, dynamic>> getGerencialObra(String obraId) async {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get('/api/relatorios/gerencial-obra/$obraId');
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> getRelatorioGerencial({int? mes, int? ano}) async {
    final apiClient = ref.read(apiClientProvider);
    String query = '';
    if (mes != null && ano != null) {
      query = '?mes=$mes&ano=$ano';
    } else if (mes != null) {
      query = '?mes=$mes';
    } else if (ano != null) {
      query = '?ano=$ano';
    }
    final response = await apiClient.get('/financeiro/relatorios/gerencial$query');
    return response['data'] ?? {};
  }

  Future<void> exportarLivroCaixaCsv(Map<String, dynamic> data) async {
    final transacoes = data['transacoes'] as List<dynamic>;
    final saldoAnterior = data['saldoAnterior'];

    List<List<dynamic>> rows = [];
    rows.add(['Data', 'Descrição/Histórico', 'Categoria', 'Conta', 'Entrada (R\$)', 'Saída (R\$)', 'Saldo Acumulado (R\$)']);
    
    // Linha de Saldo Anterior
    rows.add(['', 'SALDO ANTERIOR', '', '', '', '', saldoAnterior]);

    for (var t in transacoes) {
      final date = DateTime.parse(t['dataVencimento']);
      final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      
      final isReceita = t['tipo'] == 'RECEITA';
      final entrada = isReceita ? t['valorFormatado'] : '';
      final saida = !isReceita ? t['valorFormatado'] : '';
      
      final categoria = t['categoriaFk']?['descricao'] ?? t['categoriaFk']?['nome'] ?? '';
      final conta = t['contaBancaria']?['nome'] ?? '';
      
      rows.add([
        dateStr,
        t['descricao'],
        categoria,
        conta,
        entrada,
        saida,
        t['saldoAcumulado']
      ]);
    }

    String csvData = csv.encode(rows);

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/livro_caixa_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(path)], text: 'Relatório Livro Caixa');
  }
}

