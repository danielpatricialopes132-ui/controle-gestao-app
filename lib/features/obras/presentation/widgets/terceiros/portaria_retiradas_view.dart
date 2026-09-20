import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/termo_portaria_pdf_service.dart';
import '../../../services/termo_retirada_pdf_service.dart';

class PortariaRetiradasView extends StatelessWidget {
  final String obraNome;
  final List<dynamic> portariaLiberacoes;
  final List<dynamic> termosRetirada;
  final Function(String liberacaoId) onDeleteLiberacao;
  final Function(String termoId) onBaixarDevolucao;
  final VoidCallback onNovaPortaria;
  final VoidCallback onNovaRetirada;

  const PortariaRetiradasView({
    super.key,
    required this.obraNome,
    required this.portariaLiberacoes,
    required this.termosRetirada,
    required this.onDeleteLiberacao,
    required this.onBaixarDevolucao,
    required this.onNovaPortaria,
    required this.onNovaRetirada,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Card 1: Portaria Condominial ---
        Card(
          elevation: 2.5,
          margin: const EdgeInsets.only(bottom: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.badge, color: Color(0xFF1E3A8A), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CONTROLE DE PORTARIA & ACESSO DE CONDOMÍNIO',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                          Text('Emissão de termos de liberação formal para montadores e equipes de interiores',
                              style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onNovaPortaria,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nova Liberação'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (portariaLiberacoes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blueGrey, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Nenhuma autorização de portaria emitida. Clique no botão acima para liberar a entrada de montadores no condomínio.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...portariaLiberacoes.map((lib) {
                    final dataInicio = lib['dataInicio'] != null ? dateFormat.format(DateTime.parse(lib['dataInicio'])) : '-';
                    final dataFim = lib['dataFim'] != null ? dateFormat.format(DateTime.parse(lib['dataFim'])) : '-';
                    final colaboradores = (lib['colaboradores'] as List<dynamic>?) ?? [];

                    return Card(
                      color: Colors.blue.shade50.withOpacity(0.4),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.blue.shade100)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.security, color: Color(0xFF1E3A8A), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(lib['empresaNome'] ?? 'Empresa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                                        child: Text(lib['tipoAcesso'] ?? 'TERCEIRO_CLIENTE', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Período: $dataInicio até $dataFim | Horário: ${lib['horarioPermitido'] ?? '08:00 às 17:00'}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                                  if (lib['veiculoPlaca'] != null)
                                    Text('Veículo: ${lib['veiculoModelo'] ?? ''} (Placa: ${lib['veiculoPlaca']})',
                                        style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: colaboradores.map((c) {
                                      return Chip(
                                        avatar: const Icon(Icons.person, size: 12),
                                        label: Text('${c['nome']} (RG: ${c['rg']})', style: const TextStyle(fontSize: 10)),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => TermoPortariaPdfService.exportarTermo(
                                    nomeObra: obraNome,
                                    enderecoObra: null,
                                    autorizacao: lib,
                                  ),
                                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                                  label: const Text('PDF Portaria'),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () => onDeleteLiberacao(lib['id']),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),

        // --- Card 2: Termos de Retirada & Cautela de Itens ---
        Card(
          elevation: 2.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.outbox, color: Color(0xFF0F766E), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TERMO DE CAUTELA & RETIRADA DE ITENS DA OBRA',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                          Text('Controle e rastreio de cubas, portas ou metais retirados por marmorarias e marcenarias com assinatura digital',
                              style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onNovaRetirada,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nova Cautela'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (termosRetirada.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: Colors.teal, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Nenhum item em posse de terceiros fora da obra. Para liberar cubas para marmoraria ou peças para ajuste, clique no botão acima.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...termosRetirada.map((termo) {
                    final dataRetirada = termo['dataRetirada'] != null ? dateFormat.format(DateTime.parse(termo['dataRetirada'])) : '-';
                    final previsao = termo['previsaoDevolucao'] != null ? dateFormat.format(DateTime.parse(termo['previsaoDevolucao'])) : 'Sem data';
                    final isRetirado = termo['status'] == 'RETIRADO';
                    final itens = (termo['itensRetirados'] as List<dynamic>?) ?? [];

                    return Card(
                      color: isRetirado ? Colors.amber.shade50.withOpacity(0.5) : Colors.green.shade50.withOpacity(0.5),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isRetirado ? Colors.amber.shade200 : Colors.green.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(isRetirado ? Icons.timelapse : Icons.check_circle, color: isRetirado ? Colors.orange.shade800 : Colors.green.shade700, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(termo['numeroTermo'] ?? 'RET-000', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(width: 8),
                                      Text('Empresa: ${termo['empresaRetirante']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: isRetirado ? Colors.orange.shade100 : Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                        child: Text(termo['status'] ?? 'RETIRADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isRetirado ? Colors.orange.shade900 : Colors.green.shade900)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Retirado em: $dataRetirada | Previsão de Retorno: $previsao', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                                  Text('Responsável: ${termo['nomeResponsavelRetirada']} (Doc: ${termo['documentoResponsavel'] ?? 'N/I'})', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: itens.map((it) {
                                      return Chip(
                                        backgroundColor: Colors.white,
                                        label: Text('${it['quantidade']}x ${it['item']} (${it['estadoConservacao'] ?? 'OK'})', style: const TextStyle(fontSize: 10)),
                                        visualDensity: VisualDensity.compact,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => TermoRetiradaPdfService.exportarTermo(
                                    nomeObra: obraNome,
                                    enderecoObra: null,
                                    termo: termo,
                                  ),
                                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                                  label: const Text('PDF Cautela'),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                ),
                                const SizedBox(height: 6),
                                if (isRetirado)
                                  OutlinedButton(
                                    onPressed: () => onBaixarDevolucao(termo['id']),
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                    child: const Text('Baixar Devolução', style: TextStyle(fontSize: 11, color: Colors.green)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
