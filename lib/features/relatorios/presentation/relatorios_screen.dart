import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/relatorios_provider.dart';
import 'dre_aba.dart';
import 'fluxo_caixa_aba.dart';
import 'lucratividade_aba.dart';

class RelatoriosScreen extends ConsumerWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesAno = ref.watch(relatorioMesAnoProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Relatórios e Dashboards'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Fluxo de Caixa'),
              Tab(text: 'DRE'),
              Tab(text: 'Lucratividade'),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: mesAno,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (date != null) {
                  ref.read(relatorioMesAnoProvider.notifier).state = date;
                }
              },
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              label: Text(
                DateFormat('MM/yyyy').format(mesAno),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            FluxoCaixaAba(),
            DREAba(),
            LucratividadeAba(),
          ],
        ),
      ),
    );
  }
}
