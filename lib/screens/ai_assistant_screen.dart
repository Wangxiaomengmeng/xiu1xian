import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> with TickerProviderStateMixin {
  final AiService _aiService = AiService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late final AnimationController _typingCtrl;
  bool _loading = false;

  // 预设的快捷问题
  static const List<String> _quickQuestions = [
    '怎么快速提升修为？',
    '突破境界有什么技巧？',
    '炼丹材料怎么获得？',
    '各境界需要多少修为？',
  ];

  @override
  void initState() {
    super.initState();
    _typingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _typingCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? text]) async {
    final content = (text ?? _inputCtrl.text).trim();
    if (content.isEmpty || _loading) return;

    setState(() {
      _inputCtrl.clear();
      _loading = true;
    });
    _scrollToBottom();

    try {
      await _aiService.sendMessage(content);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI助手暂时无法回复: $e')),
        );
      }
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('清空对话', style: TextStyle(color: Colors.white)),
        content: const Text('确定要清空当前对话记录吗？', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _aiService.clearHistory();
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = _aiService.history;

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.auto_awesome, color: Color(0xFFe94560), size: 20),
            SizedBox(width: 8),
            Text('AI助手 · 灵仙', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
            tooltip: '清空对话',
            onPressed: _clearConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          // 对话区域
          Expanded(
            child: history.isEmpty
                ? _buildWelcome()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == history.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(history[i]);
                    },
                  ),
          ),
          // 快捷问题（仅在无对话时显示）
          if (history.isEmpty) _buildQuickQuestions(),
          // 输入区域
          _buildInputBar(),
        ],
      ),
    );
  }

  /// 欢迎页
  Widget _buildWelcome() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [Color(0xFFe94560), Color(0xFF1a1a2e)],
                radius: 0.7,
              ),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            '我是灵仙，你的修仙引路人',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '有任何关于修仙录的问题，尽管问我',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// 快捷问题按钮
  Widget _buildQuickQuestions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _quickQuestions.map((q) {
          return GestureDetector(
            onTap: () => _sendMessage(q),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFe94560).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFe94560).withOpacity(0.4)),
              ),
              child: Text(q, style: const TextStyle(color: Color(0xFFe94560), fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 单条消息气泡
  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFe94560),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFe94560) : const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: isUser ? const Radius.circular(14) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(14),
                ),
                border: isUser ? null : Border.all(color: Colors.white12),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  /// AI 正在输入的指示器
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFe94560),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(1),
                const SizedBox(width: 4),
                _dot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delay) {
    return AnimatedBuilder(
      animation: _typingCtrl,
      builder: (context, child) {
        final phase = (_typingCtrl.value + delay * 0.2) % 1.0;
        final opacity = 0.3 + 0.7 * ((phase < 0.5) ? phase * 2 : (1 - phase) * 2);
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFFe94560).withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  /// 底部输入栏
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: '输入你的问题...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFe94560), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _loading ? null : () => _sendMessage(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _loading ? Colors.grey : const Color(0xFFe94560),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _loading ? Icons.hourglass_empty : Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
