import 'package:flutter/material.dart';

class MapaVisitasSemanalCard extends StatelessWidget {
  final List<dynamic> mapaSemanal;
  final List<dynamic> terceiros;
  final VoidCallback onApontarEntrada;

  const MapaVisitasSemanalCard({
    super.key,
    required this.mapaSemanal,
    required this.terceiros,
    required this.onApontarEntrada,
  });

  @override
  Widget build(BuildContext context) {
    if (mapaSemanal.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2.5,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.date_range, color: Colors.indigo, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MAPA SEMANAL DE VISITAS A OBRA (S, T, Q, Q, S, S, D)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                      Text('Acessos das empresas contratadas pelo cliente ao longo da semana',
                          style: TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onApontarEntrada,
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Apontar Entrada'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
                columnSpacing: 14,
                columns: const [
                  DataColumn(label: Text('Empresa / Especialidade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('S', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('T', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Q', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Q', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('S', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('S', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('D', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: mapaSemanal.map((item) {
                  final dias = item['dias'] as Map<String, dynamic>? ?? {};
                  final esp = item['especialidade'];
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getEspecialidadeIcon(esp), size: 16, color: _getEspecialidadeColor(esp)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item['nomeEmpresa'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text(esp ?? '', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(_buildDiaVisitaBadge(dias['seg'] as List<dynamic>?)),
                      DataCell(_buildDiaVisitaBadge(dias['ter'] as List<dynamic>?)),
                      DataCell(_buildDiaVisitaBadge(dias['qua'] as List<dynamic>?)),
                      DataCell(_buildDiaVisitaBadge(dias['qui'] as List<dynamic>?)),
                      DataCell(_buildDiaVisitaBadge(dias['sex'] as List<dynamic>?)),
                      DataCell(_buildDiaVisitaBadge(dias['sab'] as List<dynamic>?)),
                      DataCell(_buildDiaVisitaBadge(dias['dom'] as List<dynamic>?)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.indigo.shade100, borderRadius: BorderRadius.circular(10)),
                          child: Text('${item['totalVisitasNaSemana'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.indigo)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaVisitaBadge(List<dynamic>? visitas) {
    if (visitas == null || visitas.isEmpty) {
      return Text('-', style: TextStyle(color: Colors.grey.shade400));
    }
    final total = visitas.length;
    final primeira = visitas.first;
    final motivo = primeira['motivo'] ?? 'Visita';

    return Tooltip(
      message: '$total visita(s): $motivo',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(6)),
        child: Text(
          total > 1 ? '$total x' : 'SIM',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
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
