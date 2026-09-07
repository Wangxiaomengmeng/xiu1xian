import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';
import '../services/game_provider.dart';
import '../widgets/video_player_widget.dart';

class ChatDetailScreen extends StatefulWidget {
  final UserBrief partner;
  const ChatDetailScreen({super.key, required this.partner});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with TickerProviderStateMixin {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();

  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _showMediaMenu = false;

  // 语音录制
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _recordPath;

  // 语音播放
  VideoPlayerController? _voiceController;
  int? _playingVoiceId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _msgCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _recordTimer?.cancel();
    _recorder.dispose();
    _voiceController?.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await context.read<GameProvider>().api.getMessages(widget.partner.id);
      if (mounted) {
        setState(() { _messages = msgs; _loading = false; });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    try {
      final msg = await context.read<GameProvider>().api.sendMessage(widget.partner.id, text);
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage() async {
    setState(() => _showMediaMenu = false);
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    setState(() => _sending = true);
    try {
      final msg = await context.read<GameProvider>().api.sendImageMessage(widget.partner.id, File(img.path));
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickVideo() async {
    setState(() => _showMediaMenu = false);
    final XFile? vid = await _picker.pickVideo(source: ImageSource.gallery);
    if (vid == null) return;
    setState(() => _sending = true);
    try {
      final msg = await context.read<GameProvider>().api.sendVideoMessage(widget.partner.id, File(vid.path));
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ===== 语音录制 =====
  Future<void> _startRecording() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('需要麦克风权限')));
      return;
    }
    try {
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: '');
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
        _showMediaMenu = false;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _recordSeconds++);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('录音启动失败: $e')));
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recordTimer?.cancel();
    try {
      final path = await _recorder.stop();
      if (!cancel && path != null && _recordSeconds >= 1) {
        setState(() => _sending = true);
        try {
          final msg = await context.read<GameProvider>().api.sendVoiceMessage(
            widget.partner.id,
            File(path),
            duration: _recordSeconds,
          );
          setState(() => _messages.add(msg));
          _scrollToBottom();
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败: $e')));
        } finally {
          if (mounted) setState(() => _sending = false);
        }
      }
    } catch (_) {}
    if (mounted) setState(() { _isRecording = false; _recordSeconds = 0; });
  }

  // ===== 语音播放 =====
  Future<void> _toggleVoicePlay(ChatMessage msg) async {
    if (_playingVoiceId == msg.id) {
      await _voiceController?.pause();
      setState(() => _playingVoiceId = null);
      return;
    }
    await _voiceController?.dispose();
    try {
      final data = jsonDecode(msg.content);
      final url = context.read<GameProvider>().api.fullUrl(data['url']);
      _voiceController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _voiceController!.initialize();
      _voiceController!.play();
      setState(() => _playingVoiceId = msg.id);
      _voiceController!.addListener(() {
        if (_voiceController!.value.position >= _voiceController!.value.duration) {
          if (mounted) setState(() => _playingVoiceId = null);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _playingVoiceId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GameProvider>();
    final myId = provider.userInfo?.id ?? 0;
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(widget.partner.nickname, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _buildMessageBubble(_messages[i], myId, provider),
                    ),
                  ),
          ),
          // 录音遮罩
          if (_isRecording) _buildRecordingOverlay(),
          // 媒体菜单
          if (_showMediaMenu) _buildMediaMenu(),
          // 输入栏
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, int myId, GameProvider provider) {
    final isMe = msg.senderId == myId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(widget.partner.avatar, provider, size: 36),
            const SizedBox(width: 8),
          ],
          Flexible(child: _buildMessageContent(msg, isMe, provider)),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(provider.userInfo?.avatar, provider, size: 36),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage msg, bool isMe, GameProvider provider) {
    final bubbleColor = isMe ? const Color(0xFFe94560) : const Color(0xFF1a1a2e);
    final textColor = isMe ? Colors.white : Colors.white;

    switch (msg.type) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: provider.api.fullUrl(msg.content),
            width: 180,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(width: 180, height: 180, color: Colors.white10, child: const Center(child: CircularProgressIndicator())),
          ),
        );
      case 'video':
        return SizedBox(width: 200, child: VideoPlayerWidget(videoUrl: provider.api.fullUrl(msg.content), height: 150));
      case 'voice':
        return _buildVoiceBubble(msg, isMe);
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(16)),
          child: Text(msg.content, style: TextStyle(color: textColor, fontSize: 15)),
        );
    }
  }

  Widget _buildVoiceBubble(ChatMessage msg, bool isMe) {
    int duration = 0;
    try { duration = jsonDecode(msg.content)['duration'] ?? 0; } catch (_) {}
    final isPlaying = _playingVoiceId == msg.id;
    return GestureDetector(
      onTap: () => _toggleVoicePlay(msg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFe94560) : const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            // 语音波形动画
            Row(
              children: List.generate(4, (i) => AnimatedContainer(
                duration: Duration(milliseconds: 150 + i * 50),
                width: 3,
                height: isPlaying ? (8 + (i % 3) * 6).toDouble() : 8,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
              )),
            ),
            const SizedBox(width: 8),
            Text('${duration}″', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(color: Color(0xFF1a1a2e), border: Border(top: BorderSide(color: Colors.white10))),
      child: SafeArea(
        child: Row(
          children: [
            // 语音录制按钮
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              onLongPressCancel: () => _stopRecording(cancel: true),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(_isRecording ? Icons.mic_off : Icons.mic, color: _isRecording ? Colors.red : Colors.white54, size: 24),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '说点什么...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
            ),
            // 媒体按钮
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white54, size: 26),
              onPressed: () => setState(() => _showMediaMenu = !_showMediaMenu),
            ),
            // 发送按钮
            if (_msgCtrl.text.trim().isNotEmpty)
              GestureDetector(
                onTap: _sendText,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFe94560), shape: BoxShape.circle),
                  child: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaMenu() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1a1a2e),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMediaButton(Icons.photo_library, '图片', _pickImage),
          _buildMediaButton(Icons.videocam, '视频', _pickVideo),
        ],
      ),
    );
  }

  Widget _buildMediaButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white70, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecordingOverlay() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mic, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          Text('正在录音 $_recordSeconds 秒，松开发送', style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, GameProvider provider, {double size = 36}) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: provider.api.fullUrl(avatarUrl),
          width: size, height: size, fit: BoxFit.cover,
          placeholder: (_, __) => Container(width: size, height: size, color: Colors.deepPurple, child: Icon(Icons.person, color: Colors.white, size: size * 0.5)),
          errorWidget: (_, __, ___) => Container(width: size, height: size, color: Colors.deepPurple, child: Icon(Icons.person, color: Colors.white, size: size * 0.5)),
        ),
      );
    }
    return Container(width: size, height: size, decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle), child: Icon(Icons.person, color: Colors.white, size: size * 0.5));
  }
}
