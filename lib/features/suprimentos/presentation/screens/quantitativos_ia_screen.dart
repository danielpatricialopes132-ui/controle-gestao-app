import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../shared/providers/api_client_provider.dart';

class QuantitativosIaScreen extends ConsumerStatefulWidget {
  const QuantitativosIaScreen({super.key});

  @override
  ConsumerState<QuantitativosIaScreen> createState() => _QuantitativosIaScreenState();
}

class _QuantitativosIaScreenState extends ConsumerState<QuantitativosIaScreen> {
  bool _isLoading = false;
  String? _selectedFileName;
  String? _resumoProjeto;
  List<Map<String, dynamic>> _itensExtraidos = [];
  final TextEditingController _observacoesController = TextEditingController();
  String _tipoProjeto = 'ESTRUTURAL_OU_GERAL';

  Future<void> _selecionarEAnalisarArquivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível ler os bytes do arquivo.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
        _selectedFileName = file.name;
        _itensExtraidos = [];
        _resumoProjeto = null;
      });

      final base64File = base64Encode(file.bytes!);
      final extension = file.extension?.toLowerCase() ?? 'pdf';
      final mimeType = extension == 'pdf'
          ? 'application/pdf'
          : (extension == 'png' ? 'image/png' : 'image/jpeg');

      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.post(
        '/ai/quantitativos',
        {
          'fileBase64': base64File,
          'mimeType': mimeType,
          'tipoProjeto': _tipoProjeto,
          'observacoes': _observacoesController.text.trim(),
        },
      );

      if (data['success'] == true) {
        final analise = data['data'] ?? {};
        final List<dynamic> itensBrutos = analise['itens'] ?? [];
        setState(() {
          _resumoProjeto = analise['resumoProjeto'] ?? 'Projeto processado com sucesso.';
          _itensExtraidos = itensBrutos.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro na análise: ${data['error'] ?? 'Falha desconhecida'}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao analisar projeto: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _enviarParaSuprimentos() {
    if (_itensExtraidos.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.inventory, color: Colors.teal),
            SizedBox(width: 8),
            Text('Exportar para Cotação'),
          ],
        ),
        content: Text(
          'Deseja exportar os ${_itensExtraidos.length} itens levantados pela IA para a esteira de cotações com fornecedores?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quantitativos encaminhados para a Central de Cotações com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Confirmar Exportação'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quantitativos com IA (Plantas & Projetos)'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.teal, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Engenheiro Orçamentista com IA',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Faça upload de pranchas em PDF ou imagens do projeto. A IA extrai e padroniza a lista de materiais em segundos (aço, cimento, agregados, etc).',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _tipoProjeto,
                            decoration: const InputDecoration(labelText: 'Disciplina do Projeto', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'ESTRUTURAL_OU_GERAL', child: Text('Estrutural / Concreto Armado')),
                              DropdownMenuItem(value: 'ARQUITETONICO', child: Text('Arquitetônico / Alvenaria')),
                              DropdownMenuItem(value: 'HIDROSSANITARIO', child: Text('Hidrossanitário')),
                              DropdownMenuItem(value: 'ELETRICO', child: Text('Elétrico / Cabeamento')),
                            ],
                            onChanged: (val) => setState(() => _tipoProjeto = val ?? 'ESTRUTURAL_OU_GERAL'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _observacoesController,
                      decoration: const InputDecoration(
                        labelText: 'Instruções Adicionais (Opcional)',
                        hintText: 'Ex: Focar na laje do 2º pavimento e vigas V1 a V5',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _selecionarEAnalisarArquivo,
                        icon: _isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.upload_file),
                        label: Text(_isLoading ? 'Processando Prancha com IA...' : 'Selecionar Prancha PDF / Imagem'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                      ),
                    ),
                    if (_selectedFileName != null) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Arquivo: $_selectedFileName',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_resumoProjeto != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.teal, size: 20),
                        SizedBox(width: 8),
                        Text('Resumo Técnico do Projeto:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(_resumoProjeto!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ],
                ),
              ),
            ],
            if (_itensExtraidos.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quantitativos Extraídos (${_itensExtraidos.length} insumos)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _enviarParaSuprimentos,
                    icon: const Icon(Icons.send_to_mobile, size: 18),
                    label: const Text('Enviar para Cotação'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _itensExtraidos.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final item = _itensExtraidos[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: Text('${index + 1}', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(item['nome'] ?? 'Insumo', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Categoria: ${item['categoria'] ?? 'GERAL'}\n${item['observacaoTecnica'] ?? ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '${item['quantidade']} ${item['unidade']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
