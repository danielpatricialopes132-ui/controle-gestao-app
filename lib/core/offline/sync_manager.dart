import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../../shared/providers/api_client_provider.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final manager = SyncManager(apiClient);
  manager.init(); // Inicia o Hive box e listeners sem bloquear
  return manager;
});

/// Define um trabalho de sincronização que falhou por falta de internet.
class SyncJob {
  final String id;
  final String method;
  final String path;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  SyncJob({
    required this.id,
    required this.method,
    required this.path,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'method': method,
      'path': path,
      'data': jsonEncode(data),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncJob.fromMap(Map<String, dynamic> map) {
    return SyncJob(
      id: map['id'],
      method: map['method'],
      path: map['path'],
      data: jsonDecode(map['data']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class SyncManager {
  static const String _boxName = 'sync_queue';
  final ApiClient _apiClient;
  Box? _box;
  bool _isSyncing = false;

  SyncManager(this._apiClient);

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);

    // Escuta mudanças na conexão
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!results.contains(ConnectivityResult.none)) {
        _syncPendingJobs();
      }
    });

    // Tenta sincronizar ao iniciar (se houver rede)
    _syncPendingJobs();
  }

  /// Adiciona uma requisição na fila para ser tentada depois
  Future<void> enqueue(String method, String path, Map<String, dynamic> data) async {
    if (_box == null) return;
    
    final job = SyncJob(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: method,
      path: path,
      data: data,
      createdAt: DateTime.now(),
    );

    await _box!.put(job.id, job.toMap());
    print('SyncJob enfileirado: ${job.path}');
  }

  /// Tenta enviar todos os jobs parados na fila
  Future<void> _syncPendingJobs() async {
    if (_isSyncing || _box == null || _box!.isEmpty) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    _isSyncing = true;
    print('Iniciando sincronização offline... Jobs: ${_box!.length}');

    final keys = _box!.keys.toList();
    for (final key in keys) {
      final rawData = _box!.get(key);
      if (rawData == null) continue;

      final jobMap = Map<String, dynamic>.from(rawData);
      final job = SyncJob.fromMap(jobMap);

      try {
        if (job.method == 'POST') {
          await _apiClient.post(job.path, job.data);
        } else if (job.method == 'PUT') {
          await _apiClient.put(job.path, job.data);
        }
        
        // Se sucesso, remove da fila
        await _box!.delete(key);
        print('SyncJob sincronizado com sucesso: ${job.path}');
      } catch (e) {
        print('Erro ao sincronizar job ${job.path}: $e');
        // Se o erro não for de conexão, mas de backend (ex: 400 bad request), 
        // a depender da regra, deveríamos deletar ou manter.
        // No momento, manteremos para retentar.
      }
    }

    _isSyncing = false;
    print('Sincronização offline finalizada.');
  }
}
