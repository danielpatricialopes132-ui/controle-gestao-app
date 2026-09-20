import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TerceirosEstagiosView extends StatelessWidget {
  final List<dynamic> terceiros;
  final List<String> estagiosCiclo;
  final Function(String terceiroId, String novoStatus) onUpdateStatus;
  final Function(String terceiroId) onDeleteTerceiro;
  final VoidCallback onNovoTerceiro;

  const TerceirosEstagiosView({
    super.key,
    required this.terceiros,
    required this.estagiosCiclo,
    required this.onUpdateStatus,
    required this.onDeleteTerceiro,
    required this.onNovoTerceiro,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    if (terceiros.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.handshake_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Nenhum parceiro de interiores ou decoração cadastrado.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),
              const Text('Acompanhe marcenarias, marmorarias, automação e coordene os prazos de entrega do cliente.',
                  style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onNovoTerceiro,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar Primeiro Parceiro'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white),
              )
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12, top: 4),
          child: Text('Empresas Parceiras & Ciclo de Fabricação / Instalação',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ...terceiros.map((t) {
          final punchList = (t['punchList'] as List<dynamic>?) ?? [];
          final pendenciasAbertas = punchList.where((p) => p['status'] != 'RESOLVIDO').length;
          final statusAtual = t['status'] ?? 'CONTRATADO';
          final idxEstagio = estagiosCiclo.indexOf(statusAtual);
          final esp = t['especialidade'];

          return Card(
            elevation: 2.5,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getEspecialidadeColor(esp).withOpacity(0.15),
                        child: Icon(_getEspecialidadeIcon(esp), color: _getEspecialidadeColor(esp)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['nomeEmpresa'] ?? 'Empresa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Especialidade: $esp', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                          ],
                        ),
                      ),
                      _buildStatusEstagioChip(statusAtual),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => onDeleteTerceiro(t['id']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (t['responsavel'] != null && t['responsavel'].toString().isNotEmpty)
                        Expanded(
                          child: Text('Responsável: ${t['responsavel']}', style: const TextStyle(fontSize: 12)),
                        ),
                      if (t['telefone'] != null && t['telefone'].toString().isNotEmpty)
                        Expanded(
                          child: Text('Contato: ${t['telefone']}', style: const TextStyle(fontSize: 12)),
                        ),
                      if (t['valorContrato'] != null && (t['valorContrato'] as num) > 0)
                        Text('Contrato: ${currencyFormat.format(t['valorContrato'])}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Linha de Progresso do Ciclo de Vida
                  Row(
                    children: [
                      Text('Estágio: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (idxEstagio + 1) / estagiosCiclo.length,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              idxEstagio == estagiosCiclo.length - 1 ? Colors.green : Colors.teal,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${idxEstagio + 1}/${estagiosCiclo.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (pendenciasAbertas > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.shade200)),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Text('$pendenciasAbertas pendência(s) no Punch List', style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else
                        Text('Sem pendências no checklist', style: TextStyle(color: Colors.green.shade700, fontSize: 11)),
                      const Spacer(),
                      if (idxEstagio > 0)
                        OutlinedButton(
                          onPressed: () {
                            final ant = estagiosCiclo[idxEstagio - 1];
                            onUpdateStatus(t['id'], ant);
                          },
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                          child: const Text('Voltar Etapa', style: TextStyle(fontSize: 11)),
                        ),
                      const SizedBox(width: 8),
                      if (idxEstagio < estagiosCiclo.length - 1)
                        ElevatedButton(
                          onPressed: () {
                            final prox = estagiosCiclo[idxEstagio + 1];
                            onUpdateStatus(t['id'], prox);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          child: Text('Avançar p/ ${_formatEstagioNome(estagiosCiclo[idxEstagio + 1])}', style: const TextStyle(fontSize: 11)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatusEstagioChip(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;

    switch (status) {
      case 'CONTRATADO': bg = Colors.blue.shade100; fg = Colors.blue.shade900; break;
      case 'MEDICAO_IN_LOCO': bg = Colors.purple.shade100; fg = Colors.purple.shade900; break;
      case 'FABRICACAO': bg = Colors.amber.shade100; fg = Colors.amber.shade900; break;
      case 'PRONTO_ENTREGA': bg = Colors.orange.shade100; fg = Colors.orange.shade900; break;
      case 'MONTAGEM': bg = Colors.teal.shade100; fg = Colors.teal.shade900; break;
      case 'ENTREGUE_APROVADO': bg = Colors.green.shade100; fg = Colors.green.shade900; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(_formatEstagioNome(status), style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  String _formatEstagioNome(String status) {
    switch (status) {
      case 'CONTRATADO': return 'Contratado';
      case 'MEDICAO_IN_LOCO': return 'Medição in loco';
      case 'FABRICACAO': return 'Em Fabricação';
      case 'PRONTO_ENTREGA': return 'Pronto p/ Entrega';
      case 'MONTAGEM': return 'Em Montagem';
      case 'ENTREGUE_APROVADO': return 'Entregue & Aprovado';
      default: return status;
    }
  }

  Color _getEspecialidadeColor(String? esp) {
    switch (esp) {
      case 'MARCENARIA': return Colors.brown;
      case 'MARMORARIA': return Colors.blueGrey;
      case 'AUTOMACAO': return Colors.indigo;
      case 'CLIMATIZACAO': return Colors.cyan;
      case 'ESQUADRIAS': return Colors.deepPurple;
      case 'DECORACAO': return Colors.pink;
      default: return Colors.teal;
    }
  }

  IconData _getEspecialidadeIcon(String? esp) {
    switch (esp) {
      case 'MARCENARIA': return Icons.table_restaurant;
      case 'MARMORARIA': return Icons.square_foot;
      case 'AUTOMACAO': return Icons.settings_remote;
      case 'CLIMATIZACAO': return Icons.ac_unit;
      case 'ESQUADRIAS': return Icons.window;
      case 'DECORACAO': return Icons.chair;
      default: return Icons.handshake;
    }
  }
}
