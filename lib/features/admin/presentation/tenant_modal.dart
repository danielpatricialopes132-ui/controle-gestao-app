import 'package:flutter/material.dart';

class TenantModal extends StatefulWidget {
  const TenantModal({super.key});

  @override
  State<TenantModal> createState() => _TenantModalState();

  static void show(BuildContext context) {
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
        child: const TenantModal(),
      ),
    );
  }
}

class _TenantModalState extends State<TenantModal> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _documentoController = TextEditingController();
  
  // TODO: Implementar ImagePicker para subir para o Firebase Storage
  String? _logoUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cadastrar Nova Empresa (Tenant)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 16),
            
            // Área de Upload de Logo (Simulado)
            Center(
              child: GestureDetector(
                onTap: () {
                  // TODO: Acionar ImagePicker e Firebase Storage
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Abrindo galeria para upload do Firebase Storage...')),
                  );
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.indigo.shade50,
                  child: _logoUrl == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file, color: Colors.indigo),
                            Text('Logo', style: TextStyle(fontSize: 12, color: Colors.indigo)),
                          ],
                        )
                      : const Icon(Icons.check, color: Colors.green),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Razão Social / Nome Fantasia',
                border: OutlineInputBorder(),
              ),
              validator: (val) => (val == null || val.isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _documentoController,
              decoration: const InputDecoration(
                labelText: 'CNPJ / CPF',
                border: OutlineInputBorder(),
              ),
              validator: (val) => (val == null || val.isEmpty) ? 'Obrigatório' : null,
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // TODO: Enviar POST /api/tenants
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Empresa cadastrada! Plano de contas padrão gerado.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Salvar Empresa e Estruturar Banco'),
            ),
          ],
        ),
      ),
    );
  }
}
