import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/game_provider.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Pill> _pills = [];
  List<Technique> _techniques = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final api = context.read<GameProvider>().api;
    try {
      final results = await Future.wait([api.getPills(), api.getTechniques()]);
      setState(() {
        _pills = results[0] as List<Pill>;
        _techniques = results[1] as List<Technique>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _buyPill(Pill pill) async {
    final provider = context.read<GameProvider>();
    try {
      final resp = await provider.api.buyPill(pill.id);
      await provider.loadPlayer();
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'])));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _learnTech(Technique tech) async {
    final provider = context.read<GameProvider>();
    try {
      final resp = await provider.api.learnTechnique(tech.id);
      await provider.loadPlayer();
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'])));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _equipTech(Technique tech) async {
    final provider = context.read<GameProvider>();
    try {
      final resp = await provider.api.equipTechnique(tech.id);
      await provider.loadPlayer();
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'])));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFFe94560),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFFe94560),
          tabs: const [Tab(text: '丹药阁'), Tab(text: '功法殿')],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabCtrl,
                  children: [_buildPillsTab(), _buildTechniquesTab()],
                ),
        ),
      ],
    );
  }

  Widget _buildPillsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pills.length,
      itemBuilder: (context, i) {
        final p = _pills[i];
        return Card(
          color: Colors.white.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.medication, color: Colors.greenAccent),
            ),
            title: Row(
              children: [
                Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text(p.grade, style: const TextStyle(color: Colors.amber, fontSize: 10)),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text('拥有: ${p.owned} 颗', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${p.cost} 灵石', style: const TextStyle(color: Colors.teal, fontSize: 12)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    onPressed: () => _buyPill(p),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), backgroundColor: const Color(0xFFe94560)),
                    child: const Text('购买', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTechniquesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _techniques.length,
      itemBuilder: (context, i) {
        final t = _techniques[i];
        return Card(
          color: Colors.white.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.menu_book, color: Colors.purpleAccent),
            ),
            title: Row(
              children: [
                Text(t.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: Colors.purple.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                  child: Text(t.grade, style: const TextStyle(color: Colors.purpleAccent, fontSize: 10)),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text('威力加成: +${t.power}%', style: const TextStyle(color: Colors.orange, fontSize: 11)),
              ],
            ),
            trailing: t.equipped
                ? const Text('修炼中', style: TextStyle(color: Colors.green, fontSize: 12))
                : t.learned
                    ? SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          onPressed: () => _equipTech(t),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), backgroundColor: Colors.blue),
                          child: const Text('修炼', style: TextStyle(fontSize: 11)),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${t.cost} 灵石', style: const TextStyle(color: Colors.teal, fontSize: 12)),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: () => _learnTech(t),
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), backgroundColor: const Color(0xFFe94560)),
                              child: const Text('学习', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
          ),
        );
      },
    );
  }
}
