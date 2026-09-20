import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/ponto_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'whatsapp_import_modal.dart';

class PontoScreen extends ConsumerStatefulWidget {
  const PontoScreen({super.key});

  @override
  ConsumerState<PontoScreen> createState() => _PontoScreenState();
}

class _PontoScreenState extends ConsumerState<PontoScreen> {
  String _activeTab = 'lancar'; // 'lancar' | 'aprovar'
  DateTime _selectedDate = DateTime.now();
  String? _selectedObraId;

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(appUserProvider);
    final ehAdmin = userData?['role'] == 'MASTER' || userData?['role'] == 'ADMIN' || userData?['role'] == 'ESCRITORIO';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Controle de Ponto Administrativo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Lançamento de presença e validação', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            if (ehAdmin)
              ElevatedButton.icon(
                onPressed: () => _openWhatsAppImportModal(),
                icon: const Icon(Icons.message),
                label: const Text('Importar Escala WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              )
          ],
        ),
        const SizedBox(height: 16),
        if (ehAdmin)
          Row(
            children: [
              _buildTabButton('Lançar Ponto', 'lancar'),
              const SizedBox(width: 8),
              _buildTabButton('Aprovações Pendentes', 'aprovar'),
            ],
          ),
        const Divider(),
        Expanded(
          child: _activeTab == 'lancar' ? _buildLancarTab() : _buildAprovarTab(),
        )
      ],
    );
  }

  Widget _buildTabButton(String title, String value) {
    final isActive = _activeTab == value;
    return ElevatedButton(
      onPressed: () => setState(() => _activeTab = value),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.indigo : Colors.grey.shade200,
        foregroundColor: isActive ? Colors.white : Colors.black87,
        elevation: isActive ? 2 : 0,
      ),
      child: Text(title),
    );
  }

  Widget _buildLancarTab() {
    final pontoDataAsync = ref.watch(pontoDataFuturoProvider(
      PontoParams(
        dataStr: DateFormat('yyyy-MM-dd').format(_selectedDate), 
        obraId: _selectedObraId,
      )
    ));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Data', border: OutlineInputBorder()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                      },
                    ),
                    Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, size: 20),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: pontoDataAsync.when(
                data: (res) {
                  final obras = res['obras'] as List<dynamic>;
                  if (obras.isNotEmpty && _selectedObraId == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() { _selectedObraId = obras.first['id']; });
                    });
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedObraId,
                    decoration: const InputDecoration(
                      labelText: 'Obra / Centro de Custo',
                      border: OutlineInputBorder(),
                    ),
                    items: obras.map((o) => DropdownMenuItem<String>(
                      value: o['id'], 
                      child: Text(o['nome'])
                    )).toList(),
                    onChanged: (val) {
                      setState(() => _selectedObraId = val);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => const Text('Erro ao carregar obras'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _selectedObraId == null 
            ? const Center(child: Text('Selecione uma obra acima para lançar o ponto.'))
            : PontoTableForm(
                dataStr: DateFormat('yyyy-MM-dd').format(_selectedDate),
                obraId: _selectedObraId!,
              ),
        )
      ],
    );
  }

  Widget _buildAprovarTab() {
    final pendentesAsync = ref.watch(pontosPendentesProvider);
    
    return pendentesAsync.when(
      data: (pendentes) {
        if (pendentes.isEmpty) {
          return const Center(child: Text('Nenhum registro pendente de aprovação.'));
        }
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(pontoControllerProvider.notifier).aprovarEmLote(
                    pendentes.map<String>((p) => p['id'] as String).toList()
                  );
                  ref.invalidate(pontosPendentesProvider);
                },
                icon: const Icon(Icons.check_circle),
                label: Text('Aprovar Todos (${pendentes.length})'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: pendentes.length,
                itemBuilder: (context, index) {
                  final p = pendentes[index];
                  return Card(
                    child: ListTile(
                      title: Text('${p['funcionario']['nome']} - ${p['obra']['nome']}'),
                      subtitle: Text('${DateFormat('dd/MM/yyyy').format(DateTime.parse(p['data']))} | ${p['status']} | ${p['horasTrabalhadas']}h'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await ref.read(pontoControllerProvider.notifier).aprovarRejeitar(p['id'], 'APROVADO');
                              ref.invalidate(pontosPendentesProvider);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              await ref.read(pontoControllerProvider.notifier).aprovarRejeitar(p['id'], 'REJEITADO');
                              ref.invalidate(pontosPendentesProvider);
                            },
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erro: $e')),
    );
  }

  void _openWhatsAppImportModal() {
    showDialog(
      context: context,
      builder: (_) => const WhatsAppImportModal(),
    );
  }
}

class PontoTableForm extends ConsumerStatefulWidget {
  final String dataStr;
  final String obraId;
  const PontoTableForm({super.key, required this.dataStr, required this.obraId});

  @override
  ConsumerState<PontoTableForm> createState() => _PontoTableFormState();
}

class _PontoTableFormState extends ConsumerState<PontoTableForm> {
  final Map<String, dynamic> _rows = {};
  String _filtroVinculo = 'TODOS'; // 'TODOS' | 'PROPRIO' | 'EMPREITEIRO' | 'SUBCONTRATADO'

  @override
  Widget build(BuildContext context) {
    final pontoDataAsync = ref.watch(pontoDataFuturoProvider(
      PontoParams(dataStr: widget.dataStr, obraId: widget.obraId)
    ));
    final isSaving = ref.watch(pontoControllerProvider) is AsyncLoading;

    return pontoDataAsync.when(
      data: (res) {
        final todosFuncionarios = res['funcionarios'] as List<dynamic>;
        final pontosExistentes = res['pontosExistentes'] as List<dynamic>;

        // Initialize rows
        if (_rows.isEmpty) {
          for (var f in todosFuncionarios) {
            final ext = pontosExistentes.firstWhere((p) => p['funcionarioId'] == f['id'], orElse: () => null);
            _rows[f['id']] = {
              'status': ext != null ? ext['status'] : 'NA',
              'horasTrabalhadas': ext != null ? ext['horasTrabalhadas'].toString() : '0',
              'percentualPago': ext != null ? ext['percentualPago'].toString() : '100',
              'observacoes': ext != null ? (ext['observacao'] ?? '') : '',
              'statusAprovacao': ext != null ? ext['statusAprovacao'] : null,
            };
          }
        }

        if (todosFuncionarios.isEmpty) {
          return const Center(child: Text('Nenhum funcionário cadastrado.'));
        }

        // Filtrar funcionários de acordo com o vínculo
        final funcionarios = todosFuncionarios.where((f) {
          final fornecedor = f['fornecedor'];
          if (_filtroVinculo == 'TODOS') return true;
          if (_filtroVinculo == 'PROPRIO') return fornecedor == null;
          if (_filtroVinculo == 'SUBCONTRATADO') {
            return fornecedor != null && (fornecedor['tipoFornecedor'] == 'SUBCONTRATADO' || fornecedor['empreiteiroPai'] != null);
          }
          if (_filtroVinculo == 'EMPREITEIRO') {
            return fornecedor != null && fornecedor['tipoFornecedor'] == 'EMPREITEIRO' && fornecedor['empreiteiroPai'] == null;
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Filtro por vínculo trabalhista
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Text('Filtrar Equipe: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _filtroVinculo == 'TODOS',
                    onSelected: (_) => setState(() => _filtroVinculo = 'TODOS'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Equipe Própria'),
                    selected: _filtroVinculo == 'PROPRIO',
                    onSelected: (_) => setState(() => _filtroVinculo = 'PROPRIO'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Empreiteiros Principais'),
                    selected: _filtroVinculo == 'EMPREITEIRO',
                    selectedColor: Colors.indigo.shade100,
                    onSelected: (_) => setState(() => _filtroVinculo = 'EMPREITEIRO'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Subcontratados'),
                    selected: _filtroVinculo == 'SUBCONTRATADO',
                    selectedColor: Colors.purple.shade100,
                    onSelected: (_) => setState(() => _filtroVinculo = 'SUBCONTRATADO'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Colaborador / Vínculo')),
                    DataColumn(label: Text('Status Dia')),
                    DataColumn(label: Text('Horas')),
                    DataColumn(label: Text('Obs')),
                    DataColumn(label: Text('Status Aprov.')),
                  ],
                  rows: funcionarios.map((f) {
                    final row = _rows[f['id']]!;
                    final fornecedor = f['fornecedor'];
                    final ehSub = fornecedor != null && (fornecedor['tipoFornecedor'] == 'SUBCONTRATADO' || fornecedor['empreiteiroPai'] != null);
                    final ehEmp = fornecedor != null && !ehSub;

                    return DataRow(cells: [
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(f['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(f['cargo'] ?? 'Sem cargo', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          if (ehSub)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.purple.shade200)),
                                child: Text(
                                  'Sub: ${fornecedor['nomeRazao'] ?? fornecedor['nome']}${fornecedor['empreiteiroPai'] != null ? ' (de ${fornecedor['empreiteiroPai']['nomeRazao'] ?? fornecedor['empreiteiroPai']['nome']})' : ''}',
                                  style: TextStyle(color: Colors.purple.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                          else if (ehEmp)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.indigo.shade200)),
                                child: Text(
                                  'Empreiteiro: ${fornecedor['nomeRazao'] ?? fornecedor['nome']}',
                                  style: TextStyle(color: Colors.indigo.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      )),
                      DataCell(
                        DropdownButton<String>(
                          value: row['status'],
                          items: const [
                            DropdownMenuItem(value: 'TRABALHO', child: Text('Trabalho')),
                            DropdownMenuItem(value: 'VIAGEM', child: Text('Viagem')),
                            DropdownMenuItem(value: 'CHUVA', child: Text('Chuva')),
                            DropdownMenuItem(value: 'FALTA', child: Text('Falta')),
                            DropdownMenuItem(value: 'NA', child: Text('N/A')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              row['status'] = val;
                              if (val == 'NA' || val == 'FALTA') row['horasTrabalhadas'] = '0';
                              else if (val == 'TRABALHO' || val == 'VIAGEM' || val == 'CHUVA') row['horasTrabalhadas'] = '8';
                            });
                          },
                        )
                      ),
                      DataCell(
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            initialValue: row['horasTrabalhadas'],
                            keyboardType: TextInputType.number,
                            onChanged: (val) => row['horasTrabalhadas'] = val,
                          ),
                        )
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: TextFormField(
                            initialValue: row['observacoes'],
                            onChanged: (val) => row['observacoes'] = val,
                          ),
                        )
                      ),
                      DataCell(
                        row['statusAprovacao'] != null 
                          ? Chip(label: Text(row['statusAprovacao'], style: const TextStyle(fontSize: 10)))
                          : const Text('Não lançado', style: TextStyle(color: Colors.grey, fontSize: 12))
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : () async {
                    final payload = _rows.entries.map((e) => {
                      'funcionarioId': e.key,
                      'status': e.value['status'],
                      'horasTrabalhadas': double.tryParse(e.value['horasTrabalhadas']) ?? 0,
                      'percentualPago': double.tryParse(e.value['percentualPago']) ?? 100,
                      'observacoes': e.value['observacoes'],
                    }).toList();

                    await ref.read(pontoControllerProvider.notifier).salvarDiario(
                      dataStr: widget.dataStr,
                      obraId: widget.obraId,
                      registros: payload,
                    );
                    
                    ref.invalidate(pontoDataFuturoProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ponto salvo com sucesso!')));
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar e Enviar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                ),
              ),
            )
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Erro ao carregar folha')),
    );
  }
}
