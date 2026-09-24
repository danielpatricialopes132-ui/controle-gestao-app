import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

class Vistoria360Aba extends StatefulWidget {
  final String obraId;

  const Vistoria360Aba({super.key, required this.obraId});

  @override
  State<Vistoria360Aba> createState() => _Vistoria360AbaState();
}

class _Vistoria360AbaState extends State<Vistoria360Aba> {
  // Para fins de demonstração na Fase 8, carregamos uma imagem 360 estática.
  // Pode ser substituída pela API que lista vistorias e uma imagem real (Ex: Ricoh Theta).
  final String demo360Image = 'https://upload.wikimedia.org/wikipedia/commons/8/89/360_Degrees_view_of_Machu_Picchu_-_Peru.jpg'; 

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.indigo.shade50,
          child: Row(
            children: [
              const Icon(Icons.threed_rotation, color: Colors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: const Text(
                  'Arraste na tela para explorar a Vistoria 360º. Ou mova o celular se possuir giroscópio.',
                  style: TextStyle(color: Colors.indigo),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Ação para fazer upload de nova foto 360
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Upload de foto panorâmica em breve!')),
                  );
                },
                icon: const Icon(Icons.upload),
                label: const Text('Nova'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PanoramaViewer(
            sensorControl: SensorControl.orientation,
            child: Image.network(demo360Image),
          ),
        ),
      ],
    );
  }
}

