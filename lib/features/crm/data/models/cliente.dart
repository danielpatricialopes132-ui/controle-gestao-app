class Cliente {
  final String id;
  final String nome;
  final String? cpfCnpj;
  final String? telefone;
  final String? email;

  Cliente({
    required this.id,
    required this.nome,
    this.cpfCnpj,
    this.telefone,
    this.email,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      nome: json['nome'],
      cpfCnpj: json['cpfCnpj'],
      telefone: json['telefone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nome': nome,
      'cpfCnpj': cpfCnpj,
      'telefone': telefone,
      'email': email,
    };
  }
}
