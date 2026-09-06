import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/format_utils.dart';

class PlayerStatusBar extends StatelessWidget {
  final Player player;
  const PlayerStatusBar({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(int.parse(FormatUtils.realmColor(player.realm))).withOpacity(0.3),
            Colors.deepPurple.shade900.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Color(int.parse(FormatUtils.realmColor(player.realm))).withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    player.username,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Color(int.parse(FormatUtils.realmColor(player.realm))),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  player.realm,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildBar('生命', player.hp, player.maxHp, Colors.red, Icons.favorite),
          const SizedBox(height: 6),
          _buildBar('体力', player.stamina, player.maxStamina, Colors.green, Icons.bolt),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _attrItem('攻击', player.atk, Icons.flash_on, Colors.orange),
              _attrItem('防御', player.def, Icons.shield, Colors.blue),
              _attrItem('战力', player.power, Icons.bolt, Colors.yellow),
              _attrItem('灵石', player.spiritStones, Icons.monetization_on, Colors.teal),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '修为: ${FormatUtils.formatNumber(player.cultivation)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, int current, int max, Color color, IconData icon) {
    final ratio = max > 0 ? current / max : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text('$label $current/$max', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _attrItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(
          FormatUtils.formatNumber(value),
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}
