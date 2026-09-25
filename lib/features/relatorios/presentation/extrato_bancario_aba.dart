import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../financeiro/providers/financeiro_provider.dart';
import '../../../shared/utils/export_utils.dart';
import '../utils/pdf_extrato_generator.dart';


class ExtratoBancarioAba extends ConsumerStatefulWidget {
  final bool showAppBar;
  const ExtratoBancarioAba({super.key, this.showAppBar = false});

  @override
  ConsumerState<ExtratoBancarioAba> createState() => _ExtratoBancarioAbaState();
}

class _ExtratoBancarioAbaState extends ConsumerState<ExtratoBancarioAba> {
  String _contaSelecionada = 'todas';
  DateTime _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _dataFim = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

  final _formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _formatDate = DateFormat('dd/MM/yyyy');

  Map<String, String> _getParams() {
    return {
      'contaBancariaId': _contaSelecionada,
      'dataInicio': _dataInicio.toIso8601String(),
      'dataFim': _dataFim.toIso8601String(),
    };
  }

  Future<void> _selecionarData(BuildContext context, bool isInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInicio ? _dataInicio : _dataFim,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        } else {
          _dataFim = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  void _exportarPdf(Map<String, dynamic> data) {
    final transacoes = data['transacoes'] as List;
    final saldoFinal = (data['saldoFinalPeriodo'] ?? 0).toDouble();

    PdfExtratoGenerator.exportC6StylePdf(
      transacoes: transacoes,
      dataInicio: _dataInicio,
      dataFim: _dataFim,
      saldoFinal: saldoFinal,
      empresaNome: 'ECO STONE BRASIL',
      cnpj: '63.011.697/0001-16',
      contaInfo: _contaSelecionada == 'todas' ? 'Todas as Contas Consolidadas' : 'Agência: 1 • Conta Corrente',
    );
  }

  void _exportarCsv(Map<String, dynamic> data) {
    final transacoes = data['transacoes'] as List;
    final rows = <List<dynamic>>[];
    rows.add(['Data', 'Conta', 'Categoria', 'Descrição', 'Tipo', 'Valor', 'Saldo Progressivo']);
    for (var t in transacoes) {
      rows.add([
        _formatDate.format(DateTime.parse(t['data'])),
        t['conta'],
        t['categoria'],
        t['descricao'],
        t['tipo'],
        t['valor'],
        t['saldoProgressivo']
      ]);
    }
    ExportUtils.exportToCsv(
      fileName: 'extrato_bancario',
      rows: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final extratoAsync = ref.watch(extratoProvider(_getParams()));
    final contasAsync = ref.watch(contasBancariasProvider);

    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Superior
          _buildHeaderBanner(extratoAsync),
          const SizedBox(height: 20),

          // Barra de Filtros
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Dropdown de Contas Reais
                  contasAsync.when(
                    data: (contas) {
                      final items = <DropdownMenuItem<String>>[
                        const DropdownMenuItem(value: 'todas', child: Text('Todas as Contas (Consolidado)')),
                      ];
                      for (var c in contas) {
                        items.add(DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text(c['nome']?.toString() ?? 'Conta'),
                        ));
                      }
                      return DropdownButtonHideUnderline(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _contaSelecionada,
                            items: items,
                            onChanged: (val) {
                              if (val != null) setState(() => _contaSelecionada = val);
                            },
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(width: 150, child: LinearProgressIndicator()),
                    error: (_, __) => const Text('Erro ao carregar contas'),
                  ),

                  // Data Inicial
                  InkWell(
                    onTap: () => _selecionarData(context, true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Text('De: ${_formatDate.format(_dataInicio)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),

                  // Data Final
                  InkWell(
                    onTap: () => _selecionarData(context, false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_outlined, size: 16, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Text('Até: ${_formatDate.format(_dataFim)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),

                  // Atalho Mês Atual
                  TextButton.icon(
                    onPressed: () {
                      final now = DateTime.now();
                      setState(() {
                        _dataInicio = DateTime(now.year, now.month, 1);
                        _dataFim = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                      });
                    },
                    icon: const Icon(Icons.replay, size: 16),
                    label: const Text('Mês Atual'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Indicadores de Saldo
          extratoAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (err, stack) => Center(child: Text('Erro: $err')),
            data: (data) {
              final transacoes = data['transacoes'] as List;
              final saldoAbertura = (data['saldoAberturaPeriodo'] ?? 0).toDouble();
              final saldoFinal = (data['saldoFinalPeriodo'] ?? 0).toDouble();
              final variacao = saldoFinal - saldoAbertura;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildBalanceCard(
                          title: 'Saldo de Abertura',
                          value: _formatCurrency.format(saldoAbertura),
                          subtitle: 'Posição em ${_formatDate.format(_dataInicio)}',
                          color: const Color(0xFF64748B),
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildBalanceCard(
                          title: 'Variação no Período',
                          value: (variacao >= 0 ? '+ ' : '') + _formatCurrency.format(variacao),
                          subtitle: '${transacoes.length} movimentações',
                          color: variacao >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          icon: variacao >= 0 ? Icons.trending_up : Icons.trending_down,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildBalanceCard(
                          title: 'Saldo Final Consolidado',
                          value: _formatCurrency.format(saldoFinal),
                          subtitle: 'Posição em ${_formatDate.format(_dataFim)}',
                          color: const Color(0xFF007A8D),
                          icon: Icons.account_balance_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Lista de Transações com visual bancário
                  if (transacoes.isEmpty)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(48.0),
                        child: Center(
                          child: Text(
                            'Nenhuma movimentação bancária registrada para os filtros selecionados.',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transacoes.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (context, index) {
                            final t = transacoes[index];
                            final dt = DateTime.parse(t['data']);
                            final isReceita = t['tipo'] == 'RECEITA';
                            final val = (t['valor'] ?? 0).toDouble();
                            final saldoProg = (t['saldoProgressivo'] ?? 0).toDouble();

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isReceita ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFEF4444).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isReceita ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                      color: isReceita ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t['descricao'] ?? 'Sem descrição',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              _formatDate.format(dt),
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                t['categoria']?.toString() ?? 'Geral',
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF007A8D).withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                t['conta']?.toString() ?? '',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF007A8D), fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        (isReceita ? '+ ' : '- ') + _formatCurrency.format(val),
                                        style: TextStyle(
                                          color: isReceita ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Saldo: ${_formatCurrency.format(saldoProg)}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(title: const Text('Extrato Bancário')),
        body: content,
      );
    }

    return content;
  }

  Widget _buildHeaderBanner(AsyncValue<Map<String, dynamic>> extratoAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF005362), Color(0xFF007A8D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007A8D).withOpacity(0.2),
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
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Extrato Bancário Conciliado',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Acompanhe o saldo real progressivo com base nas contas correntes e aplicações operacionais.',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF007A8D),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              extratoAsync.whenData((data) => _exportarPdf(data));
            },
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Exportar PDF'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              extratoAsync.whenData((data) => _exportarCsv(data));
            },
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('CSV'),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
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
}
