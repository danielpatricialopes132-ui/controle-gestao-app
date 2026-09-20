import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/suprimentos_provider.dart';
import 'contratos_empreiteiro_screen.dart';

class FornecedoresScreen extends ConsumerStatefulWidget {
  const FornecedoresScreen({super.key});

  @override
  ConsumerState<FornecedoresScreen> createState() => _FornecedoresScreenState();
}

class _FornecedoresScreenState extends ConsumerState<FornecedoresScreen> {
  String _filtroTipo = 'TODOS';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(suprimentosProvider.notifier).fetchFornecedores());
  }

  void _showAddFornecedorModal() {
    final nomeController = TextEditingController();
    final cnpjController = TextEditingController();
    final telefoneController = TextEditingController();
    final emailController = TextEditingController();
    final chavePixController = TextEditingController();
    final bancoController = TextEditingController();
    final agenciaController = TextEditingController();
    final contaController = TextEditingController();

    String tipoFornecedor = 'MATERIAL';
    String? empreiteiroPaiId;

    final todosFornecedores = ref.read(suprimentosProvider).fornecedores;
    final empreiteirosPrincipais = todosFornecedores.where((f) => f['tipoFornecedor'] == 'EMPREITEIRO').toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Novo Fornecedor / Empreiteiro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: tipoFornecedor,
                      decoration: const InputDecoration(labelText: 'Tipo de Fornecedor *', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'MATERIAL', child: Text('Fornecedor de Materiais / Insumos')),
                        DropdownMenuItem(value: 'EMPREITEIRO', child: Text('Empreiteiro Principal (Prestador Direto)')),
                        DropdownMenuItem(value: 'SUBCONTRATADO', child: Text('Subcontratado (Terceiro do Empreiteiro)')),
                        DropdownMenuItem(value: 'SERVICO', child: Text('Prestador de Serviços Gerais / Locação')),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          tipoFornecedor = val ?? 'MATERIAL';
                          if (tipoFornecedor != 'SUBCONTRATADO') {
                            empreiteiroPaiId = null;
                          }
                        });
                      },
                    ),
                    if (tipoFornecedor == 'SUBCONTRATADO') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: empreiteiroPaiId,
                        decoration: const InputDecoration(
                          labelText: 'Empreiteiro Principal Responsável *',
                          border: OutlineInputBorder(),
                          helperText: 'Empresa contratante que subcontratou este serviço',
                        ),
                        items: empreiteirosPrincipais.isEmpty
                            ? [const DropdownMenuItem(value: null, child: Text('Nenhum Empreiteiro Principal cadastrado'))]
                            : empreiteirosPrincipais.map<DropdownMenuItem<String>>((ep) {
                                return DropdownMenuItem(
                                  value: ep['id'] as String,
                                  child: Text(ep['nomeRazao'] ?? ep['nome']),
                                );
                              }).toList(),
                        onChanged: (val) => setModalState(() => empreiteiroPaiId = val),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(labelText: 'Razão Social / Nome Fantasia *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cnpjController,
                            decoration: const InputDecoration(labelText: 'CNPJ / CPF', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: telefoneController,
                            decoration: const InputDecoration(labelText: 'Telefone / WhatsApp', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'E-mail para Notificações', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    const Text('Dados para Pagamento (Opcional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: chavePixController,
                      decoration: const InputDecoration(labelText: 'Chave PIX', border: OutlineInputBorder(), prefixIcon: Icon(Icons.pix)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(flex: 2, child: TextField(controller: bancoController, decoration: const InputDecoration(labelText: 'Banco', border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: agenciaController, decoration: const InputDecoration(labelText: 'Agência', border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: TextField(controller: contaController, decoration: const InputDecoration(labelText: 'Conta', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (nomeController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o nome do fornecedor.')));
                          return;
                        }
                        if (tipoFornecedor == 'SUBCONTRATADO' && empreiteiroPaiId == null && empreiteirosPrincipais.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione o Empreiteiro Principal responsável.')));
                          return;
                        }
                        try {
                          await ref.read(suprimentosProvider.notifier).createFornecedor({
                            'nome': nomeController.text.trim(),
                            'cnpj': cnpjController.text.trim().isNotEmpty ? cnpjController.text.trim() : null,
                            'telefone': telefoneController.text.trim().isNotEmpty ? telefoneController.text.trim() : null,
                            'email': emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                            'tipoFornecedor': tipoFornecedor,
                            'empreiteiroPaiId': empreiteiroPaiId,
                            'chavePix': chavePixController.text.trim().isNotEmpty ? chavePixController.text.trim() : null,
                            'banco': bancoController.text.trim().isNotEmpty ? bancoController.text.trim() : null,
                            'agencia': agenciaController.text.trim().isNotEmpty ? agenciaController.text.trim() : null,
                            'conta': contaController.text.trim().isNotEmpty ? contaController.text.trim() : null,
                          });
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                      child: const Text('Salvar Fornecedor'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(suprimentosProvider);

    final fornecedoresFiltrados = provider.fornecedores.where((f) {
      if (_filtroTipo == 'TODOS') return true;
      final tipo = f['tipoFornecedor'] ?? 'MATERIAL';
      return tipo == _filtroTipo;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fornecedores & Empreiteiros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(suprimentosProvider.notifier).fetchFornecedores(),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Todos', 'TODOS'),
                _buildFilterChip('Materiais', 'MATERIAL'),
                _buildFilterChip('Empreiteiros', 'EMPREITEIRO'),
                _buildFilterChip('Subcontratados', 'SUBCONTRATADO'),
                _buildFilterChip('Serviços', 'SERVICO'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : fornecedoresFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Nenhum fornecedor cadastrado nesta categoria.'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: fornecedoresFiltrados.length,
                        itemBuilder: (context, index) {
                          final f = fornecedoresFiltrados[index];
                          final tipo = f['tipoFornecedor'] ?? 'MATERIAL';
                          final ehEmpreiteiroOuSub = tipo == 'EMPREITEIRO' || tipo == 'SUBCONTRATADO';
                          final subcontratados = (f['subcontratados'] as List<dynamic>?) ?? [];
                          final pai = f['empreiteiroPai'];

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getTipoColor(tipo).withOpacity(0.15),
                                child: Icon(_getTipoIcon(tipo), color: _getTipoColor(tipo)),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      f['nomeRazao'] ?? f['nome'] ?? 'Sem nome',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  _buildTipoBadge(tipo),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${f['cnpj'] != null ? 'CNPJ: ${f['cnpj']} | ' : ''}${f['telefone'] ?? 'Sem telefone'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (tipo == 'SUBCONTRATADO' && pai != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '↳ Subcontratado de: ${pai['nomeRazao'] ?? pai['nome']}',
                                        style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  if (tipo == 'EMPREITEIRO' && subcontratados.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Possui ${subcontratados.length} subcontratado(s) vinculado(s)',
                                        style: const TextStyle(color: Colors.teal, fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: ehEmpreiteiroOuSub
                                  ? IconButton(
                                      icon: const Icon(Icons.handshake, color: Colors.indigo),
                                      tooltip: 'Ver Contratos',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ContratosEmpreiteiroScreen(
                                              initialFornecedorId: f['id'],
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : const Icon(Icons.chevron_right),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFornecedorModal,
        tooltip: 'Adicionar Fornecedor',
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtroTipo == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filtroTipo = value),
        selectedColor: Colors.orange.shade100,
        checkmarkColor: Colors.orange.shade900,
      ),
    );
  }

  Widget _buildTipoBadge(String tipo) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;
    String label = tipo;

    switch (tipo) {
      case 'EMPREITEIRO':
        bg = Colors.indigo.shade100;
        fg = Colors.indigo.shade800;
        label = 'Empreiteiro';
        break;
      case 'SUBCONTRATADO':
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade800;
        label = 'Subcontratado';
        break;
      case 'MATERIAL':
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        label = 'Materiais';
        break;
      case 'SERVICO':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        label = 'Serviço';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'EMPREITEIRO': return Colors.indigo;
      case 'SUBCONTRATADO': return Colors.purple;
      case 'MATERIAL': return Colors.orange;
      case 'SERVICO': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'EMPREITEIRO': return Icons.engineering;
      case 'SUBCONTRATADO': return Icons.construction;
      case 'MATERIAL': return Icons.inventory_2;
      case 'SERVICO': return Icons.miscellaneous_services;
      default: return Icons.local_shipping;
    }
  }
}
