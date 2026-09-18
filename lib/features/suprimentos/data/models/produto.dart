class Produto {
  final String id;
  final String nome;
  final String unidadeMedida;
  final double precoBase;

  Produto({
    required this.id,
    required this.nome,
    required this.unidadeMedida,
    this.precoBase = 0.0,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'],
      nome: json['nome'],
      unidadeMedida: json['unidadeMedida'],
      precoBase: double.tryParse(json['precoBase']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nome': nome,
      'unidadeMedida': unidadeMedida,
      'precoBase': precoBase,
    };
  }
}
