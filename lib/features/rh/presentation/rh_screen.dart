import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'funcionario_modal.dart';
import '../providers/rh_provider.dart';
import 'ponto_screen.dart';
import 'folha_pagamento_tab.dart';

class RHScreen extends ConsumerStatefulWidget {
  const RHScreen({super.key});

  @override
  ConsumerState<RHScreen> createState() => _RHScreenState();
}

class _RHScreenState extends ConsumerState<RHScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String? _selectedObraId;
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _presencas = {}; // funcionarioId -> status

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recursos Humanos'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ajuda',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Ajuda - Recursos Humanos'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Bem-vindo ao módulo de RH!\n\n'
                      'Aqui você gerencia sua equipe e a folha de pagamento:\n\n'
                      '• Equipe: Cadastre funcionários, defina se são mensalistas ou diaristas e os valores.\n'
                      '• Diário de Obra: Confira as faltas e presenças (também geradas pelo robô do WhatsApp).\n'
                      '• Folha de Pagto: Calcule os valores do mês e envie os pagamentos diretamente para as Despesas Pendentes do Financeiro.',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Entendi'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Equipe (Funcionários)', icon: Icon(Icons.people)),
            Tab(text: 'Diário de Obra (Ponto)', icon: Icon(Icons.check_circle_outline)),
            Tab(text: 'Folha de Pagto', icon: Icon(Icons.attach_money)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEquipeTab(),
          _buildDiarioObraTab(),
          const FolhaPagamentoTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => FuncionarioModal.show(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Funcionário'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildEquipeTab() {
    final asyncFuncionarios = ref.watch(funcionariosProvider);

    return asyncFuncionarios.when(
      data: (funcionarios) {
        if (funcionarios.isEmpty) {
          return const Center(child: Text('Nenhum funcionário cadastrado.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: funcionarios.length,
          itemBuilder: (context, index) {
            final f = funcionarios[index];
            final temMotorista = f['valorDiariaMotorista'] != null;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(f['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${f['cargo'] ?? 'Sem cargo'}'),
                    if (f['tipoPagamento'] == 'DIARISTA' || f['valorDiaria'] != null)
                      Text('Diária: R\$ ${f['valorDiaria'] ?? '0.00'}')
                    else if (f['salario'] != null)
                      Text('Salário: R\$ ${f['salario']}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (temMotorista)
                      Chip(
                        label: Text('+ Motorista (R\$ ${f['valorDiariaMotorista']})'),
                        backgroundColor: Colors.green.shade50,
                        labelStyle: const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        FuncionarioModal.show(context, funcionario: f);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        try {
                          await ref.read(funcionarioControllerProvider.notifier).deleteFuncionario(f['id']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Funcionário excluído com sucesso!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erro: $e')),
    );
  }

  Widget _buildDiarioObraTab() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: PontoScreen(),
    );
  }
}
