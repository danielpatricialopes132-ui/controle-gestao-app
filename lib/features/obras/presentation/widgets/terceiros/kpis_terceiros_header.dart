import 'package:flutter/material.dart';

class KpisTerceirosHeader extends StatelessWidget {
  final int totalTerceiros;
  final int totalVisitasSemana;
  final int totalRetiradasPendentes;
  final int punchListResolvidos;
  final int punchListTotal;

  const KpisTerceirosHeader({
    super.key,
    required this.totalTerceiros,
    required this.totalVisitasSemana,
    required this.totalRetiradasPendentes,
    required this.punchListResolvidos,
    required this.punchListTotal,
  });

  @override
  Widget build(BuildContext context) {
    final taxaResolucao = punchListTotal > 0
        ? ((punchListResolvidos / punchListTotal) * 100).toInt()
        : 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildKpiCard(
                title: 'Parceiros Contratados',
                value: '$totalTerceiros',
                subtitle: 'Marcenaria, Mármore, etc.',
                icon: Icons.handshake,
                color: Colors.teal,
                width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 36) / 4,
              ),
              _buildKpiCard(
                title: 'Visitas na Semana',
                value: '$totalVisitasSemana',
                subtitle: 'Acessos S-T-Q-Q-S-S-D',
                icon: Icons.event_available,
                color: Colors.indigo,
                width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 36) / 4,
              ),
              _buildKpiCard(
                title: 'Itens Sob Cautela',
                value: '$totalRetiradasPendentes',
                subtitle: totalRetiradasPendentes > 0 ? 'Em usinagem externa' : 'Nenhuma pendência',
                icon: Icons.outbox,
                color: totalRetiradasPendentes > 0 ? Colors.orange.shade800 : Colors.teal.shade700,
                width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 36) / 4,
              ),
              _buildKpiCard(
                title: 'Qualidade / Vistorias',
                value: '$taxaResolucao%',
                subtitle: '$punchListResolvidos de $punchListTotal itens sanados',
                icon: Icons.verified,
                color: taxaResolucao == 100 ? Colors.green.shade700 : const Color(0xFF4338CA),
                width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 36) / 4,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
