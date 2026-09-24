import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../../../shared/providers/api_client_provider.dart';

class FvsScreen extends ConsumerStatefulWidget {
  const FvsScreen({super.key});

  @override
  ConsumerState<FvsScreen> createState() => _FvsScreenState();
}

class _FvsScreenState extends ConsumerState<FvsScreen> {
  final TextEditingController _servicoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? _imageBase64;
  String? _mimeType;
  bool _isAnalyzing = false;

  List<String> _conformidades = [];
  List<String> _naoConformidades = [];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 1200, imageQuality: 80);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBase64 = base64Encode(bytes);
          _mimeType = image.mimeType ?? 'image/jpeg';
          _conformidades.clear();
          _naoConformidades.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao capturar imagem: $e')));
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, tire uma foto ou selecione uma imagem primeiro.')));
      return;
    }
    if (_servicoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe a etapa ou serviço para análise.')));
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _conformidades.clear();
      _naoConformidades.clear();
    });

    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post('/ai/fvs-vision', {
        'imageBase64': _imageBase64,
        'mimeType': _mimeType,
        'servico': _servicoController.text.trim(),
      });

      if (res['success'] == true) {
        final analise = res['analise'];
        setState(() {
          _conformidades = List<String>.from(analise['conformidades'] ?? []);
          _naoConformidades = List<String>.from(analise['naoConformidades'] ?? []);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na análise da IA: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FVS com IA (Inspeção de Qualidade)'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tire uma foto do serviço concluído para que a IA (Gemini Vision) analise as conformidades de execução.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _servicoController,
              decoration: const InputDecoration(
                labelText: 'Qual serviço está sendo inspecionado? (ex: Alvenaria, Reboco)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.construction),
              ),
            ),
            const SizedBox(height: 24),
            
            if (_imageBase64 == null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Nenhuma foto selecionada', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(_imageBase64!),
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera),
                  label: const Text('Tirar Foto'),
                ),
                OutlinedButton.icon(
                  onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeria'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isAnalyzing 
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Analisando com Inteligência Artificial...'),
                      ],
                    )
                  : const Text('Analisar com IA (Gemini Vision)'),
            ),

            if (_conformidades.isNotEmpty || _naoConformidades.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const Text('Resultado da Análise (Ficha FVS)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              if (_conformidades.isNotEmpty) ...[
                const Text('✅ Conformidades', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                ..._conformidades.map((c) => ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(c),
                  dense: true,
                )),
                const SizedBox(height: 16),
              ],
              
              if (_naoConformidades.isNotEmpty) ...[
                const Text('⚠️ Não Conformidades (Atenção)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                ..._naoConformidades.map((c) => ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(c),
                  dense: true,
                )),
              ],
            ]
          ],
        ),
      ),
    );
  }
}
