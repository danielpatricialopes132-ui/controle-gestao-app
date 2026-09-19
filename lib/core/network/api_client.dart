import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart';

class ApiClient {
  // URL da API (Local em debug, Render em produção)
  static const String baseUrl = kReleaseMode 
      ? 'https://controle-gestao-api.onrender.com/api'
      : 'http://localhost:3000/api'; 
  final FirebaseAuth _auth;

  final String? tenantOverride;

  ApiClient(this._auth, {this.tenantOverride});

  Future<dynamic> get(String endpoint) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final token = await user.getIdToken();
    
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    if (tenantOverride != null) {
      headers['x-tenant-override'] = tenantOverride!;
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro na requisição: ${response.statusCode} - ${response.body}');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final token = await user.getIdToken();
    
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    if (tenantOverride != null) {
      headers['x-tenant-override'] = tenantOverride!;
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro na requisição: ${response.statusCode} - ${response.body}');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final token = await user.getIdToken();
    
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    if (tenantOverride != null) {
      headers['x-tenant-override'] = tenantOverride!;
    }
    
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro na requisição: ${response.statusCode} - ${response.body}');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final token = await user.getIdToken();
    
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    if (tenantOverride != null) {
      headers['x-tenant-override'] = tenantOverride!;
    }
    
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro na requisição: ${response.statusCode} - ${response.body}');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final token = await user.getIdToken();
    
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    if (tenantOverride != null) {
      headers['x-tenant-override'] = tenantOverride!;
    }
    
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      throw Exception('Erro na requisição: ${response.statusCode} - ${response.body}');
    }
  }
}
