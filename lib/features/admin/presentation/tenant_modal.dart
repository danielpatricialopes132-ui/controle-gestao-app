import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/providers/api_client_provider.dart';

class TenantModal extends ConsumerStatefulWidget {
  final Map<String, dynamic>? tenant;
  final VoidCallback? onSuccess;

  const TenantModal({super.key, this.tenant, this.onSuccess});

  @override
  ConsumerState<TenantModal> createState() => _TenantModalState();

  static void show(BuildContext context, {Map<String, dynamic>? tenant, VoidCallback? onSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: TenantModal(tenant: tenant, onSuccess: onSuccess),
      ),
    );
  }
}

class _TenantModalState extends ConsumerState<TenantModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _documentoController;
  
  String? _logoUrl;
  bool _isUploadingLogo = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.tenant?['nome'] ?? '');
    _documentoController = TextEditingController(text: widget.tenant?['documento'] ?? '');
    _logoUrl = widget.tenant?['logoUrl'];
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _documentoController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() => _isUploadingLogo = true);

      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = picked.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

      final api = ref.read(apiClientProvider);
      final res = await api.post('/tenants/upload-logo', {
        'base64': base64String,
        'mimeType': mimeType,
        'fileName': picked.name,
        'tenantId': widget.tenant?['id'],
      });

      if (res['url'] != null) {
        setState(() {
          _logoUrl = res['url'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logotipo carregado com sucesso!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar imagem: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      final isEditing = widget.tenant != null;

      if (isEditing) {
        await api.put('/tenants/${widget.tenant!['id']}', {
          'nome': _nomeController.text.trim(),
          'documento': _documentoController.text.trim(),
          'logoUrl': _logoUrl,
        });
      } else {
        await api.post('/tenants', {
          'nome': _nomeController.text.trim(),
          'documento': _documentoController.text.trim(),
          'logoUrl': _logoUrl,
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Empresa atualizada com sucesso!'
                  : 'Empresa cadastrada e categorias padrão geradas!',
            ),
          ),
        );
      }

      widget.onSuccess?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar empresa: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildLogoPreview() {
    if (_isUploadingLogo) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_logoUrl != null && _logoUrl!.isNotEmpty) {
      if (_logoUrl!.startsWith('data:')) {
        try {
          final clean = _logoUrl!.split(',').last;
          return ClipOval(
            child: Image.memory(
              base64Decode(clean),
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          );
        } catch (_) {}
      } else {
        return ClipOval(
          child: Image.network(
            _logoUrl!,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, size: 40, color: Colors.indigo),
          ),
        );
      }
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, color: Colors.indigo, size: 30),
        SizedBox(height: 4),
        Text('Logo', style: TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tenant != null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Editar Empresa' : 'Cadastrar Nova Empresa (Tenant)',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 16),
              
              // Área de Upload de Logo
              Center(
                child: GestureDetector(
                  onTap: _isUploadingLogo ? null : _pickAndUploadLogo,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.indigo.shade50,
                        child: _buildLogoPreview(),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.indigo,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 14),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Razão Social / Nome Fantasia',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _documentoController,
                decoration: const InputDecoration(
                  labelText: 'CNPJ / CPF',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Obrigatório' : null,
              ),
              
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvar,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? 'Salvando...'
                      : (isEditing ? 'Salvar Alterações' : 'Cadastrar e Gerar Plano de Contas'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
