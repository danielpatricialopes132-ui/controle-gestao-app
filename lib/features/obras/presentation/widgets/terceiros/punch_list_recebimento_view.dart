import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/termo_recebimento_pdf_service.dart';

class PunchListRecebimentoView extends StatelessWidget {
  final String obraNome;
  final List<dynamic> punchList;
  final List<dynamic> termosRecebimento;
  final Function(String itemId) onBaixarPunchItem;
  final Function(String itemId) onDeletePunchItem;
  final VoidCallback onNovoTermoRecebimento;
  final VoidCallback onNovoPunchItem;

  const PunchListRecebimentoView({
    super.key,
    required this.obraNome,
    required this.punchList,
    required this.termosRecebimento,
    required this.onBaixarPunchItem,
    required this.onDeletePunchItem,
    required this.onNovoTermoRecebimento,
    required this.onNovoPunchItem,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totalVistoriados = punchList.length;
    final totalResolvidos = punchList.where((p) => p['status'] == 'RESOLVIDO').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card de Auditoria e Termos de Recebimento Emitidos
        Card(
          elevation: 2.5,
          margin: const EdgeInsets.only(bottom: 20),
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
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.verified, color: Color(0xFF4338CA), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AUDITORIA DE ENTREGA & RECEBIMENTO DE INTERIORES',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                          Text('Saneamento do checklist de qualidade: $totalResolvidos de $totalVistoriados itens resolvidos',
                              style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onNovoTermoRecebimento,
                      icon: const Icon(Icons.draw, size: 16),
                      label: const Text('Emitir Termo com Assinatura'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4338CA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                if (termosRecebimento.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Termos de Recebimento Assinados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  ...termosRecebimento.map((rec) {
                    final dataEmissao = rec['dataEmissao'] != null ? dateFormat.format(DateTime.parse(rec['dataEmissao'])) : '-';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text('${rec['numeroTermo']} - ${rec['nomeCliente']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 8),
                          Text('($dataEmissao)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => TermoRecebimentoPdfService.exportarTermo(
                              nomeObra: obraNome,
                              enderecoObra: null,
                              termo: rec,
                            ),
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: const Text('Exportar Certidão PDF'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF4338CA)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Itens do Checklist de Vistoria / Punch List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: onNovoPunchItem,
              icon: const Icon(Icons.add_task, size: 16),
              label: const Text('Nova Pendência'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (punchList.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.task_alt, size: 48, color: Colors.green.shade400),
                  const SizedBox(height: 12),
                  const Text('Nenhuma pendência ou não-conformidade registrada.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
            ),
          )
        else
          ...punchList.map((p) {
            final isResolvido = p['status'] == 'RESOLVIDO';
            final terceiro = p['terceiro'];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isResolvido ? Colors.green.shade100 : Colors.red.shade100,
                  child: Icon(
                    isResolvido ? Icons.check : Icons.warning_amber_rounded,
                    color: isResolvido ? Colors.green.shade800 : Colors.red.shade900,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${p['ambiente'] ?? 'Ambiente'} - ${p['descricao']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: isResolvido ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    _buildPunchStatusChip(p['status']),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    if (terceiro != null)
                      Text('Empresa Responsável: ${terceiro['nomeEmpresa']} (${terceiro['especialidade']})',
                          style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                    if (p['prazoCorrecao'] != null)
                      Text('Prazo p/ Correção: ${dateFormat.format(DateTime.parse(p['prazoCorrecao']))}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    if (isResolvido && p['dataResolucao'] != null)
                      Text('Resolvido em: ${dateFormat.format(DateTime.parse(p['dataResolucao']))}',
                          style: const TextStyle(fontSize: 11, color: Colors.green)),
                  ],
                ),
                trailing: isResolvido
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                        onPressed: () => onDeletePunchItem(p['id']),
                      )
                    : ElevatedButton(
                        onPressed: () => onBaixarPunchItem(p['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: const Text('Baixar'),
                      ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPunchStatusChip(String status) {
    Color bg = Colors.red.shade100;
    Color fg = Colors.red.shade900;
    String label = 'Pendente';

    if (status == 'EM_CORRECAO') {
      bg = Colors.amber.shade100;
      fg = Colors.amber.shade900;
      label = 'Em Correção';
    } else if (status == 'RESOLVIDO') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
      label = 'Resolvido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
