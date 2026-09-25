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
        backgroundColor: const Color(0xFFF3F4F6),
        body: Column(
          children: [
            // Premium Header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF0284C7)]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF0284C7).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.insights_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Inteligência & Relatórios',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Análise gerencial, auditoria financeira e resultados',
                                  style: TextStyle(fontSize: 13, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: mesAno,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                  initialDatePickerMode: DatePickerMode.year,
                                  builder: (context, child) => Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: const ColorScheme.light(primary: Color(0xFF0EA5E9)),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (date != null) {
                                  ref.read(relatorioMesAnoProvider.notifier).setDate(date);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_month_rounded, color: Color(0xFF38BDF8), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMMM / yyyy', 'pt_BR').format(mesAno).toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.5),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: TabBar(
                        isScrollable: true,
                        indicator: const UnderlineTabIndicator(
                          borderSide: BorderSide(width: 3.0, color: Color(0xFF38BDF8)),
                          insets: EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                        labelColor: const Color(0xFF38BDF8),
                        unselectedLabelColor: Colors.white60,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tabs: const [
                          Tab(text: 'DRE Gerencial'),
                          Tab(text: 'Extrato Bancário'),
                          Tab(text: 'Auditoria'),
                          Tab(text: 'Fluxo de Caixa'),
                          Tab(text: 'Lucratividade'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Expanded(
              child: TabBarView(
                physics: BouncingScrollPhysics(),
                children: [
                  DREAba(),
                  ExtratoBancarioAba(),
                  AuditoriaConfirmarAba(),
                  FluxoCaixaAba(),
                  LucratividadeAba(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
