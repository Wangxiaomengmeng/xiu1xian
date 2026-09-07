import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/game_provider.dart';
import 'chat_detail_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();

  List<UserBrief> _friends = [];
  List<FriendRequest> _requests = [];
  List<SearchUser> _searchResults = [];
  bool _loadingFriends = true;
  bool _loadingRequests = true;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadFriends();
    _loadRequests();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      final list = await context.read<GameProvider>().api.getFriends();
      if (mounted) setState(() { _friends = list; _loadingFriends = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingFriends = false);
    }
  }

  Future<void> _loadRequests() async {
    try {
      final list = await context.read<GameProvider>().api.getFriendRequests();
      if (mounted) setState(() { _requests = list; _loadingRequests = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  Future<void> _doSearch() async {
    final kw = _searchCtrl.text.trim();
    if (kw.isEmpty) { setState(() => _searchResults = []); return; }
    setState(() => _searching = true);
    try {
      final results = await context.read<GameProvider>().api.searchUsers(kw);
      if (mounted) setState(() { _searchResults = results; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _addFriend(int userId) async {
    try {
      final resp = await context.read<GameProvider>().api.sendFriendRequest(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'] ?? '操作成功')));
        _doSearch();
        _loadRequests();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _acceptRequest(int id) async {
    try {
      await context.read<GameProvider>().api.acceptFriendRequest(id);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已接受'))); _loadRequests(); _loadFriends(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _rejectRequest(int id) async {
    try {
      await context.read<GameProvider>().api.rejectFriendRequest(id);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已拒绝'))); _loadRequests(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GameProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('好友', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFFe94560),
          unselectedLabelColor: Colors.white38,
          indicatorColor: const Color(0xFFe94560),
          tabs: [
            Tab(text: '好友 (${_friends.length})'),
            Tab(text: '申请 (${_requests.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildFriendListTab(provider),
          _buildRequestsTab(provider),
        ],
      ),
    );
  }

  Widget _buildFriendListTab(GameProvider provider) {
    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            onSubmitted: (_) => _doSearch(),
            decoration: InputDecoration(
              hintText: '搜索用户名或昵称...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white10,
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              suffixIcon: _searching
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFe94560)))
                  : IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: () { _searchCtrl.clear(); setState(() => _searchResults = []); }),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
        ),
        // 搜索结果
        if (_searchResults.isNotEmpty)
          Expanded(child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (_, i) => _buildSearchResultItem(_searchResults[i], provider),
          ))
        else if (_loadingFriends)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_friends.isEmpty)
          const Expanded(child: Center(child: Text('还没有好友，去搜索添加吧', style: TextStyle(color: Colors.white38))))
        else
          Expanded(child: ListView.builder(
            itemCount: _friends.length,
            itemBuilder: (_, i) => _buildFriendItem(_friends[i], provider),
          )),
      ],
    );
  }

  Widget _buildSearchResultItem(SearchUser user, GameProvider provider) {
    return ListTile(
      leading: _buildAvatar(user.avatar, provider),
      title: Text(user.nickname, style: const TextStyle(color: Colors.white)),
      subtitle: Text('@${user.username}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: user.friendship == 'accepted'
          ? const Text('已是好友', style: TextStyle(color: Colors.white24, fontSize: 12))
          : user.friendship == 'pending'
              ? const Text('已申请', style: TextStyle(color: Colors.white24, fontSize: 12))
              : TextButton(
                  onPressed: () => _addFriend(user.id),
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFFe94560)),
                  child: const Text('添加', style: TextStyle(color: Colors.white)),
                ),
    );
  }

  Widget _buildFriendItem(UserBrief friend, GameProvider provider) {
    return ListTile(
      leading: _buildAvatar(friend.avatar, provider),
      title: Text(friend.nickname, style: const TextStyle(color: Colors.white)),
      subtitle: Text('@${friend.username}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: const Icon(Icons.chat_bubble_outline, color: Colors.white38, size: 20),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(partner: friend))),
    );
  }

  Widget _buildRequestsTab(GameProvider provider) {
    if (_loadingRequests) return const Center(child: CircularProgressIndicator());
    if (_requests.isEmpty) return const Center(child: Text('暂无好友申请', style: TextStyle(color: Colors.white38)));
    return ListView.builder(
      itemCount: _requests.length,
      itemBuilder: (_, i) {
        final req = _requests[i];
        return ListTile(
          leading: _buildAvatar(req.requester.avatar, provider),
          title: Text(req.requester.nickname, style: const TextStyle(color: Colors.white)),
          subtitle: Text('@${req.requester.username} 请求添加好友', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _acceptRequest(req.id),
                style: TextButton.styleFrom(backgroundColor: const Color(0xFFe94560), padding: const EdgeInsets.symmetric(horizontal: 12)),
                child: const Text('接受', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () => _rejectRequest(req.id),
                style: TextButton.styleFrom(backgroundColor: Colors.white12, padding: const EdgeInsets.symmetric(horizontal: 12)),
                child: const Text('拒绝', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? avatarUrl, GameProvider provider) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: provider.api.fullUrl(avatarUrl),
          width: 44, height: 44, fit: BoxFit.cover,
          placeholder: (_, __) => Container(width: 44, height: 44, color: Colors.deepPurple, child: const Icon(Icons.person, color: Colors.white)),
          errorWidget: (_, __, ___) => Container(width: 44, height: 44, color: Colors.deepPurple, child: const Icon(Icons.person, color: Colors.white)),
        ),
      );
    }
    return Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white));
  }
}
