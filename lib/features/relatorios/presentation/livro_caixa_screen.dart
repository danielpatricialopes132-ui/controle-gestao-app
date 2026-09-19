import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/relatorios_provider.dart';
import '../../financeiro/providers/financeiro_provider.dart';

class LivroCaixaScreen extends ConsumerWidget {
  const LivroCaixaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(livroCaixaFiltersProvider);
    final livroCaixaAsync = ref.watch(livroCaixaProvider);
    final contasBancariasAsync = ref.watch(contasBancariasProvider);

    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Livro Caixa'),
        actions: [
          livroCaixaAsync.when(
            data: (data) => IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Exportar para CSV',
              onPressed: () {
                // ref.read(relatoriosProvider).exportarLivroCaixaCsv(data);
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
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
                            ref.read(livroCaixaFiltersProvider.notifier).state = filters.copyWith(dataInicio: date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Data Inicial', border: OutlineInputBorder()),
                          child: Text(dateFormat.format(filters.dataInicio)),
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
                            ref.read(livroCaixaFiltersProvider.notifier).state = filters.copyWith(dataFim: date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Data Final', border: OutlineInputBorder()),
                          child: Text(dateFormat.format(filters.dataFim)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: contasBancariasAsync.when(
                        data: (contas) {
                          return DropdownButtonFormField<String?>(
                            decoration: const InputDecoration(labelText: 'Conta Bancária / Caixa', border: OutlineInputBorder()),
                            value: filters.contaBancariaId,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Todas as Contas (Consolidado)')),
                              ...contas.map((conta) => DropdownMenuItem(
                                value: conta['id'],
                                child: Text(conta['nome']),
                              ))
                            ],
                            onChanged: (value) {
                              ref.read(livroCaixaFiltersProvider.notifier).state = filters.copyWith(contaBancariaId: value);
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('Erro ao carregar contas'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Table
          Expanded(
            child: livroCaixaAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Erro: $error')),
              data: (data) {
                final saldoAnterior = data['saldoAnterior'] as num;
                final transacoes = data['transacoes'] as List<dynamic>;

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                      columns: const [
                        DataColumn(label: Text('Data')),
                        DataColumn(label: Text('Histórico')),
                        DataColumn(label: Text('Conta')),
                        DataColumn(label: Text('Entrada'), numeric: true),
                        DataColumn(label: Text('Saída'), numeric: true),
                        DataColumn(label: Text('Saldo Acumulado'), numeric: true),
                      ],
                      rows: [
                        // Saldo Anterior
                        DataRow(
                          color: WidgetStateProperty.all(Colors.amber[50]),
                          cells: [
                            const DataCell(Text('-')),
                            const DataCell(Text('SALDO ANTERIOR', style: TextStyle(fontWeight: FontWeight.bold))),
                            const DataCell(Text('-')),
                            const DataCell(Text('')),
                            const DataCell(Text('')),
                            DataCell(Text(
                              currencyFormat.format(saldoAnterior),
                              style: TextStyle(fontWeight: FontWeight.bold, color: saldoAnterior >= 0 ? Colors.green : Colors.red),
                            )),
                          ]
                        ),
                        
                        // Transações
                        ...transacoes.map((t) {
                          final date = DateTime.parse(t['dataVencimento']);
                          final isReceita = t['tipo'] == 'RECEITA';
                          final valor = t['valorFormatado'] as num;
                          final saldoAcumulado = t['saldoAcumulado'] as num;
                          
                          return DataRow(
                            cells: [
                              DataCell(Text(dateFormat.format(date))),
                              DataCell(Text(t['descricao'])),
                              DataCell(Text(t['contaBancaria']?['nome'] ?? '-')),
                              DataCell(Text(isReceita ? currencyFormat.format(valor) : '', style: const TextStyle(color: Colors.green))),
                              DataCell(Text(!isReceita ? currencyFormat.format(valor) : '', style: const TextStyle(color: Colors.red))),
                              DataCell(Text(
                                currencyFormat.format(saldoAcumulado),
                                style: TextStyle(color: saldoAcumulado >= 0 ? Colors.green : Colors.red),
                              )),
                            ]
                          );
                        })
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
