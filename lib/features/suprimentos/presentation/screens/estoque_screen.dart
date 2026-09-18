import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'estoque_detalhe_screen.dart';

class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  bool isLoading = true;
  List<dynamic> estoques = [];

  @override
  void initState() {
    super.initState();
    fetchEstoques();
  }

  Future<void> fetchEstoques() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      // Ajuste a URL do backend se necessário
      final url = Uri.parse('http://localhost:3000/api/suprimentos/estoques');
      
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
          estoques = data['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Erro ao carregar estoques: ${response.body}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque Local (Obras)'),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : estoques.isEmpty
          ? const Center(child: Text('Nenhum estoque/almoxarifado encontrado. Crie uma Obra para começar.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: estoques.length,
              itemBuilder: (context, index) {
                final est = estoques[index];
                final qteItens = est['_count']?['itens'] ?? 0;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.store, color: Colors.white),
                    ),
                    title: Text(est['nome'] ?? 'Estoque Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Obra vinculada: ${est['obra'] != null ? est['obra']['nome'] : 'Nenhuma'}'),
                    trailing: Chip(
                      label: Text('$qteItens produtos'),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EstoqueDetalheScreen(
                            estoqueId: est['id'],
                            estoqueNome: est['nome'],
                          )
                        ),
                      ).then((_) => fetchEstoques());
                    },
                  ),
                );
              },
            ),
    );
  }
}
