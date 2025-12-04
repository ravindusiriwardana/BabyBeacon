import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class BabyMonitorService {
  static final BabyMonitorService _instance = BabyMonitorService._internal();

  factory BabyMonitorService() {
    return _instance;
  }

  BabyMonitorService._internal();

  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? onEmotionReceived;

  // ⚠️ FOR IOS SIMULATOR: Use 127.0.0.1
  // ⚠️ FOR ANDROID EMULATOR: Use 10.0.2.2
  // ⚠️ FOR PHYSICAL DEVICE: Use 192.168.1.xxx
  final String serverIp = "127.0.0.1"; 
  final int port = 8765;

  bool _isConnected = false;

  void connect({Function(Map<String, dynamic>)? callback}) {
    onEmotionReceived = callback;

    if (_isConnected) return;

    final uri = Uri.parse("ws://$serverIp:$port");

    try {
      debugPrint("🔌 Connecting to Baby Monitor Server at $uri...");
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _channel!.stream.listen(
        (data) {
          try {
            final String message = data.toString();
            debugPrint("📩 Received: $message");
            
            final json = jsonDecode(message) as Map<String, dynamic>;
            
            if (onEmotionReceived != null) {
              onEmotionReceived!(json);
            }
          } catch (e) {
            debugPrint("❌ Error parsing WebSocket data: $e");
          }
        },
        onDone: () {
          debugPrint("🔌 WebSocket Connection Closed");
          _isConnected = false;
          _reconnect();
        },
        onError: (error) {
          debugPrint("❌ WebSocket Error: $error");
          _isConnected = false;
          _reconnect();
        },
      );
    } catch (e) {
      debugPrint("❌ Connection Failed: $e");
      _isConnected = false;
      _reconnect();
    }
  }

  void _reconnect() {
    // Attempt to reconnect after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      debugPrint("🔄 Attempting to reconnect...");
      connect(callback: onEmotionReceived);
    });
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _isConnected = false;
      _channel = null;
    }
  }
}