import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/categorias_provider.dart';
import '../providers/financeiro_provider.dart';
import '../../obras/providers/obras_provider.dart';
import '../../obras/providers/obras_detalhe_provider.dart';
import '../../rh/providers/rh_provider.dart';
import '../../suprimentos/presentation/providers/suprimentos_provider.dart';

class TransacaoModal extends ConsumerStatefulWidget {
  final bool isReceita;
  final Map<String, dynamic>? transacaoExistente;

  const TransacaoModal({super.key, required this.isReceita, this.transacaoExistente});

  @override
  ConsumerState<TransacaoModal> createState() => _TransacaoModalState();

  static void show(BuildContext context, {required bool isReceita, Map<String, dynamic>? transacao}) {
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
        child: TransacaoModal(isReceita: isReceita, transacaoExistente: transacao),
      ),
    );
  }
}

class _TransacaoModalState extends ConsumerState<TransacaoModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descricaoController;
  late TextEditingController _valorController;
  late TextEditingController _codigoBarrasController;
  late TextEditingController _observacaoController;
  late TextEditingController _recebedorManualController;
  
  String? _categoriaSelecionada;
  String? _obraSelecionada;
  String? _adendoSelecionadoId;
  String? _contaBancariaSelecionada;
  String _statusSelecionado = 'PENDENTE';
  late DateTime _dataVencimento;

  // Vinculação de Recebedor / Beneficiário inteligente
  String? _funcionarioSelecionadoId;
  bool _recebedorDetectadoAuto = false;

  bool _isRateio = false;
  List<Map<String, dynamic>> _rateios = [];

  @override
  void initState() {
    super.initState();
    final t = widget.transacaoExistente;
    _descricaoController = TextEditingController(text: t?['descricao'] ?? '');
    _valorController = TextEditingController(text: t?['valor']?.toString() ?? '');
    _codigoBarrasController = TextEditingController(text: t?['codigoBarras'] ?? '');
    _observacaoController = TextEditingController(text: t?['observacao'] ?? '');
    _categoriaSelecionada = t?['categoriaId'];
    _obraSelecionada = t?['obraId'];
    _adendoSelecionadoId = t?['adendoId'];
    _contaBancariaSelecionada = t?['contaBancariaId'];
    _statusSelecionado = t?['status'] ?? 'PENDENTE';
    _dataVencimento = t?['dataVencimento'] != null ? DateTime.parse(t!['dataVencimento']) : DateTime.now();

    _funcionarioSelecionadoId = t?['funcionarioId'] ?? t?['funcionario']?['id'];
    _recebedorManualController = TextEditingController(text: t?['clienteFornecedor'] ?? '');

    final r = t?['rateios'];
    if (r != null && r is List && r.isNotEmpty) {
      _isRateio = true;
      _rateios = List<Map<String, dynamic>>.from(r.map((x) => {
        'obraId': x['obraId'],
        'categoriaId': x['categoriaId'],
        'valor': x['valor'].toString(),
        'percentual': x['percentual']?.toString(),
      }));
    }

    // Carregar fornecedores de suprimentos se necessário
    Future.microtask(() {
      try {
        ref.read(suprimentosProvider.notifier).fetchFornecedores();
      } catch (_) {}
    });

    _descricaoController.addListener(_onDescricaoChanged);
  }

  @override
  void dispose() {
    _descricaoController.removeListener(_onDescricaoChanged);
    _descricaoController.dispose();
    _valorController.dispose();
    _codigoBarrasController.dispose();
    _observacaoController.dispose();
    _recebedorManualController.dispose();
    super.dispose();
  }

  void _onDescricaoChanged() {
    final text = _descricaoController.text.trim().toLowerCase();
    if (text.isEmpty || _funcionarioSelecionadoId != null || _recebedorManualController.text.isNotEmpty) {
      return;
    }

    // Tentar correspondência automática com Funcionários
    final asyncFuncs = ref.read(funcionariosProvider);
    asyncFuncs.whenData((funcs) {
      for (final f in funcs) {
        final nome = (f['nome'] as String? ?? '').trim().toLowerCase();
        if (nome.isNotEmpty && text.contains(nome)) {
          setState(() {
            _funcionarioSelecionadoId = f['id'];
            _recebedorDetectadoAuto = true;
          });
          return;
        }
      }
    });

    // Tentar correspondência automática com Fornecedores
    final suprimentos = ref.read(suprimentosProvider);
    for (final fornecedor in suprimentos.fornecedores) {
      final nome = (fornecedor['nome'] as String? ?? '').trim().toLowerCase();
      if (nome.isNotEmpty && text.contains(nome)) {
        setState(() {
          _recebedorManualController.text = fornecedor['nome'] ?? '';
          _recebedorDetectadoAuto = true;
        });
        return;
      }
    }
  }

  bool _isContaExigeVinculacao(List<dynamic> categorias) {
    if (widget.isReceita) return false;
    final cat = categorias.firstWhere(
      (c) => c['id'] == _categoriaSelecionada,
      orElse: () => null,
    );
    if (cat == null) return false;
    final desc = (cat['descricao'] as String? ?? '').toLowerCase();
    return desc.contains('folha') ||
        desc.contains('pró-labore') ||
        desc.contains('pro-labore') ||
        desc.contains('prolabore') ||
        desc.contains('salário') ||
        desc.contains('salario') ||
        desc.contains('terceiro') ||
        desc.contains('fornecedor') ||
        desc.contains('empreiteiro') ||
        desc.contains('pessoal') ||
        desc.contains('escritório') ||
        desc.contains('escritorio');
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.transacaoExistente != null 
        ? (widget.isReceita ? 'Editar Receita' : 'Editar Despesa')
        : (widget.isReceita ? 'Nova Receita' : 'Nova Despesa');
    final color = widget.isReceita ? Colors.green : Colors.red;

    final asyncCategorias = ref.watch(categoriasProvider);
    final asyncFuncionarios = ref.watch(funcionariosProvider);
    final suprimentosState = ref.watch(suprimentosProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.blueAccent),
                    tooltip: 'Ajuda Rápida: Lançamentos',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: Colors.amber),
                              SizedBox(width: 8),
                              Text('Dicas Contábeis'),
                            ],
                          ),
                          content: const SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('• Receitas: Entradas financeiras na conta da empresa.'),
                                SizedBox(height: 8),
                                Text('• Despesas: Saídas de caixa / banco.'),
                                SizedBox(height: 8),
                                Text('• Beneficiário / Recebedor: Para pagamentos de Folha (Campo ou Escritório), Pró-Labore, Terceiros ou Fornecedores, vincule o recebedor para controle total de histórico e conciliação.'),
                                SizedBox(height: 8),
                                Text('• Validação: Após lançada, a transação ficará PENDENTE até que seja confirmada e paga na gestão financeira.'),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Entendi'),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição da Transação',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor Total (R\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ratear em múltiplos centros de custo?', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Dividir esta despesa entre várias obras/categorias'),
                value: _isRateio,
                activeColor: color,
                onChanged: (val) {
                  setState(() {
                    _isRateio = val;
                    if (val && _rateios.isEmpty) {
                      _rateios.add({'valor': ''});
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              if (!_isRateio) ...[
                asyncCategorias.when(
                  data: (categorias) {
                    final categoriasFiltradas = categorias.where((c) => c['tipo'] == (widget.isReceita ? 'RECEITA' : 'DESPESA')).toList();
                    
                    if (_categoriaSelecionada != null && !categoriasFiltradas.any((c) => c['id'] == _categoriaSelecionada)) {
                      _categoriaSelecionada = null;
                    }

                    final exigeVinculo = _isContaExigeVinculacao(categorias);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _categoriaSelecionada,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Plano de Contas',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_tree),
                          ),
                          items: categoriasFiltradas.map((c) => DropdownMenuItem<String>(
                            value: c['id'],
                            child: Text(
                              '${c['codigo']} - ${c['descricao']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )).toList(),
                          onChanged: (val) {
                            setState(() => _categoriaSelecionada = val);
                          },
                          validator: (val) => val == null ? 'Selecione uma categoria' : null,
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            final asyncObras = ref.watch(obrasProvider);
                            return asyncObras.when(
                              data: (obras) {
                                if (_obraSelecionada != null && !obras.any((o) => o['id'] == _obraSelecionada)) {
                                  _obraSelecionada = null;
                                }
                                return DropdownButtonFormField<String>(
                                  value: _obraSelecionada,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Obra (Opcional)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.apartment),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('Geral (Sem Obra / Escritório)'),
                                    ),
                                    ...obras.map((o) => DropdownMenuItem<String>(
                                      value: o['id'],
                                      child: Text(o['nome'], overflow: TextOverflow.ellipsis),
                                    )),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _obraSelecionada = val;
                                      _adendoSelecionadoId = null;
                                    });
                                  },
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (e, st) => const Text('Erro ao carregar obras'),
                            );
                          },
                        ),

                        // Seletor de Vínculo: Contrato Principal vs Adendos/Aditivos
                        if (_obraSelecionada != null) ...[
                          const SizedBox(height: 12),
                          Consumer(
                            builder: (context, ref, child) {
                              final asyncAdendos = ref.watch(obraAdendosProvider(_obraSelecionada!));
                              return asyncAdendos.when(
                                data: (data) {
                                  final List<dynamic> adendos = data['adendos'] ?? [];
                                  final contrato = data['contrato'];
                                  return DropdownButtonFormField<String>(
                                    value: _adendoSelecionadoId,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'Contrato / Aditivo Vinculado',
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(Icons.assignment_outlined, size: 20),
                                      helperText: widget.isReceita
                                          ? 'Vincule ao Contrato Principal ou a um Aditivo específico'
                                          : 'Centro de custo do contrato ou aditivo',
                                    ),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text(
                                          contrato != null ? 'Contrato Principal (${contrato['descricao'] ?? 'Padrão'})' : 'Contrato Principal da Obra',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      ...adendos.map<DropdownMenuItem<String>>((ad) {
                                        final numVal = ad['valor'] != null ? (num.tryParse(ad['valor'].toString()) ?? 0.0) : null;
                                        final valor = (numVal != null) ? ' - R\$ ${numVal.toStringAsFixed(2)}' : '';
                                        return DropdownMenuItem<String>(
                                          value: ad['id'],
                                          child: Text(
                                            'Aditivo: ${ad['descricao']}$valor',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _adendoSelecionadoId = val;
                                        if (val != null) {
                                          final ad = adendos.firstWhere((x) => x['id'] == val, orElse: () => null);
                                          if (ad != null && ad['descricao'] != null) {
                                            final descAd = (ad['descricao'] as String).trim();
                                            final descAtual = _descricaoController.text.trim();
                                            if (!descAtual.toLowerCase().contains(descAd.toLowerCase())) {
                                              if (descAtual.isEmpty || descAtual.toLowerCase() == 'recebimento' || descAtual.toLowerCase() == 'quitação') {
                                                _descricaoController.text = 'Recebimento Aditivo - $descAd';
                                              }
                                            }
                                          }
                                        }
                                      });
                                    },
                                  );
                                },
                                loading: () => const LinearProgressIndicator(),
                                error: (e, st) => const SizedBox(),
                              );
                            },
                          ),
                        ],

                        // Bloco Inteligente de Vinculação de Recebedor / Beneficiário
                        if (!widget.isReceita) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: exigeVinculo ? Colors.blue.withOpacity(0.06) : Colors.grey.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: exigeVinculo ? Colors.blue.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
                                width: exigeVinculo ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_pin_circle_outlined,
                                      color: exigeVinculo ? Colors.blue.shade700 : Colors.grey.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        exigeVinculo
                                            ? 'Vincular Recebedor (Folha / Pró-Labore / Fornecedor / Terceiro)'
                                            : 'Beneficiário / Recebedor (Opcional)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: exigeVinculo ? Colors.blue.shade900 : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (_recebedorDetectadoAuto)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.auto_awesome, size: 12, color: Colors.green),
                                            SizedBox(width: 4),
                                            Text(
                                              'Auto-detectado',
                                              style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                
                                // Seletor de Colaborador / Sócio (RH)
                                asyncFuncionarios.when(
                                  data: (funcs) {
                                    return DropdownButtonFormField<String>(
                                      value: funcs.any((f) => f['id'] == _funcionarioSelecionadoId) ? _funcionarioSelecionadoId : null,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Colaborador / Sócio (Folha / Pró-Labore)',
                                        hintText: 'Selecione o colaborador do RH',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                                      ),
                                      items: [
                                        const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('Nenhum colaborador / Outro recebedor'),
                                        ),
                                        ...funcs.map<DropdownMenuItem<String>>((f) {
                                          final nome = f['nome'] ?? 'Sem Nome';
                                          final cargo = f['cargo'] != null ? ' (${f['cargo']})' : '';
                                          return DropdownMenuItem<String>(
                                            value: f['id'],
                                            child: Text('$nome$cargo', overflow: TextOverflow.ellipsis),
                                          );
                                        }),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          _funcionarioSelecionadoId = val;
                                          _recebedorDetectadoAuto = false;
                                          if (val != null) {
                                            // Limpar recebedor manual se colaborador selecionado
                                            _recebedorManualController.clear();
                                          }
                                        });
                                      },
                                    );
                                  },
                                  loading: () => const LinearProgressIndicator(),
                                  error: (e, st) => const SizedBox(),
                                ),

                                const SizedBox(height: 10),

                                // Campo de Fornecedor / Terceiro / Outro
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _recebedorManualController,
                                        enabled: _funcionarioSelecionadoId == null,
                                        decoration: InputDecoration(
                                          labelText: 'Fornecedor / Terceiro / Empreiteiro',
                                          hintText: _funcionarioSelecionadoId != null
                                              ? 'Vinculado ao colaborador acima'
                                              : 'Nome ou razão social do recebedor',
                                          isDense: true,
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                                          suffixIcon: (suprimentosState.fornecedores.isNotEmpty && _funcionarioSelecionadoId == null)
                                              ? PopupMenuButton<String>(
                                                  icon: const Icon(Icons.arrow_drop_down),
                                                  tooltip: 'Selecionar de Fornecedores Cadastrados',
                                                  onSelected: (val) {
                                                    setState(() {
                                                      _recebedorManualController.text = val;
                                                      _recebedorDetectadoAuto = false;
                                                    });
                                                  },
                                                  itemBuilder: (context) {
                                                    return suprimentosState.fornecedores.map<PopupMenuItem<String>>((forn) {
                                                      return PopupMenuItem<String>(
                                                        value: forn['nome'] ?? '',
                                                        child: Text(forn['nome'] ?? ''),
                                                      );
                                                    }).toList();
                                                  },
                                                )
                                              : null,
                                        ),
                                        onChanged: (_) {
                                          if (_recebedorDetectadoAuto) {
                                            setState(() => _recebedorDetectadoAuto = false);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, st) => const Text('Erro ao carregar plano de contas'),
                ),
              ] else ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ..._rateios.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final rateio = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: rateio['valor'],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Valor',
                                    isDense: true,
                                  ),
                                  onChanged: (val) => rateio['valor'] = val,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final asyncObras = ref.watch(obrasProvider);
                                    return asyncObras.when(
                                      data: (obras) {
                                        return DropdownButtonFormField<String>(
                                          value: rateio['obraId'],
                                          decoration: const InputDecoration(labelText: 'Obra', isDense: true),
                                          items: [
                                            const DropdownMenuItem<String>(value: null, child: Text('Sem Obra', overflow: TextOverflow.ellipsis)),
                                            ...obras.map((o) => DropdownMenuItem<String>(
                                              value: o['id'],
                                              child: Text(o['nome'], overflow: TextOverflow.ellipsis),
                                            )),
                                          ],
                                          onChanged: (val) => setState(() => rateio['obraId'] = val),
                                        );
                                      },
                                      loading: () => const SizedBox(),
                                      error: (e, st) => const SizedBox(),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: asyncCategorias.when(
                                  data: (categorias) {
                                    final categoriasFiltradas = categorias.where((c) => c['tipo'] == (widget.isReceita ? 'RECEITA' : 'DESPESA')).toList();
                                    return DropdownButtonFormField<String>(
                                      value: rateio['categoriaId'],
                                      decoration: const InputDecoration(labelText: 'Categoria', isDense: true),
                                      items: categoriasFiltradas.map((c) => DropdownMenuItem<String>(
                                        value: c['id'],
                                        child: Text(c['descricao'], overflow: TextOverflow.ellipsis),
                                      )).toList(),
                                      onChanged: (val) => setState(() => rateio['categoriaId'] = val),
                                    );
                                  },
                                  loading: () => const CircularProgressIndicator(),
                                  error: (e, st) => const Text('Erro'),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _rateios.removeAt(idx);
                                  });
                                },
                              )
                            ],
                          ),
                        );
                      }).toList(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _rateios.add({'valor': ''});
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Fração do Rateio'),
                      )
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final asyncContas = ref.watch(contasBancariasProvider);
                  return asyncContas.when(
                    data: (contas) {
                      if (_contaBancariaSelecionada != null && !contas.any((c) => c['id'] == _contaBancariaSelecionada)) {
                        _contaBancariaSelecionada = null;
                      }
                      return DropdownButtonFormField<String>(
                        value: _contaBancariaSelecionada,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Conta Bancária / Caixa',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                        items: contas.map((c) => DropdownMenuItem<String>(
                          value: c['id'],
                          child: Text(c['nome'], overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (val) {
                          setState(() => _contaBancariaSelecionada = val);
                        },
                        validator: (val) => val == null ? 'Selecione uma conta bancária' : null,
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, st) => const Text('Erro ao carregar contas'),
                  );
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data de Vencimento/Pagamento'),
                subtitle: Text('${_dataVencimento.day}/${_dataVencimento.month}/${_dataVencimento.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dataVencimento,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _dataVencimento = date);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _statusSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Status do Lançamento',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'PAGO',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text('PAGO / LIQUIDADO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'PENDENTE',
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.amber, size: 18),
                        SizedBox(width: 8),
                        Text('PENDENTE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'A_CONFIRMAR',
                    child: Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.deepPurple, size: 18),
                        SizedBox(width: 8),
                        Text('A CONFIRMAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _statusSelecionado = val);
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String descricaoFinal = _descricaoController.text.trim();

                    // Se houver colaborador vinculado e o nome não estiver na descrição, enriquecer
                    if (_funcionarioSelecionadoId != null) {
                      final asyncFuncs = ref.read(funcionariosProvider);
                      asyncFuncs.whenData((funcs) {
                        final f = funcs.firstWhere((x) => x['id'] == _funcionarioSelecionadoId, orElse: () => null);
                        if (f != null && f['nome'] != null) {
                          final nome = (f['nome'] as String).trim();
                          if (!descricaoFinal.toLowerCase().contains(nome.toLowerCase())) {
                            if (descricaoFinal.isEmpty || descricaoFinal.toLowerCase() == 'salário' || descricaoFinal.toLowerCase() == 'salario' || descricaoFinal.toLowerCase() == 'folha de pagamento') {
                              descricaoFinal = 'Pagamento Salário - $nome';
                            } else if (descricaoFinal.toLowerCase().contains('pró-labore') || descricaoFinal.toLowerCase().contains('pro-labore')) {
                              descricaoFinal = 'Pró-Labore - $nome';
                            } else {
                              descricaoFinal = '$descricaoFinal - $nome';
                            }
                          }
                        }
                      });
                    } else if (_recebedorManualController.text.trim().isNotEmpty) {
                      final nomeRecebedor = _recebedorManualController.text.trim();
                      if (!descricaoFinal.toLowerCase().contains(nomeRecebedor.toLowerCase())) {
                        descricaoFinal = '$descricaoFinal - $nomeRecebedor';
                      }
                    }

                    final data = {
                      'descricao': descricaoFinal,
                      'valor': _valorController.text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim(),
                      'categoriaId': _isRateio ? null : _categoriaSelecionada,
                      'planoContaId': _isRateio ? null : _categoriaSelecionada,
                      'obraId': _isRateio ? null : _obraSelecionada,
                      'adendoId': _isRateio ? null : _adendoSelecionadoId,
                      'contaBancariaId': _contaBancariaSelecionada,
                      'dataVencimento': _dataVencimento.toIso8601String(),
                      'tipo': widget.isReceita ? 'RECEITA' : 'DESPESA',
                      'status': _statusSelecionado,
                      'rateios': _isRateio ? _rateios : [],
                      'funcionarioId': _funcionarioSelecionadoId,
                      'clienteFornecedor': _recebedorManualController.text.trim().isNotEmpty
                          ? _recebedorManualController.text.trim()
                          : null,
                    };

                    try {
                      if (widget.transacaoExistente != null) {
                        await ref.read(financeiroControllerProvider.notifier).updateTransacao(widget.transacaoExistente!['id'], data);
                      } else {
                        await ref.read(financeiroControllerProvider.notifier).addTransacao(data);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        final msgSucesso = widget.transacaoExistente != null ? 'Edição salva com sucesso!' : '$title registrada com sucesso!';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msgSucesso)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.transacaoExistente != null ? 'Salvar Edição' : 'Salvar ${widget.isReceita ? 'Receita' : 'Despesa'}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
