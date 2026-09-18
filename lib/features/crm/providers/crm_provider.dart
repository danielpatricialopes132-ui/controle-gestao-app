import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../auth/providers/tenant_provider.dart';
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

class CrmNotifier extends StateNotifier<CrmState> {
  final Ref ref;

  CrmNotifier(this.ref) : super(CrmState());

  Future<void> fetchClientes() async {
    final tenantId = ref.read(tenantProvider);
    if (tenantId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/crm/clientes'),
        headers: {'x-tenant-id': tenantId},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        state = state.copyWith(
          clientes: data.map((e) => Cliente.fromJson(e)).toList(),
          isLoading: false,
        );
      } else {
        throw Exception('Failed to load clientes');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createCliente(Cliente cliente) async {
    final tenantId = ref.read(tenantProvider);
    if (tenantId == null) return;

    final response = await http.post(
      Uri.parse('$baseUrl/crm/clientes'),
      headers: {
        'x-tenant-id': tenantId,
        'Content-Type': 'application/json',
      },
      body: json.encode(cliente.toJson()),
    );

    if (response.statusCode == 201) {
      await fetchClientes();
    } else {
      throw Exception('Failed to create cliente');
    }
  }

  Future<void> fetchPropostas() async {
    final tenantId = ref.read(tenantProvider);
    if (tenantId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/crm/propostas'),
        headers: {'x-tenant-id': tenantId},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        state = state.copyWith(
          propostas: data.map((e) => Proposta.fromJson(e)).toList(),
          isLoading: false,
        );
      } else {
        throw Exception('Failed to load propostas');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createProposta(Proposta proposta) async {
    final tenantId = ref.read(tenantProvider);
    if (tenantId == null) return;

    final response = await http.post(
      Uri.parse('$baseUrl/crm/propostas'),
      headers: {
        'x-tenant-id': tenantId,
        'Content-Type': 'application/json',
      },
      body: json.encode(proposta.toJson()),
    );

    if (response.statusCode == 201) {
      await fetchPropostas();
    } else {
      throw Exception('Failed to create proposta');
    }
  }

  Future<void> updatePropostaStatus(String id, String novoStatus) async {
    final tenantId = ref.read(tenantProvider);
    if (tenantId == null) return;

    final response = await http.put(
      Uri.parse('$baseUrl/crm/propostas/$id'),
      headers: {
        'x-tenant-id': tenantId,
        'Content-Type': 'application/json',
      },
      body: json.encode({'status': novoStatus}),
    );

    if (response.statusCode == 200) {
      await fetchPropostas();
    } else {
      throw Exception('Failed to update proposta');
    }
  }

  Future<void> updatePropostaNfUrl(String id, String nfUrl) async {
    final tenantId = ref.read(tenantProvider);
    if (tenantId == null) return;

    final response = await http.put(
      Uri.parse('$baseUrl/crm/propostas/$id'),
      headers: {
        'x-tenant-id': tenantId,
        'Content-Type': 'application/json',
      },
      body: json.encode({'nfUrl': nfUrl}),
    );

    if (response.statusCode == 200) {
      await fetchPropostas();
    } else {
      throw Exception('Failed to update proposta nfUrl');
    }
  }
}

final crmProvider = StateNotifierProvider<CrmNotifier, CrmState>((ref) {
  return CrmNotifier(ref);
});
