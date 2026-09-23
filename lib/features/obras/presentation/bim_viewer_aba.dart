import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Arraste para rotacionar. Use o scroll para zoom.',
                  style: TextStyle(color: Colors.blue),
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
