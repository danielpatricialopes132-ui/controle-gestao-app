import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/folha_pagamento_provider.dart';

class FolhaPagamentoTab extends ConsumerStatefulWidget {
  const FolhaPagamentoTab({super.key});

  @override
  ConsumerState<FolhaPagamentoTab> createState() => _FolhaPagamentoTabState();
}

class _FolhaPagamentoTabState extends ConsumerState<FolhaPagamentoTab> {
  // Guardamos as edições manuais do usuário: funcionarioId -> valor ajustado
  final Map<String, double> _valoresAjustados = {};
  
  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(folhaFiltersProvider);
    final asyncData = ref.watch(folhaPagamentoProvider);

    return Column(
      children: [
        _buildFilters(context, filters),
        Expanded(
          child: asyncData.when(
            data: (folha) => _buildTable(context, folha),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Erro: $e')),
          ),
        ),
        if (asyncData.hasValue && asyncData.value!.isNotEmpty)
          _buildActionFooter(context, asyncData.value!),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, FolhaPagamentoState filters) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: filters.dataInicio,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  ref.read(folhaFiltersProvider.notifier).state = filters.copyWith(dataInicio: date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Data Inicial', border: OutlineInputBorder()),
                child: Text(DateFormat('dd/MM/yyyy').format(filters.dataInicio)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: filters.dataFim,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  ref.read(folhaFiltersProvider.notifier).state = filters.copyWith(dataFim: date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Data Final', border: OutlineInputBorder()),
                child: Text(DateFormat('dd/MM/yyyy').format(filters.dataFim)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<dynamic> folha) {
    if (folha.isEmpty) {
      return const Center(child: Text('Nenhum dado encontrado para o período.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Funcionário')),
            DataColumn(label: Text('Dias Trab.')),
            DataColumn(label: Text('Horas')),
            DataColumn(label: Text('Faltas')),
            DataColumn(label: Text('Base / Diária')),
            DataColumn(label: Text('Vlr. Sugerido')),
            DataColumn(label: Text('Vlr. Líquido (Ajustável)')),
          ],
          rows: folha.map((item) {
            final func = item['funcionario'];
            final est = item['estatisticas'];
            final fin = item['financeiro'];
            
            final isMensal = func['tipoPagamento'] == 'MENSAL';
            final defaultAjustado = fin['valorAjustado'].toDouble();
            final valorAjustado = _valoresAjustados[func['id']] ?? defaultAjustado;

            return DataRow(
              cells: [
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(func['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(isMensal ? 'Mensalista' : 'Diarista', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )),
                DataCell(Text('${est['diasTrabalhados']}')),
                DataCell(Text('${est['totalHoras']}h')),
                DataCell(Text('${est['totalFaltas']}', style: TextStyle(color: est['totalFaltas'] > 0 ? Colors.red : null))),
                DataCell(Text('R\$ ${fin['base']}')),
                DataCell(Text('R\$ ${fin['valorSugerido']}')),
                DataCell(
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      initialValue: valorAjustado.toStringAsFixed(2),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixText: 'R\$ ', isDense: true),
                      onChanged: (val) {
                        final parsed = double.tryParse(val.replaceAll(',', '.'));
                        if (parsed != null) {
                          _valoresAjustados[func['id']] = parsed;
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionFooter(BuildContext context, List<dynamic> folha) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.payment),
            label: const Text('Lançar Pagamentos no Financeiro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _lancarFinanceiro(folha),
          ),
        ],
      ),
    );
  }

  void _lancarFinanceiro(List<dynamic> folhaOriginal) async {
    // Mesclar ajustes
    final payload = folhaOriginal.map((item) {
      final id = item['funcionario']['id'];
      final adjusted = _valoresAjustados[id] ?? item['financeiro']['valorAjustado'].toDouble();
      item['financeiro']['valorAjustado'] = adjusted;
      return item;
    }).toList();

    // Filtro os zerados se não quiser lançar
    final itemsParaLancar = payload.where((item) => item['financeiro']['valorAjustado'] > 0).toList();

    if (itemsParaLancar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum valor a lançar.')));
      return;
    }

    final filters = ref.read(folhaFiltersProvider);
    final mes = DateFormat('MM/yyyy').format(filters.dataInicio);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Lançamento'),
        content: Text('Serão gerados ${itemsParaLancar.length} lançamentos pendentes no financeiro referente à folha de $mes. Deseja continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(folhaPagamentoControllerProvider.notifier)
                    .gerarPagamentos(itemsParaLancar, 'Folha de Pagto $mes');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lançamentos criados com sucesso!')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                }
              }
            },
            child: const Text('Confirmar'),
          )
        ],
      )
    );
  }
}
