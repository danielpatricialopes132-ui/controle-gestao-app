import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/relatorios_provider.dart';
import '../services/relatorios_pdf_service.dart';

class DREAba extends ConsumerWidget {
  const DREAba({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dreAsync = ref.watch(dreProvider);

    return dreAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erro: $e')),
      data: (data) {
        final resumo = data['resumo'];
        final receitas = data['receitas'] as List;
        final custosDiretos = data['custosDiretos'] as List;
        final despesasFixas = data['despesasFixas'] as List;

        final formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
        final formatPercent = NumberFormat.decimalPattern('pt_BR');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final mesAno = ref.read(relatorioMesAnoProvider);
                    RelatoriosPdfService.imprimirDRE(data, mesAno);
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Exportar PDF'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                ),
              ),
              const SizedBox(height: 16),
              _buildResumoCard(resumo, formatCurrency, formatPercent),
              const SizedBox(height: 24),
              _buildSection('1. Receitas Operacionais Brutas', receitas, formatCurrency, isReceita: true),
              const SizedBox(height: 16),
              _buildSection('2. Custos Diretos (Obras)', custosDiretos, formatCurrency, isReceita: false),
              const SizedBox(height: 16),
              _buildSection('3. Despesas Fixas (Escritório / Administrativo)', despesasFixas, formatCurrency, isReceita: false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResumoCard(Map<String, dynamic> resumo, NumberFormat formatCurrency, NumberFormat formatPercent) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Demonstração do Resultado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildRow('Faturamento Bruto', resumo['receitas'], formatCurrency, isBold: true),
            _buildRow('(-) Custos Diretos', resumo['custosDiretos'], formatCurrency),
            _buildRow('(=) Margem de Contribuição', resumo['lucroBruto'], formatCurrency, isBold: true, color: Colors.blue[800]),
            Text('Margem Bruta: ${formatPercent.format(resumo['margemBrutaPercentual'])}%', style: const TextStyle(color: Colors.grey)),
            const Divider(),
            _buildRow('(-) Despesas Fixas', resumo['despesasFixas'], formatCurrency),
            _buildRow('(=) Lucro Líquido', resumo['lucroLiquido'], formatCurrency, isBold: true, color: (resumo['lucroLiquido'] >= 0) ? Colors.green : Colors.red),
            Text('Margem Líquida: ${formatPercent.format(resumo['margemLiquidaPercentual'])}%', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, dynamic value, NumberFormat format, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
          Text(format.format(value ?? 0), style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List items, NumberFormat format, {required bool isReceita}) {
    if (items.isEmpty) {
      return Card(
        child: ListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Nenhum registro no período.'),
        ),
      );
    }

    double total = items.fold(0, (sum, item) => sum + (item['valor'] ?? 0));

    return Card(
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Total: ${format.format(total)}', style: TextStyle(color: isReceita ? Colors.green : Colors.red)),
        children: items.map((item) {
          return ListTile(
            title: Text(item['categoria']),
            trailing: Text(format.format(item['valor'])),
          );
        }).toList(),
      ),
    );
  }
}
