import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/game_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Pill> _allPills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPills();
  }

  Future<void> _loadPills() async {
    try {
      final list = await context.read<GameProvider>().api.getPills();
      setState(() {
        _allPills = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _usePill(Pill pill) async {
    final provider = context.read<GameProvider>();
    try {
      final resp = await provider.api.usePill(pill.id);
      await provider.loadPlayer();
      await _loadPills();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'])));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<GameProvider>().player;
    if (_loading || player == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // 筛选出拥有的丹药
    final ownedPills = _allPills.where((p) => (player.inventory[p.id] ?? 0) > 0).toList();

    if (ownedPills.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.white24),
            SizedBox(height: 12),
            Text('背包空空如也', style: TextStyle(color: Colors.white38)),
            Text('去坊市购买丹药吧', style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: ownedPills.length,
      itemBuilder: (context, i) {
        final pill = ownedPills[i];
        final count = player.inventory[pill.id] ?? 0;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.medication, color: Colors.greenAccent, size: 32),
                  ),
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0xFFe94560), borderRadius: BorderRadius.circular(8)),
                      child: Text('x$count', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(pill.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(pill.grade, style: const TextStyle(color: Colors.amber, fontSize: 10)),
              const SizedBox(height: 4),
              Text(pill.desc, style: const TextStyle(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: () => _usePill(pill),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFe94560), padding: EdgeInsets.zero),
                  child: const Text('服用', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
