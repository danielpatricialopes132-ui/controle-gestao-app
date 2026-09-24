import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'nova_proposta_modal.dart';
import '../../providers/crm_provider.dart';
import '../../../../features/auth/providers/tenant_provider.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../../services/pdf_generator_service.dart';

class PropostasScreen extends ConsumerStatefulWidget {
  const PropostasScreen({super.key});

  @override
  ConsumerState<PropostasScreen> createState() => _PropostasScreenState();
}

class _PropostasScreenState extends ConsumerState<PropostasScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(crmProvider.notifier).fetchPropostas();
      ref.read(crmProvider.notifier).fetchClientes();
    });
  }

  void _atualizarStatus(String id, String novoStatus) async {
    try {
      await ref.read(crmProvider.notifier).updatePropostaStatus(id, novoStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status atualizado para $novoStatus! Obra criada automaticamente se aprovada.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(crmProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orçamentos & Propostas')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.propostas.length,
              itemBuilder: (context, index) {
                final proposta = provider.propostas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(proposta.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            Chip(
                              label: Text(proposta.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              backgroundColor: proposta.status == 'APROVADA' ? Colors.green : (proposta.status == 'REJEITADA' ? Colors.red : Colors.orange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Cliente: ${proposta.cliente?.nome ?? 'Desconhecido'}'),
                        Text('Valor Total: R\$ ${proposta.valorTotal.toStringAsFixed(2)}'),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () async {
                                final tenantId = ref.read(tenantOverrideProvider);
                                if (tenantId != null) {
                                  // Pegar nome da empresa real do tenant atual se possível, ou padrao
                                  await PdfGeneratorService.imprimirOuCompartilhar(proposta, 'DPG Construtoras & Obras');
                                }
                              },
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                              tooltip: 'Gerar PDF do Orçamento',
                            ),
                            if (proposta.status == 'RASCUNHO') ...[
                              TextButton.icon(
                                onPressed: () => _atualizarStatus(proposta.id, 'ENVIADA'),
                                icon: const Icon(Icons.send),
                                label: const Text('Marcar Enviada'),
                              ),
                            ],
                            if (proposta.status == 'ENVIADA') ...[
                              TextButton.icon(
                                onPressed: () => _atualizarStatus(proposta.id, 'REJEITADA'),
                                icon: const Icon(Icons.close, color: Colors.red),
                                label: const Text('Rejeitar', style: TextStyle(color: Colors.red)),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _atualizarStatus(proposta.id, 'APROVADA'),
                                icon: const Icon(Icons.check),
                                label: const Text('Aprovar (Gera Obra)'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              ),
                            ],
                            if (proposta.status == 'APROVADA') ...[
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final tenantId = ref.read(tenantOverrideProvider);
                                  if (tenantId != null) {
                                    await PdfGeneratorService.gerarECompartilharFatura(proposta, 'DPG Construtoras & Obras');
                                  }
                                },
                                icon: const Icon(Icons.receipt_long),
                                label: const Text('Gerar Fatura (PDF)'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final api = ref.read(apiClientProvider);
                                    // Assumindo que a API aceita clienteId e valor. A obra seria vinculada depois, mas passamos null provisorio ou tentamos obter
                                    final response = await api.post('/nfe/emitir', {
                                      'clienteId': proposta.clienteId,
                                      'obraId': '00000000-0000-0000-0000-000000000000', // Mock id para fins de simulacao
                                      'valor': proposta.valorTotal,
                                    });
                                    if (response['success'] == true) {
                                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'NFS-e enviada para processamento!')));
                                    } else {
                                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${response['error']}')));
                                    }
                                  } catch (e) {
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao emitir nota: $e')));
                                  }
                                },
                                icon: const Icon(Icons.account_balance),
                                label: const Text('Emitir NFS-e (Fiscal)'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                              ),
                            ],
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(heroTag: null, 
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NovaPropostaModal()),
          );
        },
        tooltip: 'Novo Orçamento',
        child: const Icon(Icons.add),
      ),
    );
  }
}
