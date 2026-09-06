import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// 单条聊天消息（仅用于前端展示，实际 AI 上下文由后端按用户隔离维护）
class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.content, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

/// AI 助手服务：通过后端代理调用智谱 GLM，API key 不暴露在前端
class AiService {
  String get _baseUrl => ApiService.baseUrl;

  String? _token;

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// 前端本地展示用的消息列表（后端另存真实上下文）
  final List<ChatMessage> _displayHistory = [];
  List<ChatMessage> get history => List.unmodifiable(_displayHistory);

  /// 发送消息，返回 AI 回复文本
  Future<String> sendMessage(String userContent) async {
    final trimmed = userContent.trim();
    _displayHistory.add(ChatMessage(role: 'user', content: trimmed));

    await _loadToken();
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/ai/chat'),
          headers: _headers,
          body: jsonEncode({'message': trimmed}),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'AI助手请求失败 (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    final reply = (data['reply'] ?? '').toString().trim();
    if (reply.isEmpty) throw Exception('AI返回了空回复');

    _displayHistory.add(ChatMessage(role: 'assistant', content: reply));
    return reply;
  }

  /// 清空对话（同时清后端上下文和前端展示）
  Future<void> clearHistory() async {
    _displayHistory.clear();
    try {
      await _loadToken();
      await http.post(
        Uri.parse('$_baseUrl/api/ai/clear'),
        headers: _headers,
      );
    } catch (_) {
      // 后端清空失败不影响前端
    }
  }
}
