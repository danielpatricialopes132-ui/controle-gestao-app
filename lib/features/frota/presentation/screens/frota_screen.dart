import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/frota_provider.dart';
import 'widgets/equipamento_modal.dart';
import 'widgets/alocacao_modal.dart';
import 'widgets/manutencao_modal.dart';
import 'package:intl/intl.dart';

class FrotaScreen extends ConsumerStatefulWidget {
  const FrotaScreen({super.key});

  @override
  ConsumerState<FrotaScreen> createState() => _FrotaScreenState();
}

class _FrotaScreenState extends ConsumerState<FrotaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frota e Máquinas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.directions_car), text: 'Equipamentos'),
            Tab(icon: Icon(Icons.build), text: 'Manutenções Preventivas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Help Modal
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Ajuda - Frota e Máquinas'),
                  content: const Text(
                    'Aqui você gerencia os veículos e máquinas pesadas da construtora.\n\n'
                    '- Equipamentos: Cadastre o trator, betoneira ou veículo e informe seu custo diário.\n'
                    '- Alocação: Envie um equipamento para uma obra. Ao concluir a alocação, o sistema pode exibir o custo gerado para relatórios gerenciais.\n'
                    '- Manutenções: Agende preventivas por data para evitar quebras no canteiro de obras.'
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi'))
                  ]
                )
              );
            },
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEquipamentosTab(),
          _buildManutencoesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            EquipamentoModal.show(context);
          } else {
            ManutencaoModal.show(context);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Novo Equipamento' : 'Agendar Manutenção'),
      ),
    );
  }

  Widget _buildEquipamentosTab() {
    final equipAsync = ref.watch(equipamentosProvider);
    return equipAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erro: $e')),
      data: (equipamentos) {
        if (equipamentos.isEmpty) {
          return const Center(child: Text('Nenhum equipamento cadastrado.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: equipamentos.length,
          itemBuilder: (context, index) {
            final e = equipamentos[index];
            final statusColor = e['status'] == 'DISPONIVEL' ? Colors.green : (e['status'] == 'ALOCADO' ? Colors.blue : Colors.red);
            
            // Check active allocation
            final alocacoes = e['alocacoes'] as List;
            final alocacaoAtiva = alocacoes.where((a) => a['dataFim'] == null).firstOrNull;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(Icons.directions_car, color: statusColor),
                ),
                title: Text('${e['identificador']} - ${e['modelo'] ?? 'Sem modelo'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${e['status']} | Custo Dia: R\$ ${e['custoDiario']}'),
                    if (alocacaoAtiva != null)
                      Text('Na obra: ${alocacaoAtiva['obra']?['nome']}', style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                  ]
                ),
                children: [
                  ButtonBar(
                    children: [
                      if (e['status'] == 'DISPONIVEL')
                        TextButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('Alocar na Obra'),
                          onPressed: () => AlocacaoModal.show(context, e['id']),
                        ),
                      if (e['status'] == 'ALOCADO' && alocacaoAtiva != null)
                        TextButton.icon(
                          icon: const Icon(Icons.assignment_return),
                          label: const Text('Desalocar (Retornar)'),
                          onPressed: () => _desalocarEquipamento(alocacaoAtiva['id']),
                        ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        onPressed: () => EquipamentoModal.show(context, equipamento: e),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Excluir', style: TextStyle(color: Colors.red)),
                        onPressed: () => _excluirEquipamento(e['id']),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildManutencoesTab() {
    final equipAsync = ref.watch(equipamentosProvider);
    return equipAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erro: $e')),
      data: (equipamentos) {
        final todasManutencoes = <Map<String,dynamic>>[];
        for (var e in equipamentos) {
          for (var m in (e['manutencoes'] as List)) {
            todasManutencoes.add({
              ...m,
              'equipamentoIdentificador': e['identificador'],
              'equipamentoModelo': e['modelo'],
            });
          }
        }

        if (todasManutencoes.isEmpty) {
          return const Center(child: Text('Nenhuma manutenção agendada.'));
        }

        // Sort by date
        todasManutencoes.sort((a, b) => DateTime.parse(a['dataProgramada']).compareTo(DateTime.parse(b['dataProgramada'])));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: todasManutencoes.length,
          itemBuilder: (context, index) {
            final m = todasManutencoes[index];
            final statusColor = m['status'] == 'CONCLUIDA' ? Colors.green : (m['status'] == 'PENDENTE' ? Colors.orange : Colors.red);
            final dataFormatada = DateFormat('dd/MM/yyyy').format(DateTime.parse(m['dataProgramada']));

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(Icons.build, color: statusColor),
                ),
                title: Text('${m['equipamentoIdentificador']} - ${m['descricao']}'),
                subtitle: Text('Data: $dataFormatada | Custo Estimado: R\$ ${m['custoEstimado']}'),
                trailing: DropdownButton<String>(
                  value: m['status'],
                  items: const [
                    DropdownMenuItem(value: 'PENDENTE', child: Text('PENDENTE')),
                    DropdownMenuItem(value: 'CONCLUIDA', child: Text('CONCLUÍDA')),
                    DropdownMenuItem(value: 'ATRASADA', child: Text('ATRASADA')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _alterarStatusManutencao(m['id'], val);
                    }
                  },
                ),
              ),
            );
          },
        );
      }
    );
  }

  void _desalocarEquipamento(String alocacaoId) async {
    try {
      final hoje = DateTime.now().toIso8601String();
      await ref.read(frotaControllerProvider.notifier).desalocarEquipamento(alocacaoId, hoje);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipamento desalocado com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  void _excluirEquipamento(String id) async {
    try {
      await ref.read(frotaControllerProvider.notifier).deleteEquipamento(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipamento excluído com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  void _alterarStatusManutencao(String id, String status) async {
    try {
      await ref.read(frotaControllerProvider.notifier).updateManutencaoStatus(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status da manutenção atualizado!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }
}
