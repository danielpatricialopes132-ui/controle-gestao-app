import 'package:flutter/material.dart';

class AntesDepoisSliderDialog extends StatefulWidget {
  final String fotoAntesUrl;
  final String fotoDepoisUrl;
  final String ambiente;
  final String? descricao;

  const AntesDepoisSliderDialog({
    super.key,
    required this.fotoAntesUrl,
    required this.fotoDepoisUrl,
    required this.ambiente,
    this.descricao,
  });

  static Future<void> show(
    BuildContext context, {
    required String fotoAntesUrl,
    required String fotoDepoisUrl,
    required String ambiente,
    String? descricao,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AntesDepoisSliderDialog(
        fotoAntesUrl: fotoAntesUrl,
        fotoDepoisUrl: fotoDepoisUrl,
        ambiente: ambiente,
        descricao: descricao,
      ),
    );
  }

  @override
  State<AntesDepoisSliderDialog> createState() => _AntesDepoisSliderDialogState();
}

class _AntesDepoisSliderDialogState extends State<AntesDepoisSliderDialog> {
  double _sliderPosition = 0.5; // 0.0 a 1.0 (50% no centro)
  bool _modoLadoALado = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header do Dialog
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade900.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo.shade400.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.compare, color: Colors.indigoAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COMPARAÇÃO ANTES & DEPOIS • ${widget.ambiente.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (widget.descricao != null && widget.descricao!.isNotEmpty)
                        Text(
                          widget.descricao!,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _modoLadoALado ? 'Modo Cortina Interativa' : 'Modo Lado a Lado',
                  icon: Icon(
                    _modoLadoALado ? Icons.splitscreen : Icons.view_column,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() => _modoLadoALado = !_modoLadoALado),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Área de Visualização Interativa
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _modoLadoALado ? _buildLadoALado() : _buildSliderInterativo(),
              ),
            ),
            const SizedBox(height: 14),

            // Footer com Dica e Controles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.touch_app, size: 16, color: Colors.amberAccent),
                    SizedBox(width: 6),
                    Text(
                      'Arraste a divisória para comparar a evolução do ambiente',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLadoALado() {
    return Row(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(widget.fotoAntesUrl),
              _buildBadge('ANTES DA MONTAGEM', Alignment.topLeft, Colors.black87),
            ],
          ),
        ),
        const VerticalDivider(width: 4, thickness: 4, color: Color(0xFF1E293B)),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(widget.fotoDepoisUrl),
              _buildBadge('DEPOIS DA MONTAGEM', Alignment.topRight, const Color(0xFF059669)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderInterativo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final splitX = width * _sliderPosition;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _sliderPosition = (details.localPosition.dx / width).clamp(0.02, 0.98);
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagem Fundo: DEPOIS (revelada à direita ou por baixo)
              _buildImage(widget.fotoDepoisUrl),
              _buildBadge('DEPOIS (ENTREGUE)', Alignment.topRight, const Color(0xFF059669)),

              // Imagem Sobreposta: ANTES (cortada na largura splitX)
              ClipRect(
                clipper: _HorizontalClipper(splitX),
                child: _buildImage(widget.fotoAntesUrl),
              ),
              _buildBadge('ANTES (INICIAL)', Alignment.topLeft, Colors.black87),

              // Divisor Vertical Móvel
              Positioned(
                left: splitX - 1.5,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: Colors.white,
                ),
              ),

              // Handle de Arraste Central
              Positioned(
                left: splitX - 18,
                top: height / 2 - 18,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.drag_indicator, size: 20, color: Color(0xFF0F172A)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderFallback(),
      );
    } else {
      return _buildPlaceholderFallback();
    }
  }

  Widget _buildPlaceholderFallback() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined, color: Colors.white30, size: 48),
            SizedBox(height: 8),
            Text('Foto em alta resolução arquivada', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Alignment alignment, Color bgColor) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _HorizontalClipper extends CustomClipper<Rect> {
  final double width;
  _HorizontalClipper(this.width);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, width, size.height);
  }

  @override
  bool shouldReclip(covariant _HorizontalClipper oldClipper) {
    return oldClipper.width != width;
  }
}
