import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/categorias_provider.dart';
import '../providers/financeiro_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

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
  
  String? _categoriaSelecionada;
  String? _obraSelecionada;
  String? _contaBancariaSelecionada;
  String? _comprovanteUrl;
  late DateTime _dataVencimento;

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
    _contaBancariaSelecionada = t?['contaBancariaId'];
    _comprovanteUrl = t?['comprovanteUrl'];
    _dataVencimento = t?['dataVencimento'] != null ? DateTime.parse(t!['dataVencimento']) : DateTime.now();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _codigoBarrasController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.transacaoExistente != null 
        ? (widget.isReceita ? 'Editar Receita' : 'Editar Despesa')
        : (widget.isReceita ? 'Nova Receita' : 'Nova Despesa');
    final color = widget.isReceita ? Colors.green : Colors.red;

    final asyncCategorias = ref.watch(categoriasProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
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
                              Text('• Receitas: Entradas financeiras na conta da empresa (ex: Pagamento de cliente, Aporte de capital).'),
                              SizedBox(height: 8),
                              Text('• Despesas: Saídas financeiras (ex: Compra de materiais, Conta de energia, Pagamento de salários).'),
                              SizedBox(height: 8),
                              Text('• Plano de Contas: Selecione a categoria que melhor descreve a transação para que seus relatórios (DRE) fiquem organizados.'),
                              SizedBox(height: 8),
                              Text('• Validação: Após lançada, a transação ficará PENDENTE até que alguém verifique e marque como PAGA na tela de Gestão Financeira.'),
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
              ),
              validator: (val) => (val == null || val.isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                border: OutlineInputBorder(),
              ),
              validator: (val) => (val == null || val.isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codigoBarrasController,
              decoration: const InputDecoration(
                labelText: 'Código de Barras / Pix (Opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacaoController,
              decoration: const InputDecoration(
                labelText: 'Observação / Histórico (Opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            asyncCategorias.when(
              data: (categorias) {
                final categoriasFiltradas = categorias.where((c) => c['tipo'] == (widget.isReceita ? 'RECEITA' : 'DESPESA')).toList();
                
                // Garantir que a categoria selecionada existe na lista filtrada (pode ocorrer problema se a categoria do backend não bater)
                if (_categoriaSelecionada != null && !categoriasFiltradas.any((c) => c['id'] == _categoriaSelecionada)) {
                  _categoriaSelecionada = null; // reseta se não existir
                }

                return DropdownButtonFormField<String>(
                  value: _categoriaSelecionada,
                  decoration: const InputDecoration(
                    labelText: 'Plano de Contas',
                    border: OutlineInputBorder(),
                  ),
                  items: categoriasFiltradas.map((c) => DropdownMenuItem<String>(
                    value: c['id'],
                    child: Text('${c['codigo']} - ${c['descricao']}'),
                  )).toList(),
                  onChanged: (val) {
                    setState(() => _categoriaSelecionada = val);
                  },
                  validator: (val) => val == null ? 'Selecione uma categoria' : null,
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => const Text('Erro ao carregar plano de contas'),
            ),
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
                      decoration: const InputDecoration(
                        labelText: 'Conta Bancária / Caixa',
                        border: OutlineInputBorder(),
                      ),
                      items: contas.map((c) => DropdownMenuItem<String>(
                        value: c['id'],
                        child: Text(c['nome']),
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
            // Data
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
            if (_comprovanteUrl != null) ...[
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.attachment, color: Colors.blue),
                title: const Text('Comprovante Anexado', style: TextStyle(color: Colors.blue)),
                onTap: () {
                  // Aqui futuramente podemos abrir a URL no navegador ou Modal
                },
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final data = {
                    'descricao': _descricaoController.text,
                    'valor': _valorController.text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim(),
                    'categoriaId': _categoriaSelecionada,
                    'obraId': _obraSelecionada,
                    'contaBancariaId': _contaBancariaSelecionada,
                    'dataVencimento': _dataVencimento.toIso8601String(),
                    'tipo': widget.isReceita ? 'RECEITA' : 'DESPESA',
                    'status': widget.transacaoExistente?['status'] ?? 'PENDENTE',
                    'codigoBarras': _codigoBarrasController.text.isNotEmpty ? _codigoBarrasController.text : null,
                    'observacao': _observacaoController.text.isNotEmpty ? _observacaoController.text : null,
                    'comprovanteUrl': _comprovanteUrl,
                  };

                  try {
                    if (widget.transacaoExistente != null) {
                      await ref.read(financeiroControllerProvider.notifier).updateTransacao(widget.transacaoExistente!['id'], data);
                    } else {
                      await ref.read(financeiroControllerProvider.notifier).addTransacao(data);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${widget.transacaoExistente != null ? 'Edição salva' : title + ' registrada'} com sucesso!')),
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
    );
  }
}
