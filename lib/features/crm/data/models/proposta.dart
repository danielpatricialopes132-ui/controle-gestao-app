import 'cliente.dart';

class PropostaItem {
  final String id;
  final String descricao;
  final double quantidade;
  final double valorUnitario;
  final double valorTotal;

  PropostaItem({
    required this.id,
    required this.descricao,
    required this.quantidade,
    required this.valorUnitario,
    required this.valorTotal,
  });

  factory PropostaItem.fromJson(Map<String, dynamic> json) {
    return PropostaItem(
      id: json['id'] ?? '',
      descricao: json['descricao'],
      quantidade: double.tryParse(json['quantidade'].toString()) ?? 1,
      valorUnitario: double.tryParse(json['valorUnitario'].toString()) ?? 0,
      valorTotal: double.tryParse(json['valorTotal'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'descricao': descricao,
      'quantidade': quantidade,
      'valorUnitario': valorUnitario,
      'valorTotal': valorTotal,
    };
  }
}

class Proposta {
  final String id;
  final String titulo;
  final String clienteId;
  final double valorTotal;
  final int validadeDias;
  final String status;
  final String? termos;
  final String? nfUrl;
  final Cliente? cliente;
  final List<PropostaItem> itens;

  Proposta({
    required this.id,
    required this.titulo,
    required this.clienteId,
    required this.valorTotal,
    required this.validadeDias,
    required this.status,
    this.termos,
    this.nfUrl,
    this.cliente,
    this.itens = const [],
  });

  factory Proposta.fromJson(Map<String, dynamic> json) {
    return Proposta(
      id: json['id'],
      titulo: json['titulo'],
      clienteId: json['clienteId'],
      valorTotal: double.tryParse(json['valorTotal'].toString()) ?? 0,
      validadeDias: json['validadeDias'] ?? 15,
      status: json['status'] ?? 'RASCUNHO',
      termos: json['termos'],
      nfUrl: json['nfUrl'],
      cliente: json['cliente'] != null ? Cliente.fromJson(json['cliente']) : null,
      itens: json['itens'] != null 
          ? (json['itens'] as List).map((i) => PropostaItem.fromJson(i)).toList() 
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'titulo': titulo,
      'clienteId': clienteId,
      'valorTotal': valorTotal,
      'validadeDias': validadeDias,
      'status': status,
      'termos': termos,
      'nfUrl': nfUrl,
      'itens': itens.map((i) => i.toJson()).toList(),
    };
  }
}
