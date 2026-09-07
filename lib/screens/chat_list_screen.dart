import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/game_provider.dart';
import 'chat_detail_screen.dart';
import 'ai_assistant_screen.dart';
import 'friends_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Conversation> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final convs = await context.read<GameProvider>().api.getConversations();
      if (mounted) setState(() { _conversations = convs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _lastMessagePreview(ChatMessage? msg) {
    if (msg == null) return '';
    switch (msg.type) {
      case 'voice': return '[语音]';
      case 'image': return '[图片]';
      case 'video': return '[视频]';
      default: return msg.content;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}-${dt.day}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GameProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('消息', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        color: const Color(0xFFe94560),
        child: ListView(
          children: [
            // AI助手入口
            _buildAIEntry(),
            const Divider(color: Colors.white10, height: 1),
            if (_loading)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (_conversations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: Text('还没有聊天，快去添加好友吧！', style: TextStyle(color: Colors.white38))),
              )
            else
              ..._conversations.map((c) => _buildConversationItem(c, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildAIEntry() {
    return ListTile(
      leading: Container(
        width: 48, height: 48,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFe94560), Color(0xFF9c27b0)]), shape: BoxShape.circle),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
      ),
      title: const Text('AI助手 · 灵仙', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: const Text('有什么修仙问题尽管问我', style: TextStyle(color: Colors.white38, fontSize: 13)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
    );
  }

  Widget _buildConversationItem(Conversation conv, GameProvider provider) {
    return ListTile(
      leading: _buildAvatar(conv.partner.avatar, provider),
      title: Text(conv.partner.nickname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(
        _lastMessagePreview(conv.lastMessage),
        style: const TextStyle(color: Colors.white38, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_formatTime(conv.lastMessage?.createdAt), style: const TextStyle(color: Colors.white24, fontSize: 11)),
          if (conv.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: const BoxDecoration(color: Color(0xFFe94560), shape: BoxShape.circle),
              child: Text('${conv.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ],
        ],
      ),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(partner: conv.partner)));
        _loadConversations();
      },
    );
  }

  Widget _buildAvatar(String? avatarUrl, GameProvider provider) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: provider.api.fullUrl(avatarUrl),
          width: 48, height: 48, fit: BoxFit.cover,
          placeholder: (_, __) => Container(width: 48, height: 48, color: Colors.deepPurple, child: const Icon(Icons.person, color: Colors.white)),
          errorWidget: (_, __, ___) => Container(width: 48, height: 48, color: Colors.deepPurple, child: const Icon(Icons.person, color: Colors.white)),
        ),
      );
    }
    return Container(width: 48, height: 48, decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white));
  }
}
