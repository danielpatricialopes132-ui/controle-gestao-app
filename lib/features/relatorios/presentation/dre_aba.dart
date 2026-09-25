import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/pdf_utils.dart';
import 'package:intl/intl.dart';
import '../providers/relatorios_provider.dart';

class DREAba extends ConsumerWidget {
  const DREAba({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dreAsync = ref.watch(dreProvider);
    final mesAno = ref.watch(relatorioMesAnoProvider);

    return dreAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Calculando DRE do período...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Erro ao carregar DRE: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(dreProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Recarregar'),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        final resumo = data['resumo'] as Map<String, dynamic>? ?? {};
        final receitas = (data['receitas'] as List<dynamic>? ?? []);
        final custosDiretos = (data['custosDiretos'] as List<dynamic>? ?? []);
        final despesasFixas = (data['despesasFixas'] as List<dynamic>? ?? []);

        final formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
        final formatPercent = NumberFormat.decimalPattern('pt_BR');

        final faturamento = (resumo['receitas'] ?? 0).toDouble();
        final custos = (resumo['custosDiretos'] ?? 0).toDouble();
        final lucroBruto = (resumo['lucroBruto'] ?? 0).toDouble();
        final margemBruta = (resumo['margemBrutaPercentual'] ?? 0).toDouble();
        final lucroLiquido = (resumo['lucroLiquido'] ?? 0).toDouble();
        final margemLiquida = (resumo['margemLiquidaPercentual'] ?? 0).toDouble();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              _buildHeaderBanner(data, mesAno),
              const SizedBox(height: 20),

              // KPI Cards Executivos
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Faturamento Bruto',
                      value: formatCurrency.format(faturamento),
                      subtitle: '100% da receita',
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF007A8D),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Margem de Contribuição',
                      value: formatCurrency.format(lucroBruto),
                      subtitle: 'Margem Bruta: ${formatPercent.format(margemBruta)}%',
                      icon: Icons.pie_chart_outline_rounded,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Lucro Líquido Final',
                      value: formatCurrency.format(lucroLiquido),
                      subtitle: 'Margem Líquida: ${formatPercent.format(margemLiquida)}%',
                      icon: lucroLiquido >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: lucroLiquido >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // DRE Demonstrativo em cascata (Waterfall Card)
              _buildModernDreTable(resumo, formatCurrency, formatPercent),
              const SizedBox(height: 24),

              // Detalhamento Aberto por Categorias
              Text(
                'Detalhamento por Categorias Contábeis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
              ),
              const SizedBox(height: 12),
              _buildSection(
                title: '1. Receitas Operacionais Brutas',
                items: receitas,
                format: formatCurrency,
                isReceita: true,
                badgeColor: const Color(0xFF10B981),
                icon: Icons.arrow_upward_rounded,
              ),
              const SizedBox(height: 12),
              _buildSection(
                title: '2. Custos Diretos (Insumos e Produção de Obras)',
                items: custosDiretos,
                format: formatCurrency,
                isReceita: false,
                badgeColor: const Color(0xFFF59E0B),
                icon: Icons.construction_outlined,
              ),
              const SizedBox(height: 12),
              _buildSection(
                title: '3. Despesas Fixas e Administrativas (Escritório)',
                items: despesasFixas,
                format: formatCurrency,
                isReceita: false,
                badgeColor: const Color(0xFFEF4444),
                icon: Icons.corporate_fare_outlined,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderBanner(Map<String, dynamic> data, DateTime mesAno) {
    const meses = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    final formatMes = '${meses[mesAno.month]} / ${mesAno.year}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF007A8D).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics_outlined, color: Colors.tealAccent, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demonstração do Resultado do Exercício ($formatMes)',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Visão gerencial de faturamento, margem de contribuição direta e lucro operacional líquido.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final receitasList = data['receitas'] as List<dynamic>? ?? [];
              final custosDiretosList = data['custosDiretos'] as List<dynamic>? ?? [];
              final despesasFixasList = data['despesasFixas'] as List<dynamic>? ?? [];
              final resumoMap = data['resumo'] as Map<String, dynamic>? ?? {};

              final dataList = <List<String>>[
                ['1. RECEITAS OPERACIONAIS', ''],
                ...receitasList.map((r) => [r['categoria'] ?? 'Sem Categoria', 'R\$ ${(r['valor'] ?? 0).toString()}']),
                ['2. CUSTOS DIRETOS (OBRAS)', ''],
                ...custosDiretosList.map((c) => [c['categoria'] ?? 'Sem Categoria', 'R\$ ${(c['valor'] ?? 0).toString()}']),
                ['3. DESPESAS FIXAS (ADMINISTRATIVO)', ''],
                ...despesasFixasList.map((d) => [d['categoria'] ?? 'Sem Categoria', 'R\$ ${(d['valor'] ?? 0).toString()}']),
                ['RESULTADO LÍQUIDO FINAL', 'R\$ ${(resumoMap['lucroLiquido'] ?? 0).toString()}'],
              ];

              await PdfUtils.exportTablePdf(
                title: 'DRE Gerencial - $formatMes',
                fileName: 'dre_report',
                headers: ['Estrutura DRE', 'Valor (R\$)'],
                data: dataList,
              );
            },
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Exportar PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007A8D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildModernDreTable(Map<String, dynamic> resumo, NumberFormat formatCurrency, NumberFormat formatPercent) {
    final fat = (resumo['receitas'] ?? 0).toDouble();
    final custos = (resumo['custosDiretos'] ?? 0).toDouble();
    final margemContr = (resumo['lucroBruto'] ?? 0).toDouble();
    final fixas = (resumo['despesasFixas'] ?? 0).toDouble();
    final lucroLiq = (resumo['lucroLiquido'] ?? 0).toDouble();
    final mb = (resumo['margemBrutaPercentual'] ?? 0).toDouble();
    final ml = (resumo['margemLiquidaPercentual'] ?? 0).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.view_headline_rounded, color: Color(0xFF007A8D)),
                    SizedBox(width: 8),
                    Text(
                      'Demonstrativo Estruturado',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Text(
                  'Consolidado Operacional',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildCascadeRow(
            label: 'Faturamento Operacional Bruto',
            value: formatCurrency.format(fat),
            percentage: '100%',
            isHighlighted: false,
            color: const Color(0xFF0F172A),
            background: Colors.transparent,
          ),
          _buildCascadeRow(
            label: '(-) Custos Diretos com Obras / Produção',
            value: '- ' + formatCurrency.format(custos),
            percentage: fat > 0 ? '${formatPercent.format((custos / fat) * 100)}%' : '0%',
            isHighlighted: false,
            color: const Color(0xFFEF4444),
            background: Colors.transparent,
          ),
          _buildCascadeRow(
            label: '(=) Margem de Contribuição Bruta',
            value: formatCurrency.format(margemContr),
            percentage: '${formatPercent.format(mb)}%',
            isHighlighted: true,
            color: const Color(0xFF2563EB),
            background: const Color(0xFFEFF6FF),
          ),
          _buildCascadeRow(
            label: '(-) Despesas Fixas & Administrativas',
            value: '- ' + formatCurrency.format(fixas),
            percentage: fat > 0 ? '${formatPercent.format((fixas / fat) * 100)}%' : '0%',
            isHighlighted: false,
            color: const Color(0xFFEF4444),
            background: Colors.transparent,
          ),
          _buildCascadeRow(
            label: '(=) Resultado Operacional Líquido',
            value: formatCurrency.format(lucroLiq),
            percentage: '${formatPercent.format(ml)}%',
            isHighlighted: true,
            color: lucroLiq >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            background: lucroLiq >= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
          ),
        ],
      ),
    );
  }

  Widget _buildCascadeRow({
    required String label,
    required String value,
    required String percentage,
    required bool isHighlighted,
    required Color color,
    required Color background,
  }) {
    return Container(
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                fontSize: isHighlighted ? 15 : 14,
                color: isHighlighted ? color : const Color(0xFF334155),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              percentage,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                fontSize: isHighlighted ? 16 : 14,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List items,
    required NumberFormat format,
    required bool isReceita,
    required Color badgeColor,
    required IconData icon,
  }) {
    double total = items.fold(0, (sum, item) => sum + (item['valor'] ?? 0));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: badgeColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          'Total: ${format.format(total)} (${items.length} itens)',
          style: TextStyle(color: isReceita ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontWeight: FontWeight.bold),
        ),
        children: items.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Nenhum lançamento nesta categoria para o período.', style: TextStyle(color: Colors.grey)),
                )
              ]
            : items.map((item) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  title: Text(item['categoria']?.toString() ?? 'Sem Categoria', style: const TextStyle(fontSize: 13)),
                  trailing: Text(
                    format.format(item['valor'] ?? 0),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                );
              }).toList(),
      ),
    );
  }
}
