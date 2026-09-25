import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/relatorios_provider.dart';
import 'dre_aba.dart';
import 'extrato_bancario_aba.dart';
import 'auditoria_confirmar_aba.dart';
import 'fluxo_caixa_aba.dart';
import 'lucratividade_aba.dart';

class RelatoriosScreen extends ConsumerWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesAno = ref.watch(relatorioMesAnoProvider);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007A8D).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Colors.tealAccent, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Painel de Relatórios & Inteligência',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Gestão Contábil, Bancária, Auditoria e Margens',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: const Color(0xFF1E293B),
              child: const TabBar(
                isScrollable: true,
                indicatorColor: Color(0xFF007A8D),
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'DRE Gerencial'),
                  Tab(icon: Icon(Icons.account_balance_wallet_outlined, size: 18), text: 'Extrato Bancário'),
                  Tab(icon: Icon(Icons.policy_outlined, size: 18), text: 'Auditoria (A Confirmar)'),
                  Tab(icon: Icon(Icons.show_chart_rounded, size: 18), text: 'Fluxo de Caixa'),
                  Tab(icon: Icon(Icons.leaderboard_outlined, size: 18), text: 'Lucratividade por Obra'),
                ],
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: mesAno,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDatePickerMode: DatePickerMode.year,
                  );
                  if (date != null) {
                    ref.read(relatorioMesAnoProvider.notifier).setDate(date);
                  }
                },
                icon: const Icon(Icons.calendar_month, color: Colors.tealAccent, size: 18),
                label: Text(
                  DateFormat('MM/yyyy').format(mesAno),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            DREAba(),
            ExtratoBancarioAba(),
            AuditoriaConfirmarAba(),
            FluxoCaixaAba(),
            LucratividadeAba(),
          ],
        ),
      ),
    );
  }
}
