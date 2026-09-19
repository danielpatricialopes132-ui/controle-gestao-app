import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/crm_provider.dart';
import '../../data/models/proposta.dart';

class NovaPropostaModal extends ConsumerStatefulWidget {
  const NovaPropostaModal({super.key});

  @override
  ConsumerState<NovaPropostaModal> createState() => _NovaPropostaModalState();
}

class _NovaPropostaModalState extends ConsumerState<NovaPropostaModal> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _validadeController = TextEditingController(text: '15');
  String? _clienteSelecionado;
  List<PropostaItem> _itens = [];
  bool _isScanning = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _validadeController.dispose();
    super.dispose();
  }

  double get _valorTotal => _itens.fold(0, (sum, item) => sum + item.valorTotal);

  Future<void> _scanOrcamento() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() => _isScanning = true);
        
        final bytes = result.files.single.bytes!;
        final base64Str = base64Encode(bytes);
        
        String mimeType = 'application/pdf';
        final ext = result.files.single.extension?.toLowerCase();
        if (ext == 'png') mimeType = 'image/png';
        if (ext == 'jpg' || ext == 'jpeg') mimeType = 'image/jpeg';

        final scanResult = await ref.read(crmProvider.notifier).scanProposta(base64Str, mimeType);
        
        if (mounted) {
          setState(() {
            _tituloController.text = scanResult['titulo'] ?? 'Orçamento Importado';
            _validadeController.text = (scanResult['validadeDias'] ?? 15).toString();
            
            if (scanResult['itens'] != null) {
              _itens.clear();
              for (var i in scanResult['itens']) {
                _itens.add(PropostaItem(
                  id: '',
                  descricao: i['descricao'] ?? 'Sem descrição',
                  quantidade: double.tryParse(i['quantidade'].toString()) ?? 1,
                  valorUnitario: double.tryParse(i['valorUnitario'].toString()) ?? 0,
                  valorTotal: double.tryParse(i['valorTotal'].toString()) ?? 0,
                ));
              }
            }
            _isScanning = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leitura concluída! Revise os dados.')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na IA: $e')));
      }
    }
  }

  void _salvar() async {
    if (!_formKey.currentState!.validate() || _clienteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os campos obrigatórios e selecione um cliente.')));
      return;
    }
    
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione pelo menos um item.')));
      return;
    }

    try {
      final proposta = Proposta(
        id: '',
        titulo: _tituloController.text,
        clienteId: _clienteSelecionado!,
        valorTotal: _valorTotal,
        validadeDias: int.tryParse(_validadeController.text) ?? 15,
        status: 'RASCUNHO',
        itens: _itens,
      );

      await ref.read(crmProvider.notifier).createProposta(proposta);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposta criada com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final crm = ref.watch(crmProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Proposta'),
        actions: [
          TextButton.icon(
            onPressed: _isScanning ? null : _scanOrcamento,
            icon: _isScanning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.document_scanner, color: Colors.white),
            label: const Text('Escanear (IA)', style: TextStyle(color: Colors.white)),
          ),
          IconButton(icon: const Icon(Icons.save), onPressed: _salvar),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder()),
                value: _clienteSelecionado,
                items: crm.clientes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList(),
                onChanged: (val) => setState(() => _clienteSelecionado = val),
                validator: (val) => val == null ? 'Selecione o cliente' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título da Proposta', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _validadeController,
                decoration: const InputDecoration(labelText: 'Validade (Dias)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Itens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Total: R\$ ${_valorTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _itens.length,
                  itemBuilder: (context, index) {
                    final item = _itens[index];
                    return ListTile(
                      title: Text(item.descricao),
                      subtitle: Text('${item.quantidade}x R\$ ${item.valorUnitario.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('R\$ ${item.valorTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => _itens.removeAt(index)),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
