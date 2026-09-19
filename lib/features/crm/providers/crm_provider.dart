import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';
import '../data/models/cliente.dart';
import '../data/models/proposta.dart';

const String baseUrl = 'http://localhost:3000/api';

class CrmState {
  final bool isLoading;
  final List<Cliente> clientes;
  final List<Proposta> propostas;

  CrmState({
    this.isLoading = false,
    this.clientes = const [],
    this.propostas = const [],
  });

  CrmState copyWith({
    bool? isLoading,
    List<Cliente>? clientes,
    List<Proposta>? propostas,
  }) {
    return CrmState(
      isLoading: isLoading ?? this.isLoading,
      clientes: clientes ?? this.clientes,
      propostas: propostas ?? this.propostas,
    );
  }
}

class CrmNotifier extends Notifier<CrmState> {
  @override
  CrmState build() {
    return CrmState();
  }

  Future<void> fetchClientes() async {
    state = state.copyWith(isLoading: true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/crm/clientes');

      final List data = response;
      state = state.copyWith(
        clientes: data.map((e) => Cliente.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createCliente(Cliente cliente) async {
    final api = ref.read(apiClientProvider);
    await api.post('/crm/clientes', cliente.toJson());
    await fetchClientes();
  }

  Future<void> fetchPropostas() async {
    state = state.copyWith(isLoading: true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/crm/propostas');

      final List data = response;
      state = state.copyWith(
        propostas: data.map((e) => Proposta.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createProposta(Proposta proposta) async {
    final api = ref.read(apiClientProvider);
    await api.post('/crm/propostas', proposta.toJson());
    await fetchPropostas();
  }

  Future<void> updatePropostaStatus(String id, String novoStatus) async {
    final api = ref.read(apiClientProvider);
    await api.put('/crm/propostas/$id', {'status': novoStatus});
    await fetchPropostas();
  }

  Future<void> updatePropostaNfUrl(String id, String nfUrl) async {
    final api = ref.read(apiClientProvider);
    await api.put('/crm/propostas/$id', {'nfUrl': nfUrl});
    await fetchPropostas();
  }
}

final crmProvider = NotifierProvider<CrmNotifier, CrmState>(() {
  return CrmNotifier();
});
