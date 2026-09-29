class AgendaEventoModel {
  final String id;
  final String titulo;
  final String? descricao;
  final String tipo; // PROFISSIONAL, PESSOAL
  final DateTime dataInicio;
  final DateTime dataFim;
  final bool diaInteiro;
  final String? local;
  final String status;
  final String? obraId;
  final String? obraNome;
  final String? clienteNome;
  final String criadorId;
  final String? criadorNome;
  final List<AgendaParticipanteModel> participantes;
  final List<dynamic> lembretes;

  AgendaEventoModel({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.tipo,
    required this.dataInicio,
    required this.dataFim,
    required this.diaInteiro,
    this.local,
    required this.status,
    this.obraId,
    this.obraNome,
    this.clienteNome,
    required this.criadorId,
    this.criadorNome,
    required this.participantes,
    required this.lembretes,
  });

  factory AgendaEventoModel.fromJson(Map<String, dynamic> json) {
    return AgendaEventoModel(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'],
      tipo: json['tipo'] ?? 'PROFISSIONAL',
      dataInicio: json['dataInicio'] != null
          ? DateTime.tryParse(json['dataInicio']) ?? DateTime.now()
          : DateTime.now(),
      dataFim: json['dataFim'] != null
          ? DateTime.tryParse(json['dataFim']) ?? DateTime.now()
          : DateTime.now(),
      diaInteiro: json['diaInteiro'] ?? false,
      local: json['local'],
      status: json['status'] ?? 'CONFIRMADO',
      obraId: json['obraId'],
      obraNome: json['obra']?['nome'],
      clienteNome: json['cliente']?['nome'],
      criadorId: json['criadorId'] ?? '',
      criadorNome: json['criador']?['nome'],
      participantes: (json['participantes'] as List<dynamic>?)
              ?.map((p) => AgendaParticipanteModel.fromJson(p))
              .toList() ??
          [],
      lembretes: json['lembretes'] ?? [],
    );
  }
}

class AgendaParticipanteModel {
  final String id;
  final String? usuarioId;
  final String? nome;
  final String? email;
  final String statusConvite; // PENDENTE, ACEITO, RECUSADO, TALVEZ
  final String? motivoRecusa;

  AgendaParticipanteModel({
    required this.id,
    this.usuarioId,
    this.nome,
    this.email,
    required this.statusConvite,
    this.motivoRecusa,
  });

  factory AgendaParticipanteModel.fromJson(Map<String, dynamic> json) {
    return AgendaParticipanteModel(
      id: json['id'] ?? '',
      usuarioId: json['usuarioId'],
      nome: json['usuario']?['nome'] ?? json['nomeExterno'],
      email: json['usuario']?['email'] ?? json['emailExterno'],
      statusConvite: json['statusConvite'] ?? 'PENDENTE',
      motivoRecusa: json['motivoRecusa'],
    );
  }
}
