import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EstoqueDetalheScreen extends StatefulWidget {
  final String estoqueId;
  final String estoqueNome;

  const EstoqueDetalheScreen({
    super.key,
    required this.estoqueId,
    required this.estoqueNome,
  });

  @override
  State<EstoqueDetalheScreen> createState() => _EstoqueDetalheScreenState();
}

class _EstoqueDetalheScreenState extends State<EstoqueDetalheScreen> {
  bool isLoading = true;
  List<dynamic> itens = [];

  @override
  void initState() {
    super.initState();
    fetchItens();
  }

  Future<void> fetchItens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final url = Uri.parse('http://localhost:3000/api/suprimentos/estoques/${widget.estoqueId}/itens');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          itens = data['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Erro ao carregar itens: ${response.body}');
      }
    } catch (e) {
      setState(() { isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> showBaixaDialog(dynamic item) async {
    final qtdCtrl = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Dar Baixa: ${item['produto']['nome']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Saldo Atual: ${item['quantidade']} ${item['produto']['unidadeMedida']}'),
              const SizedBox(height: 16),
              TextField(
                controller: qtdCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Quantidade a retirar',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final qtdStr = qtdCtrl.text.replaceAll(',', '.');
                final qtdNum = double.tryParse(qtdStr);
                
                if (qtdNum == null || qtdNum <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantidade inválida')));
                  return;
                }
                
                if (qtdNum > double.parse(item['quantidade'].toString())) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saldo insuficiente')));
                  return;
                }
                
                Navigator.pop(context);
                await registrarBaixa(item['produtoId'], qtdNum);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      }
    );
  }

  Future<void> registrarBaixa(String produtoId, double quantidade) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final url = Uri.parse('http://localhost:3000/api/suprimentos/estoques/${widget.estoqueId}/itens');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'produtoId': produtoId,
          'quantidade': quantidade,
          'tipo': 'SAIDA'
        })
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Baixa registrada com sucesso!')));
        fetchItens();
      } else {
        throw Exception('Erro ao dar baixa: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.estoqueNome),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : itens.isEmpty
          ? const Center(child: Text('Este estoque está vazio. Quando uma Ordem de Compra for entregue, os materiais aparecerão aqui.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: itens.length,
              itemBuilder: (context, index) {
                final item = itens[index];
                final produto = item['produto'];
                final qtd = double.parse(item['quantidade'].toString());
                
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: qtd > 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      child: Icon(Icons.category, color: qtd > 0 ? Colors.green : Colors.red),
                    ),
                    title: Text(produto['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Saldo: $qtd ${produto['unidadeMedida']}'),
                    trailing: ElevatedButton(
                      onPressed: qtd > 0 ? () => showBaixaDialog(item) : null,
                      child: const Text('Baixa'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
