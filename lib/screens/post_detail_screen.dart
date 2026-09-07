import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/game_provider.dart';
import '../widgets/video_player_widget.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? _post;
  List<Comment> _comments = [];
  bool _loading = true;
  final _commentCtrl = TextEditingController();
  bool _sendingComment = false;
  Comment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = context.read<GameProvider>().api;
    try {
      final post = await api.getPostDetail(widget.postId);
      final comments = await api.getComments(widget.postId);
      setState(() {
        _post = post;
        _comments = comments;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;
    try {
      final resp = await context.read<GameProvider>().api.toggleLike(_post!.id);
      setState(() {
        _post = Post(
          id: _post!.id,
          content: _post!.content,
          images: _post!.images,
          video: _post!.video,
          likeCount: resp['likeCount'] ?? _post!.likeCount,
          commentCount: _post!.commentCount,
          createdAt: _post!.createdAt,
          liked: resp['liked'] ?? false,
          author: _post!.author,
        );
      });
    } catch (_) {}
  }

  Future<void> _toggleCommentLike(Comment c, {bool isReply = false, int? parentIndex}) async {
    try {
      final resp = await context.read<GameProvider>().api.toggleCommentLike(widget.postId, c.id);
      setState(() {
        final updated = Comment(
          id: c.id,
          content: c.content,
          createdAt: c.createdAt,
          author: c.author,
          parentId: c.parentId,
          likeCount: resp['likeCount'] ?? c.likeCount,
          liked: resp['liked'] ?? false,
          replies: c.replies,
        );
        if (isReply && parentIndex != null) {
          final replies = List<Comment>.from(_comments[parentIndex].replies);
          final idx = replies.indexWhere((r) => r.id == c.id);
          if (idx >= 0) replies[idx] = updated;
          _comments[parentIndex] = Comment(
            id: _comments[parentIndex].id,
            content: _comments[parentIndex].content,
            createdAt: _comments[parentIndex].createdAt,
            author: _comments[parentIndex].author,
            parentId: _comments[parentIndex].parentId,
            likeCount: _comments[parentIndex].likeCount,
            liked: _comments[parentIndex].liked,
            replies: replies,
          );
        } else {
          final idx = _comments.indexWhere((e) => e.id == c.id);
          if (idx >= 0) _comments[idx] = updated;
        }
      });
    } catch (_) {}
  }

  void _startReply(Comment c) {
    setState(() => _replyingTo = c);
    _commentCtrl.text = '';
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
    _commentCtrl.clear();
  }

  Future<void> _sendComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty || _sendingComment) return;
    setState(() => _sendingComment = true);
    try {
      final resp = await context.read<GameProvider>().api.addComment(
        widget.postId,
        content,
        parentId: _replyingTo?.id,
      );
      if (resp['comment'] != null) {
        final newComment = Comment.fromJson(resp['comment']);
        setState(() {
          if (_replyingTo != null) {
            // 回复：挂到对应顶级评论的 replies 下
            final parentIdx = _comments.indexWhere((c) => c.id == _replyingTo!.id || c.replies.any((r) => r.id == _replyingTo!.id));
            if (parentIdx >= 0) {
              final replies = List<Comment>.from(_comments[parentIdx].replies)..add(newComment);
              _comments[parentIdx] = Comment(
                id: _comments[parentIdx].id,
                content: _comments[parentIdx].content,
                createdAt: _comments[parentIdx].createdAt,
                author: _comments[parentIdx].author,
                parentId: _comments[parentIdx].parentId,
                likeCount: _comments[parentIdx].likeCount,
                liked: _comments[parentIdx].liked,
                replies: replies,
              );
            }
          } else {
            _comments.add(newComment);
          }
          if (_post != null) {
            _post = Post(
              id: _post!.id,
              content: _post!.content,
              images: _post!.images,
              video: _post!.video,
              likeCount: _post!.likeCount,
              commentCount: _post!.commentCount + 1,
              createdAt: _post!.createdAt,
              liked: _post!.liked,
              author: _post!.author,
            );
          }
        });
        _commentCtrl.clear();
        _replyingTo = null;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GameProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('帖子详情', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 作者
                        Row(
                          children: [
                            _buildAvatar(_post?.author.avatar, provider),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_post?.author.nickname ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text(_post?.createdAt ?? '', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 内容
                        Text(_post?.content ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6)),
                        // 图片
                        if (_post != null && _post!.images.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ..._post!.images.map((url) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: provider.api.fullUrl(url),
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(height: 200, color: Colors.white10, child: const Center(child: CircularProgressIndicator())),
                                  ),
                                ),
                              )),
                        ],
                        // 视频
                        if (_post?.video != null && _post!.video!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          VideoPlayerWidget(videoUrl: provider.api.fullUrl(_post!.video!), height: 220),
                        ],
                        const SizedBox(height: 16),
                        // 点赞栏
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _toggleLike,
                              child: AnimatedScale(
                                scale: _post?.liked == true ? 1.3 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Row(
                                  children: [
                                    Icon(_post?.liked == true ? Icons.favorite : Icons.favorite_border, color: _post?.liked == true ? Colors.red : Colors.white54, size: 24),
                                    const SizedBox(width: 6),
                                    Text('${_post?.likeCount ?? 0}', style: TextStyle(color: _post?.liked == true ? Colors.red : Colors.white54)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Row(
                              children: [
                                const Icon(Icons.comment_outlined, color: Colors.white54, size: 22),
                                const SizedBox(width: 6),
                                Text('${_post?.commentCount ?? 0}', style: const TextStyle(color: Colors.white54)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 12),
                        const Text('评论', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        if (_comments.isEmpty)
                          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('还没有评论，快来抢沙发！', style: TextStyle(color: Colors.white38))))
                        else
                          ..._comments.asMap().entries.map((entry) => _buildCommentItem(entry.value, provider, entry.key)),
                      ],
                    ),
                  ),
                ),
                // 评论输入框
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Color(0xFF1a1a2e), border: Border(top: BorderSide(color: Colors.white10))),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_replyingTo != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('回复 @${_replyingTo!.author.nickname}', style: const TextStyle(color: Color(0xFFe94560), fontSize: 13)),
                                ),
                                GestureDetector(
                                  onTap: _cancelReply,
                                  child: const Icon(Icons.close, color: Colors.white38, size: 18),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: _replyingTo != null ? '回复...' : '写评论...',
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  filled: true,
                                  fillColor: Colors.white10,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _sendComment,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(color: Color(0xFFe94560), shape: BoxShape.circle),
                                child: _sendingComment ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCommentItem(Comment c, GameProvider provider, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(c.author.avatar, provider, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.author.nickname, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(c.content, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 6),
                    // 互动栏：点赞 + 回复
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleCommentLike(c),
                          child: Row(
                            children: [
                              Icon(c.liked ? Icons.favorite : Icons.favorite_border, color: c.liked ? Colors.red : Colors.white38, size: 14),
                              const SizedBox(width: 3),
                              Text('${c.likeCount}', style: TextStyle(color: c.liked ? Colors.red : Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _startReply(c),
                          child: const Row(
                            children: [
                              Icon(Icons.reply, color: Colors.white38, size: 14),
                              SizedBox(width: 3),
                              Text('回复', style: TextStyle(color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(c.createdAt, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 嵌套回复
          if (c.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(left: 42),
              padding: const EdgeInsets.only(left: 10, top: 8, bottom: 4),
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: Colors.white12, width: 2))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: c.replies.map((r) => _buildReplyItem(r, provider, index)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyItem(Comment r, GameProvider provider, int parentIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(r.author.avatar, provider, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.author.nickname, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(r.content, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleCommentLike(r, isReply: true, parentIndex: parentIndex),
                      child: Row(
                        children: [
                          Icon(r.liked ? Icons.favorite : Icons.favorite_border, color: r.liked ? Colors.red : Colors.white24, size: 12),
                          const SizedBox(width: 3),
                          Text('${r.likeCount}', style: TextStyle(color: r.liked ? Colors.red : Colors.white24, fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _startReply(r),
                      child: const Text('回复', style: TextStyle(color: Colors.white24, fontSize: 10)),
                    ),
                    const SizedBox(width: 12),
                    Text(r.createdAt, style: const TextStyle(color: Colors.white12, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, GameProvider provider, {double size = 40}) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: provider.api.fullUrl(avatarUrl),
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(width: size, height: size, color: Colors.deepPurple, child: Icon(Icons.person, color: Colors.white, size: size * 0.5)),
          errorWidget: (_, __, ___) => Container(width: size, height: size, color: Colors.deepPurple, child: Icon(Icons.person, color: Colors.white, size: size * 0.5)),
        ),
      );
    }
    return Container(width: size, height: size, decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle), child: Icon(Icons.person, color: Colors.white, size: size * 0.5));
  }
}
