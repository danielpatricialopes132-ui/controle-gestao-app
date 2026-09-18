class Fornecedor {
  final String id;
  final String nome;
  final String? cnpj;
  final String? telefone;
  final String? email;

  Fornecedor({
    required this.id,
    required this.nome,
    this.cnpj,
    this.telefone,
    this.email,
  });

  factory Fornecedor.fromJson(Map<String, dynamic> json) {
    return Fornecedor(
      id: json['id'],
      nome: json['nome'],
      cnpj: json['cnpj'],
      telefone: json['telefone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nome': nome,
      'cnpj': cnpj,
      'telefone': telefone,
      'email': email,
    };
  }
}
