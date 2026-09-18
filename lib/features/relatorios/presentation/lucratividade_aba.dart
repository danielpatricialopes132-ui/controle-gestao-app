import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/relatorios_provider.dart';

class LucratividadeAba extends ConsumerWidget {
  const LucratividadeAba({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lucAsync = ref.watch(lucratividadeProvider);

    return lucAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erro: $e')),
      data: (data) {
        final resumo = data['resumo'];
        final obras = data['obras'] as List;

        final formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
        final formatPercent = NumberFormat.decimalPattern('pt_BR');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Totalizador da Empresa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      _buildRow('Faturamento Total Obras', resumo['faturamentoTotal'], formatCurrency, isBold: true),
                      _buildRow('Despesas Fixas a Ratear', resumo['custosFixosTotais'], formatCurrency, color: Colors.red),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Rateio por Obra', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (obras.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Nenhuma transação vinculada a Obras neste mês.'),
                  ),
                ),
              ...obras.map((obra) {
                return Card(
                  child: ExpansionTile(
                    title: Text(obra['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Lucro Real: ${formatCurrency.format(obra['lucroLiquido'])} (${formatPercent.format(obra['margemLiquida'])}%)',
                      style: TextStyle(color: (obra['lucroLiquido'] >= 0) ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            _buildRow('Faturamento', obra['receitas'], formatCurrency),
                            _buildRow('Custos Diretos', obra['custosDiretos'], formatCurrency, color: Colors.red),
                            _buildRow('Lucro Bruto', obra['lucroBruto'], formatCurrency, isBold: true),
                            const Divider(),
                            _buildRow('Fração de Custos Fixos', obra['rateioDespesasFixas'], formatCurrency, color: Colors.red),
                            _buildRow('Lucro Líquido Final', obra['lucroLiquido'], formatCurrency, isBold: true),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
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
}
