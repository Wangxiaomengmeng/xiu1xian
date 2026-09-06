import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/game_provider.dart';
import '../utils/format_utils.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  List<Monster> _monsters = [];
  bool _loading = true;
  String? _battleLog;

  @override
  void initState() {
    super.initState();
    _loadMonsters();
  }

  Future<void> _loadMonsters() async {
    try {
      final list = await context.read<GameProvider>().api.getMonsters();
      setState(() {
        _monsters = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _battleLog = '加载妖兽失败: $e';
      });
    }
  }

  Future<void> _battle(Monster m) async {
    final provider = context.read<GameProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(width: 16), Text('战斗中...')]),
      ),
    );
    try {
      final resp = await provider.api.battle(m.id);
      Navigator.pop(context);
      await provider.loadPlayer();
      setState(() => _battleLog = resp['message']);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(resp['won'] == true ? '战斗胜利！' : '战斗失败', style: TextStyle(color: resp['won'] == true ? Colors.green : Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(resp['message']),
              const SizedBox(height: 8),
              Text('损失生命: ${resp['hpLost']}'),
              if (resp['rewards'] != null) ...[
                const SizedBox(height: 8),
                Text('获得修为: ${resp['rewards']['exp']}'),
                Text('获得灵石: ${resp['rewards']['spiritStones']}'),
              ],
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定'))],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadMonsters,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _monsters.length,
        itemBuilder: (context, i) {
          final m = _monsters[i];
          return Card(
            color: Colors.white.withOpacity(0.05),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.pets, color: Colors.redAccent, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                            Text('境界等级: ${m.realm}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _battle(m),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFe94560)),
                        child: const Text('挑战'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('生命', m.hp, Colors.red),
                      _stat('攻击', m.atk, Colors.orange),
                      _stat('防御', m.def, Colors.blue),
                      _stat('经验', m.exp, Colors.green),
                      _stat('灵石', m.spiritStones, Colors.teal),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _stat(String label, int value, Color color) {
    return Column(
      children: [
        Text(FormatUtils.formatNumber(value), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
