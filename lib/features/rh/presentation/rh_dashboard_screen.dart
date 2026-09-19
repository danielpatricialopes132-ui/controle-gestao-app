import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rh_provider.dart';
import 'widgets/funcionario_modal.dart';
import 'widgets/vale_modal.dart';
import 'widgets/apontamentos_aba.dart';
import '../services/rh_documentos_pdf_service.dart';
import '../../../shared/widgets/assinatura_modal.dart';
import 'package:intl/intl.dart';

class RhDashboardScreen extends ConsumerStatefulWidget {
  const RhDashboardScreen({super.key});

  @override
  ConsumerState<RhDashboardScreen> createState() => _RhDashboardScreenState();
}

class _RhDashboardScreenState extends ConsumerState<RhDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('RH / Empreiteiros'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Equipe'),
            Tab(icon: Icon(Icons.playlist_add_check), text: 'Apontamentos'),
            Tab(icon: Icon(Icons.money_off), text: 'Adiantamentos (Vales)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEquipeTab(),
          const ApontamentosAba(),
          _buildValesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            FuncionarioModal.show(context);
          } else if (_tabController.index == 2) {
            ValeModal.show(context);
          } else {
            // Aba apontamentos possui controles internos
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma obra e data para apontar.')));
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Novo Colaborador' : (_tabController.index == 2 ? 'Novo Vale' : 'Apontar Lote')),
      ),
    );
  }

  Widget _buildEquipeTab() {
    final funcionariosAsync = ref.watch(funcionariosProvider);
    return funcionariosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erro: $e')),
      data: (equipe) {
        if (equipe.isEmpty) {
          return const Center(child: Text('Nenhum colaborador cadastrado.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: equipe.length,
          itemBuilder: (context, index) {
            final f = equipe[index];
            final isEmpreiteiro = f['tipoColaborador'] == 'EMPREITEIRO';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isEmpreiteiro ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                  child: Icon(isEmpreiteiro ? Icons.business_center : Icons.person, color: isEmpreiteiro ? Colors.orange : Colors.blue),
                ),
                title: Text(f['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${f['cargo']} | ${f['tipoColaborador']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.blueGrey),
                      tooltip: 'Extrato de Vales',
                      onPressed: () async {
                        final vales = await ref.read(valesProvider.future);
                        
                        final assinaturaBytes = await AssinaturaModal.mostrar(context, titulo: 'Assinar Recibo');
                        
                        final tipo = f['tipoColaborador'] ?? 'CLT';
                        if (tipo == 'EMPREITEIRO') {
                          await RhDocumentosPdfService.imprimirExtratoEmpreiteiro(f, vales, assinaturaBytes: assinaturaBytes);
                        } else if (tipo == 'RPA' || tipo == 'DIARISTA') {
                          await RhDocumentosPdfService.imprimirRPA(f, 2500.0, 275.0, 125.0, assinaturaBytes: assinaturaBytes);
                        } else {
                          final salarioBase = double.tryParse(f['salario']?.toString() ?? '0') ?? 2000.0;
                          await RhDocumentosPdfService.imprimirHolerite(f, salarioBase, vales, assinaturaBytes: assinaturaBytes);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => FuncionarioModal.show(context, funcionario: f),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _excluirFuncionario(f['id']),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildValesTab() {
    final valesAsync = ref.watch(valesProvider);
    return valesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erro: $e')),
      data: (vales) {
        if (vales.isEmpty) {
          return const Center(child: Text('Nenhum vale lançado.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vales.length,
          itemBuilder: (context, index) {
            final v = vales[index];
            final dataFormatada = DateFormat('dd/MM/yyyy').format(DateTime.parse(v['dataVencimento']));
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.money_off, color: Colors.white),
                ),
                title: Text('${v['funcionario']['nome']} - R\$ ${v['valor']}'),
                subtitle: Text('${v['descricao']} | Data: $dataFormatada | Obra: ${v['obra']?['nome'] ?? 'Geral'}'),
                trailing: Text(v['status'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            );
          },
        );
      }
    );
  }

  void _excluirFuncionario(String id) async {
    try {
      await ref.read(rhControllerProvider.notifier).deleteFuncionario(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Colaborador excluído com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }
}
