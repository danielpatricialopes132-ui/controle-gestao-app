import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../obras/presentation/bim_viewer_aba.dart';
import '../../../obras/presentation/vistoria_360_aba.dart';

class PortalClienteScreen extends ConsumerStatefulWidget {
  const PortalClienteScreen({super.key});

  @override
  ConsumerState<PortalClienteScreen> createState() => _PortalClienteScreenState();
}

class _PortalClienteScreenState extends ConsumerState<PortalClienteScreen> {
  // Mock data for the client's current project.
  // In a real scenario, this would come from a provider fetching the `Obra` by the client's ID.
  final String _obraIdMock = '123-abc';
  final double _progressoGeral = 0.65; // 65%

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider);
    final userName = user?['nome'] ?? 'Cliente';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal do Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Sair',
            onPressed: _logout,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Olá, $userName!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Acompanhe o andamento da sua obra em tempo real.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
            // Progresso Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Residencial Alphaville - Lote 12', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Progresso Físico'),
                        Text('${(_progressoGeral * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _progressoGeral,
                      backgroundColor: Colors.blue.shade100,
                      color: Colors.blue,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Ferramentas 3D e Vistorias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Actions Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  'BIM Viewer 3D',
                  Icons.view_in_ar,
                  Colors.teal,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Projeto 3D')), body: BimViewerAba(obraId: _obraIdMock)))),
                ),
                _buildActionCard(
                  context,
                  'Vistoria 360°',
                  Icons.threesixty,
                  Colors.indigo,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Vistoria Virtual')), body: Vistoria360Aba(obraId: _obraIdMock)))),
                ),
                _buildActionCard(
                  context,
                  'Revista da Obra',
                  Icons.picture_as_pdf,
                  Colors.red,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revista em PDF não disponível no momento.')));
                  },
                ),
                _buildActionCard(
                  context,
                  'Galeria de Fotos',
                  Icons.photo_library,
                  Colors.orange,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Galeria de fotos não disponível no momento.')));
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
