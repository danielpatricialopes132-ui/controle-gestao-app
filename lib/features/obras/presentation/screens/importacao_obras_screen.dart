import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/importacao_obras_provider.dart';

class ImportacaoObrasScreen extends ConsumerStatefulWidget {
  const ImportacaoObrasScreen({super.key});

  @override
  ConsumerState<ImportacaoObrasScreen> createState() => _ImportacaoObrasScreenState();
}

class _ImportacaoObrasScreenState extends ConsumerState<ImportacaoObrasScreen> {
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
        final res = await ref.read(importacaoObrasProvider.notifier).analisarCsv(
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
    final selectedRows = _rows.where((r) => r['validationStatus'] != 'ERRO' && r['skip'] != true).toList();
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
      final res = await ref.read(importacaoObrasProvider.notifier).efetivarImportacao(selectedRows);
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
        title: const Text('Importação Inteligente de Obras (CSV)'),
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
                              DataColumn(label: Text('Obra')),
                              DataColumn(label: Text('Cliente')),
                              DataColumn(label: Text('Empresa')),
                              DataColumn(label: Text('Valor Fechado')),
                              DataColumn(label: Text('Adendos')),
                            ],
                            rows: _rows.map((row) {
                              final isSkipped = row['skip'] == true;
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
                                selected: !isSkipped,
                                onSelectChanged: (val) {
                                  setState(() {
                                    row['skip'] = !(val ?? true);
                                  });
                                },
                                cells: [
                                  DataCell(
                                    Checkbox(
                                      value: !isSkipped,
                                      onChanged: (val) {
                                        setState(() {
                                          row['skip'] = !(val ?? true);
                                        });
                                      },
                                    ),
                                  ),
                                  DataCell(Tooltip(
                                    message: (row['warnings'] as List?)?.join('\n') ?? (row['errors'] as List?)?.join('\n') ?? 'Ok',
                                    child: statusIcon,
                                  )),
                                  DataCell(
                                    Row(
                                      children: [
                                        Text(row['nomeObra'] ?? ''),
                                        if (row['isNovaObra'] == true)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8.0),
                                            child: Chip(
                                              label: Text('NOVA', style: TextStyle(fontSize: 10)),
                                              backgroundColor: Colors.blueAccent,
                                              labelPadding: EdgeInsets.zero,
                                              padding: EdgeInsets.symmetric(horizontal: 4),
                                            ),
                                          )
                                        else if (row['obraId'] != null)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8.0),
                                            child: Chip(
                                              label: Text('INCLUIR DADOS NELA (ATUALIZAR)', style: TextStyle(fontSize: 10, color: Colors.black87)),
                                              backgroundColor: Colors.amberAccent,
                                              labelPadding: EdgeInsets.zero,
                                              padding: EdgeInsets.symmetric(horizontal: 4),
                                            ),
                                          )
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        Text(row['clienteNome'] ?? ''),
                                        if (row['isNovoCliente'] == true)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8.0),
                                            child: Chip(
                                              label: Text('NOVO', style: TextStyle(fontSize: 10)),
                                              backgroundColor: Colors.orangeAccent,
                                              labelPadding: EdgeInsets.zero,
                                              padding: EdgeInsets.symmetric(horizontal: 4),
                                            ),
                                          )
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(row['empresa'] ?? '')),
                                  DataCell(Text('R\$ ${row['valorFechado']}')),
                                  DataCell(Text('${row['totalAdendos'] ?? 0} detectados')),
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


