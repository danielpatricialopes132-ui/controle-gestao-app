class ChatMensagemModel {
  final String id;
  final String conversaId;
  final String remetenteId;
  final String? remetenteNome;
  final String? remetenteEmail;
  final String? conteudo;
  final String? tipoAnexo;
  final String? urlAnexo;
  final Map<String, dynamic>? dadosContexto;
  final String status;
  final DateTime criadoEm;

  ChatMensagemModel({
    required this.id,
    required this.conversaId,
    required this.remetenteId,
    this.remetenteNome,
    this.remetenteEmail,
    this.conteudo,
    this.tipoAnexo,
    this.urlAnexo,
    this.dadosContexto,
    required this.status,
    required this.criadoEm,
  });

  factory ChatMensagemModel.fromJson(Map<String, dynamic> json) {
    return ChatMensagemModel(
      id: json['id'] ?? '',
      conversaId: json['conversaId'] ?? '',
      remetenteId: json['remetenteId'] ?? '',
      remetenteNome: json['remetente']?['nome'],
      remetenteEmail: json['remetente']?['email'],
      conteudo: json['conteudo'],
      tipoAnexo: json['tipoAnexo'],
      urlAnexo: json['urlAnexo'],
      dadosContexto: json['dadosContexto'] is Map<String, dynamic>
          ? json['dadosContexto']
          : null,
      status: json['status'] ?? 'ENVIADO',
      criadoEm: json['criadoEm'] != null
          ? DateTime.tryParse(json['criadoEm']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ChatConversaModel {
  final String id;
  final String tipo; // DIRETA, GRUPO, OBRA, DEPARTAMENTO
  final String titulo;
  final Map<String, dynamic>? obra;
  final Map<String, dynamic>? outroParticipante;
  final List<dynamic> participantes;
  final ChatMensagemModel? ultimaMensagem;
  final int naoLidas;
  final DateTime atualizadoEm;

  ChatConversaModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.obra,
    this.outroParticipante,
    required this.participantes,
    this.ultimaMensagem,
    required this.naoLidas,
    required this.atualizadoEm,
  });

  factory ChatConversaModel.fromJson(Map<String, dynamic> json) {
    return ChatConversaModel(
      id: json['id'] ?? '',
      tipo: json['tipo'] ?? 'DIRETA',
      titulo: json['titulo'] ?? 'Conversa',
      obra: json['obra'] is Map<String, dynamic> ? json['obra'] : null,
      outroParticipante: json['outroParticipante'] is Map<String, dynamic>
          ? json['outroParticipante']
          : null,
      participantes: json['participantes'] ?? [],
      ultimaMensagem: json['ultimaMensagem'] != null
          ? ChatMensagemModel.fromJson(json['ultimaMensagem'])
          : null,
      naoLidas: json['naoLidas'] ?? 0,
      atualizadoEm: json['atualizadoEm'] != null
          ? DateTime.tryParse(json['atualizadoEm']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
