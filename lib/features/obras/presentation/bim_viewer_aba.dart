import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class BimViewerAba extends StatefulWidget {
  final String obraId;

  const BimViewerAba({super.key, required this.obraId});

  @override
  State<BimViewerAba> createState() => _BimViewerAbaState();
}

class _BimViewerAbaState extends State<BimViewerAba> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // A URL será apontada para o backend público rodando o HTML do ifc.js
    // Idealmente deve ser a URL do servidor de produção ou ngrok local
    final String viewerUrl = 'http://10.0.2.2:3000/bim-viewer.html';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(viewerUrl));
  }

  Future<void> _abrirLinkIfcBuilder() async {
    final Uri url = Uri.parse('https://info.cype.com/br/software/ifc-builder/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link do IFC Builder')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Arraste para rotacionar. Use o scroll para zoom.',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              TextButton.icon(
                onPressed: _abrirLinkIfcBuilder,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Baixar IFC Builder'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: WebViewWidget(controller: _controller),
        ),
      ],
    );
  }
}

