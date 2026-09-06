import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/game_provider.dart';
import '../utils/format_utils.dart';
import 'edit_profile_screen.dart';
import 'inventory_screen.dart';
import 'leaderboard_screen.dart';
import 'ai_assistant_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final player = provider.player;
    final userInfo = provider.userInfo;
    if (player == null) return const Center(child: CircularProgressIndicator());

    final avatarUrl = userInfo?.avatar;
    final displayName = userInfo?.nickname ?? player.username;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 头像和昵称
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(int.parse(FormatUtils.realmColor(player.realm))), width: 2),
                      ),
                      child: ClipOval(
                        child: avatarUrl != null && avatarUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: provider.api.fullUrl(avatarUrl),
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: Colors.deepPurple, child: const Icon(Icons.person, color: Colors.white, size: 40)),
                                errorWidget: (_, __, ___) => Container(color: Colors.deepPurple, child: const Icon(Icons.person, color: Colors.white, size: 40)),
                              )
                            : Container(color: Colors.deepPurple, child: const Icon(Icons.person, color: Colors.white, size: 40)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Color(0xFFe94560), shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.white, size: 14)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(color: Color(int.parse(FormatUtils.realmColor(player.realm))), borderRadius: BorderRadius.circular(10)),
                child: Text(player.realm, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                icon: const Icon(Icons.edit, size: 14, color: Colors.white54),
                label: const Text('编辑资料', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 快捷入口
        Row(
          children: [
            Expanded(child: _quickEntry(Icons.backpack, '背包', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())))),
            Expanded(child: _quickEntry(Icons.emoji_events, '排行榜', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())))),
            Expanded(child: _quickEntry(Icons.auto_awesome, 'AI助手', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen())))),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle('详细属性'),
        _detailCard([
          _row('道号', player.username),
          _row('当前功法', _getTechName(player.technique)),
          _row('已学功法', '${player.learnedTechniques.length} 部'),
          _row('炼丹等级', 'Lv.${player.alchemyLevel}'),
          _row('生命值', '${player.hp} / ${player.maxHp}'),
          _row('体力', '${player.stamina} / ${player.maxStamina}'),
          _row('攻击力', player.atk.toString()),
          _row('防御力', player.def.toString()),
          _row('战斗力', FormatUtils.formatNumber(player.power)),
          _row('灵石', FormatUtils.formatNumber(player.spiritStones)),
          _row('修为', FormatUtils.formatNumber(player.cultivation)),
        ]),
        const SizedBox(height: 16),
        _sectionTitle('修炼成就'),
        _detailCard([
          _row('累计修为', FormatUtils.formatNumber((player.stats['totalCultivationGained'] ?? 0).toInt())),
          _row('突破次数', '${player.stats['breakthroughs'] ?? 0} 次'),
          _row('斩杀妖兽', '${player.stats['monstersKilled'] ?? 0} 只'),
          _row('秘境通关', '${player.stats['dungeonsCleared'] ?? 0} 次'),
          _row('炼制丹药', '${player.stats['pillsCrafted'] ?? 0} 颗'),
          _row('服用丹药', '${player.stats['pillsUsed'] ?? 0} 颗'),
          _row('修炼天数', '${player.stats['daysCultivated'] ?? 0} 天'),
        ]),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () async {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1a1a2e),
                  title: const Text('退出登录', style: TextStyle(color: Colors.white)),
                  content: const Text('确定要退出当前账号吗？游戏数据已保存在云端，下次登录可继续。', style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        await provider.logout();
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      },
                      child: const Text('退出'),
                    ),
                  ],
                ),
              );
            },
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
            child: const Text('退出登录', style: TextStyle(color: Colors.red)),
          ),
        ),
        const SizedBox(height: 16),
        const Center(child: Text('修仙录 v2.0.0', style: TextStyle(color: Colors.white24, fontSize: 11))),
      ],
    );
  }

  Widget _quickEntry(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFe94560), size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _getTechName(String id) {
    const names = {'basic': '基础吐纳术', 'qingfeng': '清风诀', 'xuanbing': '玄冰功', 'lianyang': '烈阳真经', 'taishang': '太上忘情诀', 'hongmeng': '鸿蒙造化功'};
    return names[id] ?? id;
  }

  Widget _sectionTitle(String text) => Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)));

  Widget _detailCard(List<Widget> rows) => Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(16), child: Column(children: rows));

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
      );
}
