import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/importacao_csv_provider.dart';

class ImportacaoCsvScreen extends ConsumerStatefulWidget {
  const ImportacaoCsvScreen({super.key});

  @override
  ConsumerState<ImportacaoCsvScreen> createState() => _ImportacaoCsvScreenState();
}

class _ImportacaoCsvScreenState extends ConsumerState<ImportacaoCsvScreen> {
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic>? _contextData;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final base64File = base64Encode(bytes);
      
      setState(() {
        _isLoading = true;
        _rows = [];
      });

      try {
        final res = await ref.read(importacaoCsvProvider.notifier).analisarCsv(
          base64File,
          'text/csv',
        );

        if (res['rows'] != null) {
          setState(() {
            _rows = List<Map<String, dynamic>>.from(res['rows']);
            _contextData = res['context'];
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao analisar CSV: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _efetivar() async {
    final selectedRows = _rows.where((r) => r['validationStatus'] != 'ERRO' && r['selected'] != false).toList();
    if (selectedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma linha selecionada/válida para importar.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await ref.read(importacaoCsvProvider.notifier).efetivarImportacao(selectedRows);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Importado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao efetivar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importação Inteligente (CSV)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.table_chart, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Nenhum arquivo analisado'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Selecionar arquivo .csv'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Importar')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Data Pgto')),
                              DataColumn(label: Text('Tipo')),
                              DataColumn(label: Text('Contato')),
                              DataColumn(label: Text('Categoria')),
                              DataColumn(label: Text('Conta/CC')),
                              DataColumn(label: Text('Valor')),
                            ],
                            rows: _rows.map((row) {
                              final isSelected = row['selected'] ?? true;
                              final status = row['validationStatus'];
                              
                              Icon statusIcon;
                              if (status == 'PRONTO') {
                                statusIcon = const Icon(Icons.check_circle, color: Colors.green);
                              } else if (status == 'ATENCAO') {
                                statusIcon = const Icon(Icons.warning, color: Colors.orange);
                              } else {
                                statusIcon = const Icon(Icons.error, color: Colors.red);
                              }

                              return DataRow(
                                selected: isSelected,
                                onSelectChanged: (val) {
                                  setState(() {
                                    row['selected'] = val;
                                  });
                                },
                                cells: [
                                  DataCell(
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (val) {
                                        setState(() {
                                          row['selected'] = val;
                                        });
                                      },
                                    ),
                                  ),
                                  DataCell(Tooltip(
                                    message: (row['warnings'] as List?)?.join('\n') ?? (row['errors'] as List?)?.join('\n') ?? 'Ok',
                                    child: statusIcon,
                                  )),
                                  DataCell(Text(row['dataPagamento'] != null ? row['dataPagamento'].toString().substring(0, 10) : '')),
                                  DataCell(Text(row['tipo'])),
                                  DataCell(Text(row['clienteFornecedor'] ?? '')),
                                  DataCell(Text(row['planoContaStr'] ?? '')),
                                  DataCell(Text(row['centroCustoStr'] ?? '')),
                                  DataCell(Text('R\$ ${row['valor']}')),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _rows = [];
                              });
                            },
                            child: const Text('Cancelar / Novo Arquivo'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _efetivar,
                            icon: const Icon(Icons.save),
                            label: const Text('Confirmar Importação'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
    );
  }
}
