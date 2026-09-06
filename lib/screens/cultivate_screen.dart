import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../utils/format_utils.dart';

class CultivateScreen extends StatefulWidget {
  const CultivateScreen({super.key});

  @override
  State<CultivateScreen> createState() => _CultivateScreenState();
}

class _CultivateScreenState extends State<CultivateScreen> with TickerProviderStateMixin {
  bool _cultivating = false;
  String? _message;
  late final AnimationController _pulseCtrl;
  late final AnimationController _rotateCtrl;
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cultivate() async {
    if (_cultivating) return;
    setState(() => _cultivating = true);
    _rotateCtrl.repeat();
    final provider = context.read<GameProvider>();
    try {
      final resp = await provider.api.cultivate();
      setState(() => _message = resp['message']);
      _fadeCtrl.forward(from: 0);
      await provider.loadPlayer();
      if (resp['canBreakthrough'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修为已足，可尝试突破到${resp['nextRealm']}！')));
      }
    } catch (e) {
      setState(() => _message = '修炼失败: $e');
    } finally {
      if (mounted) {
        setState(() => _cultivating = false);
        _rotateCtrl.stop();
      }
    }
  }

  Future<void> _breakthrough() async {
    final provider = context.read<GameProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('突破境界', style: TextStyle(color: Colors.white)),
        content: Text('当前突破成功率: ${(provider.player!.breakthroughChance * 100).toStringAsFixed(1)}%\n失败将损失部分修为，确定尝试？', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('再等等')),
          ElevatedButton(onPressed: () async {
            Navigator.pop(ctx);
            try {
              final resp = await provider.api.breakthrough();
              await provider.loadPlayer();
              if (mounted) {
                showDialog(context: context, builder: (c) => AlertDialog(
                  backgroundColor: const Color(0xFF1a1a2e),
                  title: Text(resp['success'] == true ? '突破成功！' : '突破失败', style: TextStyle(color: resp['success'] == true ? Colors.green : Colors.red)),
                  content: Text(resp['message'] ?? '', style: const TextStyle(color: Colors.white70)),
                  actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('好'))],
                ));
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }, child: const Text('突破！')),
        ],
      ),
    );
  }

  Future<void> _rest() async {
    final provider = context.read<GameProvider>();
    try {
      final resp = await provider.api.rest();
      await provider.loadPlayer();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'])));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final player = provider.player;
        if (player == null) return const Center(child: CircularProgressIndicator());
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 修炼大按钮 - 带动画
              GestureDetector(
                onTap: _cultivate,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulseCtrl, _rotateCtrl]),
                  builder: (context, child) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFe94560).withOpacity(0.6 + _pulseCtrl.value * 0.4),
                            const Color(0xFF1a1a2e),
                          ],
                          radius: 0.7 + _pulseCtrl.value * 0.1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 旋转光环
                          Positioned(
                            child: Transform.rotate(
                              angle: _rotateCtrl.value * 6.28,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                                ),
                                child: const Icon(Icons.autorenew, color: Colors.white24, size: 20),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: _cultivating ? 1.2 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: const Icon(Icons.auto_awesome, size: 56, color: Colors.white),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _cultivating ? '运转功法中...' : '点击修炼',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4),
                              ),
                              const SizedBox(height: 6),
                              const Text('吸收天地灵气，提升修为', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _fadeCtrl,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(_message!, style: const TextStyle(color: Colors.amber, fontSize: 14)),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // 突破 & 休息
              Row(
                children: [
                  Expanded(child: _actionCard(Icons.vertical_align_top, '突破境界', '成功率 ${(player.breakthroughChance * 100).toStringAsFixed(1)}%', Colors.purple, _breakthrough)),
                  const SizedBox(width: 12),
                  Expanded(child: _actionCard(Icons.nightlight_round, '打坐休息', '恢复30%生命', Colors.indigo, _rest)),
                ],
              ),
              const SizedBox(height: 20),
              _buildRealmProgress(player),
              const SizedBox(height: 20),
              _buildStats(player),
            ],
          ),
        );
      },
    );
  }

  Widget _actionCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildRealmProgress(player) {
    const realms = ['炼气期', '筑基期', '金丹期', '元婴期', '化神期', '炼虚期', '合体期', '大乘期', '渡劫期', '仙人'];
    final currentIdx = realms.indexOf(player.realm);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('境界之路', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: realms.asMap().entries.map((e) {
              final reached = e.key <= currentIdx;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: reached ? Color(int.parse(FormatUtils.realmColor(e.value))) : Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(e.value, style: TextStyle(color: reached ? Colors.white : Colors.white38, fontSize: 11, fontWeight: reached ? FontWeight.bold : FontWeight.normal)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(player) {
    final stats = player.stats;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('修炼统计', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _statRow('累计修为', FormatUtils.formatNumber((stats['totalCultivationGained'] ?? 0).toInt())),
          _statRow('突破次数', '${stats['breakthroughs'] ?? 0} 次'),
          _statRow('斩杀妖兽', '${stats['monstersKilled'] ?? 0} 只'),
          _statRow('秘境通关', '${stats['dungeonsCleared'] ?? 0} 次'),
          _statRow('炼制丹药', '${stats['pillsCrafted'] ?? 0} 颗'),
          _statRow('服用丹药', '${stats['pillsUsed'] ?? 0} 颗'),
          _statRow('修炼天数', '${stats['daysCultivated'] ?? 0} 天'),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
      );
}
