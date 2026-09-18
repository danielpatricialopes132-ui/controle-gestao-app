import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/rh_provider.dart';
import '../../../obras/providers/obras_provider.dart';
import '../../../obras/providers/obra_ged_provider.dart';
import '../../../obras/services/rdo_pdf_service.dart';
import 'package:intl/intl.dart';

class ApontamentosAba extends ConsumerStatefulWidget {
  const ApontamentosAba({super.key});

  @override
  ConsumerState<ApontamentosAba> createState() => _ApontamentosAbaState();
}

class _ApontamentosAbaState extends ConsumerState<ApontamentosAba> {
  String? _obraSelecionada;
  DateTime _dataSelecionada = DateTime.now();
  List<Map<String, dynamic>> _apontamentosLocal = [];
  bool _carregando = false;

  void _carregarDiario() async {
    if (_obraSelecionada == null) return;
    setState(() => _carregando = true);

    try {
      final equipe = await ref.read(funcionariosProvider.future);
      final dataIso = _dataSelecionada.toIso8601String();
      final apontamentosSalvos = await ref.read(rhControllerProvider.notifier).getApontamentos(_obraSelecionada!, dataIso);

      // Mesclar todos os funcionários com os apontamentos já salvos (se existirem)
      _apontamentosLocal = equipe.map((f) {
        final salvo = apontamentosSalvos.firstWhere((a) => a['funcionarioId'] == f['id'], orElse: () => null);
        return {
          'funcionarioId': f['id'],
          'nome': f['nome'],
          'tipo': f['tipoColaborador'],
          'status': salvo != null ? salvo['status'] : 'PRESENTE',
          'horasTrabalhadas': salvo != null ? salvo['horasTrabalhadas'] : 8,
          'percentualPago': salvo != null ? salvo['percentualPago'] : 100,
          'observacao': salvo != null ? salvo['observacao'] : '',
        };
      }).toList();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _salvarLote() async {
    if (_obraSelecionada == null) return;
    final dataIso = _dataSelecionada.toIso8601String();
    
    try {
      await ref.read(rhControllerProvider.notifier).saveApontamentosLote(_obraSelecionada!, dataIso, _apontamentosLocal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diário de obra salvo com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final obrasAsync = ref.watch(obrasProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: obrasAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, st) => Text('Erro: $e'),
                  data: (obras) => DropdownButtonFormField<String>(
                    value: _obraSelecionada,
                    decoration: const InputDecoration(labelText: 'Filtrar por Obra', border: OutlineInputBorder()),
                    items: obras.map<DropdownMenuItem<String>>((o) => DropdownMenuItem(
                      value: o['id'],
                      child: Text(o['nome']),
                    )).toList(),
                    onChanged: (val) {
                      setState(() => _obraSelecionada = val);
                      _carregarDiario();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dataSelecionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _dataSelecionada = date);
                      _carregarDiario();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Data', border: OutlineInputBorder()),
                    child: Text(DateFormat('dd/MM/yyyy').format(_dataSelecionada)),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_obraSelecionada != null && !_carregando) ...[
          Expanded(
            child: ListView.builder(
              itemCount: _apontamentosLocal.length,
              itemBuilder: (context, index) {
                final ap = _apontamentosLocal[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text('${ap['nome']}\n(${ap['tipo']})', style: const TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: ap['status'],
                            decoration: const InputDecoration(isDense: true),
                            items: const [
                              DropdownMenuItem(value: 'PRESENTE', child: Text('Presente')),
                              DropdownMenuItem(value: 'FALTA', child: Text('Falta')),
                              DropdownMenuItem(value: 'MEIO_PERIODO', child: Text('Meio Período')),
                            ],
                            onChanged: (val) => setState(() => ap['status'] = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: ap['horasTrabalhadas']?.toString(),
                            decoration: const InputDecoration(labelText: 'Horas', isDense: true),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => ap['horasTrabalhadas'] = double.tryParse(val) ?? 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: ap['percentualPago']?.toString(),
                            decoration: const InputDecoration(labelText: '% Diária', isDense: true),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => ap['percentualPago'] = double.tryParse(val) ?? 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar Diário'),
                    onPressed: _salvarLote,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Exportar RDO'),
                    onPressed: () async {
                      if (_obraSelecionada == null) return;
                      // Buscar fotos do GED
                      try {
                        final todosDocs = await ref.read(documentosObraProvider(_obraSelecionada!).future);
                        final fotos = todosDocs.where((d) => d['tipo'] == 'FOTO').toList();
                        
                        final obraSelecionadaObj = obrasAsync.value?.firstWhere((o) => o['id'] == _obraSelecionada);
                        final nomeObra = obraSelecionadaObj?['nome'] ?? 'Obra';

                        await RdoPdfService.imprimirRdo(nomeObra, _dataSelecionada, _apontamentosLocal, fotos);
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
                      }
                    },
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  ),
                ),
              ],
            ),
          )
        ] else if (_carregando) ...[
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ] else ...[
          const Expanded(child: Center(child: Text('Selecione uma Obra para carregar a equipe.'))),
        ]
      ],
    );
  }
}
