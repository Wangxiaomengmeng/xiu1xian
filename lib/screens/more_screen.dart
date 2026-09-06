import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/game_provider.dart';
import '../utils/format_utils.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF1a1a2e),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: const Color(0xFFe94560),
            unselectedLabelColor: Colors.white54,
            indicatorColor: const Color(0xFFe94560),
            tabs: const [
              Tab(icon: Icon(Icons.sports_martial_arts), text: '历练'),
              Tab(icon: Icon(Icons.explore), text: '秘境'),
              Tab(icon: Icon(Icons.science), text: '炼丹'),
              Tab(icon: Icon(Icons.shield), text: '装备'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: const [BattleTab(), DungeonTab(), AlchemyTab(), EquipmentTab()],
          ),
        ),
      ],
    );
  }
}

// ===== 秘境探索 =====
class DungeonTab extends StatefulWidget {
  const DungeonTab({super.key});

  @override
  State<DungeonTab> createState() => _DungeonTabState();
}

class _DungeonTabState extends State<DungeonTab> {
  List<Dungeon> _dungeons = [];
  bool _loading = true;
  bool _exploring = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await context.read<GameProvider>().api.getDungeons();
      setState(() {
        _dungeons = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _explore(Dungeon d) async {
    if (_exploring) return;
    setState(() => _exploring = true);
    final provider = context.read<GameProvider>();
    try {
      final resp = await provider.api.exploreDungeon(d.id);
      await provider.loadPlayer();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          title: Text(resp['success'] == true ? '探索成功！' : '探索失败', style: TextStyle(color: resp['success'] == true ? Colors.green : Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(resp['message'] ?? '', style: const TextStyle(color: Colors.white)),
              if (resp['rewards'] != null) ...[
                const SizedBox(height: 8),
                Text('修为+${resp['rewards']['cultivation']}', style: const TextStyle(color: Colors.green)),
                Text('灵石+${resp['rewards']['spiritStones']}', style: const TextStyle(color: Colors.teal)),
                if (resp['rewards']['materials'] != null && (resp['rewards']['materials'] as Map).isNotEmpty)
                  Text('材料: ${(resp['rewards']['materials'] as Map).keys.join(', ')}', style: const TextStyle(color: Colors.purple)),
              ],
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定'))],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _exploring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _dungeons.length,
        itemBuilder: (context, i) {
          final d = _dungeons[i];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: d.unlocked
                  ? LinearGradient(colors: [Colors.purple.withOpacity(0.3), Colors.deepPurple.withOpacity(0.1)])
                  : null,
              color: d.unlocked ? null : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: d.unlocked ? Colors.purple.withOpacity(0.5) : Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(d.unlocked ? Icons.lock_open : Icons.lock, color: d.unlocked ? Colors.purple : Colors.white38, size: 22),
                    const SizedBox(width: 10),
                    Expanded(child: Text(d.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
                    if (d.unlocked)
                      ElevatedButton(
                        onPressed: _exploring ? null : () => _explore(d),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFe94560)),
                        child: const Text('探索'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('守护者: ${d.boss}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _tag('需境界 Lv.${d.minRealm}', Colors.orange),
                    const SizedBox(width: 8),
                    _tag('体力 -${d.staminaCost}', Colors.green),
                  ],
                ),
                if (!d.unlocked) const Padding(padding: EdgeInsets.only(top: 8), child: Text('境界不足，无法进入', style: TextStyle(color: Colors.white38, fontSize: 12))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: Text(text, style: TextStyle(color: color, fontSize: 11)));
  }
}

// ===== 炼丹 =====
class AlchemyTab extends StatefulWidget {
  const AlchemyTab({super.key});

  @override
  State<AlchemyTab> createState() => _AlchemyTabState();
}

class _AlchemyTabState extends State<AlchemyTab> {
  List<Pill> _pills = [];
  Map<String, int> _materials = {};
  int _alchemyLevel = 1;
  bool _loading = true;
  bool _crafting = false;

  static const materialNames = {'lingcao': '灵草', 'xuancao': '玄草', 'yexinghua': '夜杏花', 'huolongguo': '火龙果', 'tiancaishenbao': '天材地宝', 'lingquan': '灵泉水'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<GameProvider>().api;
    try {
      final results = await Future.wait([api.getPills(), api.getAlchemyMaterials()]);
      setState(() {
        _pills = results[0] as List<Pill>;
        final matData = results[1] as Map<String, dynamic>;
        _materials = Map<String, int>.from((matData['materials'] ?? {}).map((k, v) => MapEntry(k, v.toInt())));
        _alchemyLevel = matData['alchemyLevel'] ?? 1;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  bool _canCraft(Pill pill) {
    if (pill.recipe == null) return false;
    for (final m in pill.recipe!) {
      if ((_materials[m] ?? 0) < 1) return false;
    }
    return true;
  }

  Future<void> _craft(Pill pill) async {
    if (_crafting || !_canCraft(pill)) return;
    setState(() => _crafting = true);
    final provider = context.read<GameProvider>();
    try {
      final resp = await provider.api.craftPill(pill.id);
      await provider.loadPlayer();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'] ?? '')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _crafting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        // 材料栏
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory_2, color: Colors.purple, size: 18),
                  const SizedBox(width: 6),
                  const Text('炼丹材料', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('炼丹等级 Lv.$_alchemyLevel', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: materialNames.entries.map((e) {
                  final count = _materials[e.key] ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: count > 0 ? Colors.green.withOpacity(0.15) : Colors.white10, borderRadius: BorderRadius.circular(8)),
                    child: Text('${e.value} x$count', style: TextStyle(color: count > 0 ? Colors.green : Colors.white38, fontSize: 12)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _pills.length,
              itemBuilder: (context, i) {
                final pill = _pills[i];
                final canCraft = _canCraft(pill);
                return Card(
                  color: Colors.white.withOpacity(0.05),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.medication, color: Colors.greenAccent)),
                    title: Row(
                      children: [
                        Text(pill.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text(pill.grade, style: const TextStyle(color: Colors.amber, fontSize: 10))),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pill.desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('材料: ${pill.recipe?.map((m) => materialNames[m] ?? m).join(' + ') ?? '无'}', style: TextStyle(color: canCraft ? Colors.green : Colors.red, fontSize: 11)),
                        Text('拥有: ${pill.owned} 颗', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                    trailing: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: canCraft && !_crafting ? () => _craft(pill) : null,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), backgroundColor: const Color(0xFFe94560)),
                        child: const Text('炼制', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ===== 装备 =====
class EquipmentTab extends StatefulWidget {
  const EquipmentTab({super.key});

  @override
  State<EquipmentTab> createState() => _EquipmentTabState();
}

class _EquipmentTabState extends State<EquipmentTab> {
  List<Equipment> _equipments = [];
  bool _loading = true;

  static const rarityColors = {'普通': Colors.grey, '精良': Colors.green, '稀有': Colors.blue, '史诗': Colors.purple};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await context.read<GameProvider>().api.getEquipments();
      setState(() {
        _equipments = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _buy(Equipment e) async {
    final provider = context.read<GameProvider>();
    try {
      final resp = await provider.api.buyEquipment(e.id);
      await provider.loadPlayer();
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'] ?? '')));
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString())));
    }
  }

  Future<void> _equip(Equipment e) async {
    final provider = context.read<GameProvider>();
    try {
      final resp = await provider.api.equipItem(e.id);
      await provider.loadPlayer();
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'] ?? '')));
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _equipments.length,
        itemBuilder: (context, i) {
          final e = _equipments[i];
          final color = rarityColors[e.rarity] ?? Colors.grey;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: e.equipped ? color.withOpacity(0.15) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: e.equipped ? color : Colors.white10),
            ),
            child: Row(
              children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Icon(e.type == 'weapon' ? Icons.sports_martial_arts : Icons.shield, color: color, size: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(e.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Text(e.rarity, style: TextStyle(color: color, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (e.atk > 0) Text('攻击+${e.atk} ', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                          if (e.def > 0) Text('防御+${e.def} ', style: const TextStyle(color: Colors.blue, fontSize: 12)),
                          if (e.hp > 0) Text('生命+${e.hp}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                e.equipped
                    ? const Text('已装备', style: TextStyle(color: Colors.green, fontSize: 12))
                    : e.owned
                        ? SizedBox(height: 32, child: ElevatedButton(onPressed: () => _equip(e), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), backgroundColor: Colors.blue), child: const Text('装备', style: TextStyle(fontSize: 11))))
                        : Column(
                            children: [
                              Text('${FormatUtils.formatNumber(e.cost)} 灵石', style: const TextStyle(color: Colors.teal, fontSize: 11)),
                              const SizedBox(height: 4),
                              SizedBox(height: 28, child: ElevatedButton(onPressed: () => _buy(e), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), backgroundColor: const Color(0xFFe94560)), child: const Text('购买', style: TextStyle(fontSize: 11)))),
                            ],
                          ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===== 历练战斗 =====
class BattleTab extends StatefulWidget {
  const BattleTab({super.key});

  @override
  State<BattleTab> createState() => _BattleTabState();
}

class _BattleTabState extends State<BattleTab> {
  List<Monster> _monsters = [];
  bool _loading = true;

  static const materialNames = {'lingcao': '灵草', 'xuancao': '玄草', 'yexinghua': '夜杏花', 'huolongguo': '火龙果', 'tiancaishenbao': '天材地宝', 'lingquan': '灵泉水'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await context.read<GameProvider>().api.getMonsters();
      setState(() {
        _monsters = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _battle(Monster m) async {
    final provider = context.read<GameProvider>();
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const AlertDialog(backgroundColor: Color(0xFF1a1a2e), content: Row(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(width: 16), Text('战斗中...', style: TextStyle(color: Colors.white))])));
    try {
      final resp = await provider.api.battle(m.id);
      Navigator.pop(context);
      await provider.loadPlayer();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          title: Text(resp['won'] == true ? '战斗胜利！' : '战斗失败', style: TextStyle(color: resp['won'] == true ? Colors.green : Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(resp['message'] ?? '', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('损失生命: ${resp['hpLost']}', style: const TextStyle(color: Colors.red, fontSize: 13)),
              if (resp['rewards'] != null) ...[
                const SizedBox(height: 8),
                Text('修为+${resp['rewards']['exp']}', style: const TextStyle(color: Colors.green, fontSize: 13)),
                Text('灵石+${resp['rewards']['spiritStones']}', style: const TextStyle(color: Colors.teal, fontSize: 13)),
                if (resp['rewards']['drops'] != null && (resp['rewards']['drops'] as Map).isNotEmpty)
                  Text('掉落: ${(resp['rewards']['drops'] as Map).keys.map((k) => materialNames[k] ?? k).join(', ')}', style: const TextStyle(color: Colors.purple, fontSize: 13)),
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _monsters.length,
        itemBuilder: (context, i) {
          final m = _monsters[i];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.pets, color: Colors.redAccent, size: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('境界 Lv.${m.realm}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    ElevatedButton(onPressed: () => _battle(m), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFe94560)), child: const Text('挑战')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _stat('生命', m.hp, Colors.red),
                  _stat('攻击', m.atk, Colors.orange),
                  _stat('防御', m.def, Colors.blue),
                  _stat('经验', m.exp, Colors.green),
                  _stat('灵石', m.spiritStones, Colors.teal),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stat(String label, int value, Color color) => Column(children: [
        Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]);
}
