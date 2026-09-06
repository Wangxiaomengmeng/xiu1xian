import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/game_provider.dart';
import '../widgets/player_status_bar.dart';
import 'cultivate_screen.dart';
import 'more_screen.dart';
import 'shop_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _checkedOffline = false;
  bool _checkedAnnouncement = false;

  final List<Widget> _pages = [
    const CultivateScreen(),
    const MoreScreen(),
    const ShopScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<GameProvider>();
      await provider.loadAll();

      // 离线收益
      if (!_checkedOffline && mounted) {
        _checkedOffline = true;
        try {
          final resp = await provider.api.offlineGain();
          if (resp['gain'] != null && resp['gain'] > 0) {
            await provider.loadPlayer();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'] ?? '离线收益已领取')));
            }
          }
        } catch (_) {}
      }

      // 公告检测
      if (!_checkedAnnouncement && mounted) {
        _checkedAnnouncement = true;
        _checkAnnouncement();
      }
    });
  }

  Future<void> _checkAnnouncement() async {
    try {
      final announcement = await context.read<GameProvider>().api.getLatestAnnouncement();
      if (announcement == null) return;

      final prefs = await SharedPreferences.getInstance();
      final lastReadId = prefs.getInt('last_announcement_id') ?? 0;
      final currentId = announcement['id'] as int;

      // 只有新公告才弹窗
      if (currentId > lastReadId && mounted) {
        _showAnnouncementDialog(announcement['title'], announcement['content'], currentId);
      }
    } catch (_) {}
  }

  void _showAnnouncementDialog(String title, String content, int id) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFFe94560), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.campaign, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('last_announcement_id', id);
                if (mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe94560),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('我知道了', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0f0f1e),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1a1a2e),
            title: const Text('修仙录', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 4)),
            centerTitle: true,
            actions: [
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: () => provider.loadAll()),
            ],
          ),
          body: Column(
            children: [
              if (provider.player != null)
                Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 0), child: PlayerStatusBar(player: provider.player!)),
              Expanded(child: _pages[_currentIndex]),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF1a1a2e),
            selectedItemColor: const Color(0xFFe94560),
            unselectedItemColor: Colors.white54,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.self_improvement), label: '修炼'),
              BottomNavigationBarItem(icon: Icon(Icons.explore), label: '仙途'),
              BottomNavigationBarItem(icon: Icon(Icons.store), label: '坊市'),
              BottomNavigationBarItem(icon: Icon(Icons.forum), label: '圈子'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
            ],
          ),
        );
      },
    );
  }
}
