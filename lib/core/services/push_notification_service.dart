import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Solicitar permissão (necessário no iOS e Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('Permissão de notificação concedida');
      }

      // Pegar o token
      String? token;
      if (kIsWeb) {
        // Para web precisamos passar a vapidKey (gerada no console Firebase)
        // Se ainda não tivermos vapidKey, não vai gerar token
        try {
          token = await _firebaseMessaging.getToken();
        } catch (e) {
          if (kDebugMode) print('Erro ao gerar token Web FCM (vapidKey não configurada?): $e');
        }
      } else {
        token = await _firebaseMessaging.getToken();
      }

      if (token != null) {
        if (kDebugMode) print('FCM Token: $token');
        await _registerTokenOnBackend(token);
      }

      // Ouvir atualizações de token
      _firebaseMessaging.onTokenRefresh.listen(_registerTokenOnBackend);

      // Ouvir mensagens em foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Mensagem recebida em foreground: ${message.notification?.title}');
        }
        // TODO: Mostrar banner in-app se desejar
      });
    }
  }

  Future<void> _registerTokenOnBackend(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final idToken = await user.getIdToken();
      // Enviar token para a nossa API
      // Supondo a constante da url base (pode precisar buscar da config/environment)
      const baseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://controle-gestao-api.onrender.com');
      
      await http.post(
        Uri.parse('$baseUrl/api/users/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'token': token}),
      );
    } catch (e) {
      if (kDebugMode) print('Erro ao registrar FCM Token no backend: $e');
    }
  }
}
