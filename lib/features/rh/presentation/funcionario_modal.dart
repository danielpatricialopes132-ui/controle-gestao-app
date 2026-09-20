import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rh_provider.dart';
import '../../suprimentos/presentation/providers/suprimentos_provider.dart';

class FuncionarioModal extends ConsumerStatefulWidget {
  final Map<String, dynamic>? funcionario;

  const FuncionarioModal({super.key, this.funcionario});

  @override
  ConsumerState<FuncionarioModal> createState() => _FuncionarioModalState();

  static void show(BuildContext context, {Map<String, dynamic>? funcionario}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FuncionarioModal(funcionario: funcionario),
      ),
    );
  }
}

class _FuncionarioModalState extends ConsumerState<FuncionarioModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _cargoController;
  late TextEditingController _salarioController;
  late TextEditingController _diariaMotoristaController;
  
  bool _isMotorista = false;
  String _tipoColaborador = 'PROPRIO'; // 'PROPRIO' | 'TERCEIRIZADO'
  String? _selectedFornecedorId;

  @override
  void initState() {
    super.initState();
    final f = widget.funcionario;
    _nomeController = TextEditingController(text: f?['nome'] ?? '');
    _cargoController = TextEditingController(text: f?['cargo'] ?? '');
    _salarioController = TextEditingController(text: f?['valorPadrao']?.toString() ?? f?['salario']?.toString() ?? '');
    _diariaMotoristaController = TextEditingController(text: f?['valorDiariaMotorista']?.toString() ?? '');
    _isMotorista = f?['valorDiariaMotorista'] != null;
    _tipoColaborador = f?['tipoColaborador'] ?? (f?['fornecedorId'] != null ? 'TERCEIRIZADO' : 'PROPRIO');
    _selectedFornecedorId = f?['fornecedorId'];

    Future.microtask(() => ref.read(suprimentosProvider.notifier).fetchFornecedores());
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cargoController.dispose();
    _salarioController.dispose();
    _diariaMotoristaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(rhControllerProvider);
    final suprimentosState = ref.watch(suprimentosProvider);
    final isLoading = estado is AsyncLoading;

    // Filtra empreiteiros e subcontratados
    final empreiteirosOuSubs = suprimentosState.fornecedores.where((forn) {
      final tipo = forn['tipoFornecedor'] ?? 'MATERIAL';
      return tipo == 'EMPREITEIRO' || tipo == 'SUBCONTRATADO';
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.funcionario != null ? 'Editar Funcionário' : 'Novo Funcionário',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Vínculo Trabalhista
              DropdownButtonFormField<String>(
                value: _tipoColaborador,
                decoration: const InputDecoration(labelText: 'Vínculo do Colaborador *', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'PROPRIO', child: Text('Equipe Própria (CLT / Diarista Direto)')),
                  DropdownMenuItem(value: 'TERCEIRIZADO', child: Text('Terceirizado (Empreiteiro / Subcontratado)')),
                ],
                onChanged: isLoading
                    ? null
                    : (val) {
                        setState(() {
                          _tipoColaborador = val ?? 'PROPRIO';
                          if (_tipoColaborador == 'PROPRIO') {
                            _selectedFornecedorId = null;
                          }
                        });
                      },
              ),
              if (_tipoColaborador == 'TERCEIRIZADO') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedFornecedorId,
                  decoration: const InputDecoration(
                    labelText: 'Empreiteiro / Subcontratado Vinculado *',
                    border: OutlineInputBorder(),
                    helperText: 'Selecione a empresa prestadora a que este colaborador pertence',
                  ),
                  items: empreiteirosOuSubs.isEmpty
                      ? [const DropdownMenuItem(value: null, child: Text('Nenhum Empreiteiro cadastrado em Suprimentos'))]
                      : empreiteirosOuSubs.map<DropdownMenuItem<String>>((f) {
                          final tipo = f['tipoFornecedor'] ?? 'EMPREITEIRO';
                          final labelTipo = tipo == 'SUBCONTRATADO' ? 'Subcontratado' : 'Empreiteiro Principal';
                          return DropdownMenuItem<String>(
                            value: f['id'] as String,
                            child: Text('${f['nomeRazao'] ?? f['nome']} ($labelTipo)'),
                          );
                        }).toList(),
                  onChanged: isLoading
                      ? null
                      : (val) => setState(() => _selectedFornecedorId = val),
                  validator: (val) {
                    if (_tipoColaborador == 'TERCEIRIZADO' && (val == null || val.isEmpty)) {
                      return 'Selecione o empreiteiro responsável';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome Completo *', border: OutlineInputBorder()),
                validator: (val) => (val == null || val.isEmpty) ? 'Obrigatório' : null,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cargoController,
                      decoration: const InputDecoration(labelText: 'Cargo (Ex: Pedreiro)', border: OutlineInputBorder()),
                      enabled: !isLoading,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _salarioController,
                      decoration: const InputDecoration(labelText: 'Salário / Diária Base', border: OutlineInputBorder(), prefixText: 'R\$ '),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      enabled: !isLoading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Recebe Auxílio Motorista?'),
                subtitle: const Text('Será somado na diária quando houver viagem'),
                value: _isMotorista,
                onChanged: isLoading ? null : (val) {
                  setState(() => _isMotorista = val);
                },
              ),
              if (_isMotorista) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _diariaMotoristaController,
                  decoration: const InputDecoration(labelText: 'Valor Auxílio Motorista (Diário)', border: OutlineInputBorder(), prefixText: 'R\$ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: !isLoading,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final data = {
                        'nome': _nomeController.text.trim(),
                        'cargo': _cargoController.text.trim(),
                        'salario': _salarioController.text.trim(),
                        'tipoColaborador': _tipoColaborador,
                        'fornecedorId': _tipoColaborador == 'TERCEIRIZADO' ? _selectedFornecedorId : null,
                        'valorDiariaMotorista': _isMotorista ? _diariaMotoristaController.text.trim() : null,
                      };

                      if (widget.funcionario != null) {
                        await ref.read(rhControllerProvider.notifier).saveFuncionario(
                          data,
                          id: widget.funcionario!['id'],
                        );
                      } else {
                        await ref.read(rhControllerProvider.notifier).saveFuncionario(
                          data,
                        );
                      }
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(widget.funcionario != null ? 'Funcionário atualizado com sucesso!' : 'Funcionário cadastrado com sucesso!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: ${e.toString()}'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.all(16),
                ),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.funcionario != null ? 'Salvar Alterações' : 'Cadastrar Funcionário'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
