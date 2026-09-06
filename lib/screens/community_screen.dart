import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/game_provider.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<Post> _posts = [];
  bool _loading = true;
  bool _hasMore = true;
  int _page = 1;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && _hasMore && !_loading) {
        _loadMore();
      }
    });
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _page = 1;
    });
    try {
      final resp = await context.read<GameProvider>().api.getPosts(page: 1);
      setState(() {
        _posts = (resp['posts'] as List).map((e) => Post.fromJson(e)).toList();
        _hasMore = resp['hasMore'] ?? false;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    try {
      final nextPage = _page + 1;
      final resp = await context.read<GameProvider>().api.getPosts(page: nextPage);
      final newPosts = (resp['posts'] as List).map((e) => Post.fromJson(e)).toList();
      setState(() {
        _posts.addAll(newPosts);
        _page = nextPage;
        _hasMore = resp['hasMore'] ?? false;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike(Post post, int index) async {
    try {
      final resp = await context.read<GameProvider>().api.toggleLike(post.id);
      setState(() {
        _posts[index] = Post(
          id: post.id,
          content: post.content,
          images: post.images,
          video: post.video,
          likeCount: resp['likeCount'] ?? post.likeCount,
          commentCount: post.commentCount,
          createdAt: post.createdAt,
          liked: resp['liked'] ?? false,
          author: post.author,
        );
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (result == true) _loadPosts();
        },
        backgroundColor: const Color(0xFFe94560),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: _loading && _posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Icon(Icons.forum_outlined, size: 60, color: Colors.white24)),
                      SizedBox(height: 12),
                      Center(child: Text('还没有帖子，快来发布第一条吧！', style: TextStyle(color: Colors.white38))),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: _posts.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _posts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildPostCard(_posts[i], i);
                    },
                  ),
      ),
    );
  }

  Widget _buildPostCard(Post post, int index) {
    final provider = context.read<GameProvider>();
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
        );
        _loadPosts();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 作者信息
            Row(
              children: [
                _buildAvatar(post.author.avatar, provider),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.author.nickname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(_formatTime(post.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 内容
            Text(post.content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5), maxLines: 5, overflow: TextOverflow.ellipsis),
            // 图片
            if (post.images.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildImages(post.images, provider),
            ],
            // 视频
            if (post.video != null && post.video!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                height: 180,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white54, size: 50)),
              ),
            ],
            const SizedBox(height: 10),
            // 互动栏
            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(post, index),
                  child: AnimatedScale(
                    scale: post.liked ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      children: [
                        Icon(post.liked ? Icons.favorite : Icons.favorite_border, color: post.liked ? Colors.red : Colors.white54, size: 20),
                        const SizedBox(width: 4),
                        Text('${post.likeCount}', style: TextStyle(color: post.liked ? Colors.red : Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Row(
                  children: [
                    const Icon(Icons.comment_outlined, color: Colors.white54, size: 20),
                    const SizedBox(width: 4),
                    Text('${post.commentCount}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, GameProvider provider) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: provider.api.fullUrl(avatarUrl),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(width: 40, height: 40, color: Colors.deepPurple, child: const Icon(Icons.person, color: Colors.white)),
          errorWidget: (_, __, ___) => Container(width: 40, height: 40, color: Colors.deepPurple, child: const Icon(Icons.person, color: Colors.white)),
        ),
      );
    }
    return Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white));
  }

  Widget _buildImages(List<String> images, GameProvider provider) {
    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: provider.api.fullUrl(images[0]),
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(height: 200, color: Colors.white10, child: const Center(child: CircularProgressIndicator())),
          errorWidget: (_, __, ___) => Container(height: 200, color: Colors.white10),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: images.length == 2 || images.length == 4 ? 2 : 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length,
      itemBuilder: (context, i) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            imageUrl: provider.api.fullUrl(images[i]),
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.white10),
            errorWidget: (_, __, ___) => Container(color: Colors.white10),
          ),
        );
      },
    );
  }

  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}-${dt.day}';
    } catch (_) {
      return dateStr;
    }
  }
}
