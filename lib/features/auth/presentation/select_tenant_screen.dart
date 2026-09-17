import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/tenant_provider.dart';
import '../../../shared/providers/api_client_provider.dart';

class SelectTenantScreen extends ConsumerStatefulWidget {
  const SelectTenantScreen({super.key});

  @override
  ConsumerState<SelectTenantScreen> createState() => _SelectTenantScreenState();
}

class _SelectTenantScreenState extends ConsumerState<SelectTenantScreen> {
  bool _isLoading = false;
  List<dynamic> _tenants = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/tenants');
      setState(() {
        _tenants = response['data'] ?? [];
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectTenant(String tenantId) {
    ref.read(tenantOverrideProvider.notifier).setTenant(tenantId);
    context.go('/dashboard');
  }

  void _goToAdmin() {
    ref.read(tenantOverrideProvider.notifier).setTenant(null); // Admin MASTER context
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Acesso'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erro: $_error', style: TextStyle(color: Colors.red)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.admin_panel_settings),
                        title: const Text('Painel ADM (Cadastro de Empresas)'),
                        subtitle: const Text('Acesso exclusivo MASTER'),
                        onTap: _goToAdmin,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Ou acesse como uma empresa cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    ..._tenants.map((tenant) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.business),
                          title: Text(tenant['nome'] ?? 'Empresa Sem Nome'),
                          subtitle: Text('CNPJ: ${tenant['documento'] ?? 'N/A'}'),
                          onTap: () => _selectTenant(tenant['id']),
                        ),
                      );
                    }).toList(),
                  ],
                ),
    );
  }
}


