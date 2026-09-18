import 'fornecedor.dart';
import 'produto.dart';

class OrdemCompraItem {
  final String id;
  final String produtoId;
  final Produto? produto;
  final double quantidade;
  final double precoUnitario;

  OrdemCompraItem({
    required this.id,
    required this.produtoId,
    this.produto,
    required this.quantidade,
    required this.precoUnitario,
  });

  factory OrdemCompraItem.fromJson(Map<String, dynamic> json) {
    return OrdemCompraItem(
      id: json['id'],
      produtoId: json['produtoId'],
      produto: json['produto'] != null ? Produto.fromJson(json['produto']) : null,
      quantidade: double.tryParse(json['quantidade']?.toString() ?? '0') ?? 0.0,
      precoUnitario: double.tryParse(json['precoUnitario']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'produtoId': produtoId,
      'quantidade': quantidade,
      'precoUnitario': precoUnitario,
    };
  }
}

class OrdemCompra {
  final String id;
  final int numero;
  final String fornecedorId;
  final Fornecedor? fornecedor;
  final String? obraId;
  final String status;
  final double valorTotal;
  final DateTime? dataPrevisao;
  final DateTime? dataEntrega;
  final List<OrdemCompraItem> itens;

  OrdemCompra({
    required this.id,
    required this.numero,
    required this.fornecedorId,
    this.fornecedor,
    this.obraId,
    required this.status,
    this.valorTotal = 0.0,
    this.dataPrevisao,
    this.dataEntrega,
    required this.itens,
  });

  factory OrdemCompra.fromJson(Map<String, dynamic> json) {
    return OrdemCompra(
      id: json['id'],
      numero: json['numero'] ?? 0,
      fornecedorId: json['fornecedorId'],
      fornecedor: json['fornecedor'] != null ? Fornecedor.fromJson(json['fornecedor']) : null,
      obraId: json['obraId'],
      status: json['status'] ?? 'PENDENTE',
      valorTotal: double.tryParse(json['valorTotal']?.toString() ?? '0') ?? 0.0,
      dataPrevisao: json['dataPrevisao'] != null ? DateTime.parse(json['dataPrevisao']) : null,
      dataEntrega: json['dataEntrega'] != null ? DateTime.parse(json['dataEntrega']) : null,
      itens: (json['itens'] as List<dynamic>?)
              ?.map((item) => OrdemCompraItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'fornecedorId': fornecedorId,
      'obraId': obraId,
      'status': status,
      'valorTotal': valorTotal,
      'dataPrevisao': dataPrevisao?.toIso8601String(),
      'dataEntrega': dataEntrega?.toIso8601String(),
      'itens': itens.map((item) => item.toJson()).toList(),
    };
  }
}
