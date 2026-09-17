import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  List<dynamic> _usuarios = [];
  List<dynamic> _empresas = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final usersRes = await api.get('/admin/usuarios');
      final tenantsRes = await api.get('/tenants');
      
      setState(() {
        _usuarios = usersRes['data'] ?? [];
        _empresas = tenantsRes['data'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _aprovarUsuario(String userId, String tenantId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put('/admin/usuarios/$userId', {
        'status': 'ATIVO',
        'tenantId': tenantId,
        'role': 'USER'
      });
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _editarUsuario(dynamic u) async {
    final phoneController = TextEditingController(text: u['telefone']?.toString() ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar ${u['nome']}'),
        content: TextField(
          controller: phoneController,
          decoration: const InputDecoration(labelText: 'WhatsApp (Ex: 5511999999999)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                final api = ref.read(apiClientProvider);
                await api.put('/admin/usuarios/${u['id']}', {
                  'telefone': phoneController.text.trim(),
                });
                if (mounted) Navigator.pop(ctx);
                _loadData();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Aprovar Usuários', icon: Icon(Icons.person_add)),
              Tab(text: 'Empresas', icon: Icon(Icons.business)),
              Tab(text: 'WhatsApp', icon: Icon(Icons.chat)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUsuariosTab(),
                _buildEmpresasTab(),
                _buildWhatsAppTab(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUsuariosTab() {
    if (_usuarios.isEmpty) return const Center(child: Text('Nenhum usuário encontrado.'));

    return ListView.builder(
      itemCount: _usuarios.length,
      itemBuilder: (context, index) {
        final u = _usuarios[index];
        final isPendente = u['status'] == 'PENDENTE';
        String selectedTenant = _empresas.isNotEmpty ? _empresas.first['id'] : '';
        
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(u['nome'] ?? 'Sem Nome'),
            subtitle: Text('${u['email'] ?? 'Sem Email'} - Tel/WhatsApp: ${u['telefone'] ?? 'Não cadastrado'}'),
            trailing: isPendente ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedTenant.isNotEmpty ? selectedTenant : null,
                  items: _empresas.map((e) => DropdownMenuItem<String>(
                    value: e['id'],
                    child: Text(e['nome']),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      _aprovarUsuario(u['id'], val);
                    }
                  },
                  hint: const Text('Aprovar para...'),
                )
              ],
            ) : IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editarUsuario(u),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpresasTab() {
    return ListView.builder(
      itemCount: _empresas.length,
      itemBuilder: (context, index) {
        final e = _empresas[index];
        return ListTile(
          leading: const Icon(Icons.business),
          title: Text(e['nome']),
          subtitle: Text('Doc: ${e['documento']}'),
        );
      },
    );
  }

  Widget _buildWhatsAppTab() {
    return FutureBuilder(
      future: ref.read(apiClientProvider).get('/whatsapp/connect'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        
        final data = snapshot.data as Map<String, dynamic>?;
        if (data == null) return const Center(child: Text('Nenhum dado retornado'));

        if (data['state'] == 'open') {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 16),
                const Text('WhatsApp Conectado!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar Status'),
                  onPressed: () => setState(() {}),
                )
              ],
            ),
          );
        }

        final qrData = data['qrData'];
        final base64String = qrData?['base64'];

        if (base64String == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Status atual: ${data['state']} (QR não disponível)'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                  onPressed: () => setState(() {}),
                )
              ],
            )
          );
        }

        final cleanBase64 = base64String.contains(',') 
            ? base64String.split(',')[1] 
            : base64String;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Escaneie o QR Code para conectar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Image.memory(
                base64Decode(cleanBase64),
                width: 300,
                height: 300,
                errorBuilder: (c,e,s) => const Text('Erro ao renderizar QR Code'),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar QR Code'),
                onPressed: () => setState(() {}),
              )
            ],
          ),
        );
      }
    );
  }
}


