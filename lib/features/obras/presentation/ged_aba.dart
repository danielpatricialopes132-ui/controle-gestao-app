import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../providers/obra_ged_provider.dart';

class GedAba extends ConsumerStatefulWidget {
  final String obraId;
  const GedAba({super.key, required this.obraId});

  @override
  ConsumerState<GedAba> createState() => _GedAbaState();
}

class _GedAbaState extends ConsumerState<GedAba> {
  bool _uploading = false;

  void _uploadDocumento() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() => _uploading = true);
      try {
        final file = result.files.single;
        List<int> fileBytes = file.bytes!;
        
        String mimeType = 'application/pdf';
        if (file.extension == 'png') mimeType = 'image/png';
        if (file.extension == 'jpg' || file.extension == 'jpeg') mimeType = 'image/jpeg';

        // Compressão de imagem
        if (mimeType.contains('image')) {
          final compressedBytes = await FlutterImageCompress.compressWithList(
            file.bytes!,
            minWidth: 1024,
            minHeight: 1024,
            quality: 70,
            format: mimeType == 'image/png' ? CompressFormat.png : CompressFormat.jpeg,
          );
          if (compressedBytes != null) {
            fileBytes = compressedBytes;
          }
        }

        final base64File = base64Encode(fileBytes);
        
        String tipo = 'OUTROS';
        if (mimeType.contains('image')) tipo = 'FOTO';
        else if (file.name.toLowerCase().contains('planta')) tipo = 'PLANTA';
        else if (file.name.toLowerCase().contains('art')) tipo = 'ART';
        else if (file.name.toLowerCase().contains('contrato')) tipo = 'CONTRATO';

        await ref.read(obraGedControllerProvider.notifier).uploadDocumento(
          widget.obraId,
          file.name,
          tipo,
          base64File,
          mimeType,
        );
        
        ref.invalidate(documentosObraProvider(widget.obraId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload realizado com sucesso!')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no upload: $e')));
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentosObraProvider(widget.obraId));

    return Scaffold(
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro: $e')),
        data: (docs) {
          if (docs.isEmpty) {
            return const Center(child: Text('Nenhum documento encontrado para esta obra.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              IconData icon = Icons.insert_drive_file;
              if (doc['tipo'] == 'PLANTA') icon = Icons.architecture;
              if (doc['tipo'] == 'CONTRATO') icon = Icons.description;
              if (doc['tipo'] == 'ART') icon = Icons.engineering;
              if (doc['tipo'] == 'FOTO') icon = Icons.photo;

              return Card(
                child: ListTile(
                  leading: Icon(icon, color: Colors.blueAccent),
                  title: Text(doc['nome']),
                  subtitle: Text('Tipo: ${doc['tipo']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      launchUrl(Uri.parse(doc['url']));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _uploadDocumento,
        label: _uploading ? const Text('Enviando...') : const Text('Novo Documento'),
        icon: _uploading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.upload_file),
      ),
    );
  }
}
