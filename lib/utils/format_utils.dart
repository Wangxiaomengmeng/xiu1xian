class FormatUtils {
  static String formatNumber(int n) {
    if (n >= 100000000) {
      return '${(n / 100000000).toStringAsFixed(2)}亿';
    } else if (n >= 10000) {
      return '${(n / 10000).toStringAsFixed(2)}万';
    }
    return n.toString();
  }

  static String realmColor(String realm) {
    final colors = {
      '炼气期': '0xFF9E9E9E',
      '筑基期': '0xFF4CAF50',
      '金丹期': '0xFFFFC107',
      '元婴期': '0xFF2196F3',
      '化神期': '0xFF9C27B0',
      '炼虚期': '0xFFFF5722',
      '合体期': '0xFFE91E63',
      '大乘期': '0xFF00BCD4',
      '渡劫期': '0xFFFF9800',
      '仙人': '0xFFFFD700',
    };
    return colors[realm] ?? '0xFFFFFFFF';
  }
}
