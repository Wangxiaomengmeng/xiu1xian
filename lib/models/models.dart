class UserInfo {
  final int id;
  final String username;
  final String nickname;
  final String? avatar;
  final String? createdAt;
  final String? lastLogin;

  UserInfo({
    required this.id,
    required this.username,
    required this.nickname,
    this.avatar,
    this.createdAt,
    this.lastLogin,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      username: json['username'],
      nickname: json['nickname'] ?? json['username'],
      avatar: json['avatar'],
      createdAt: json['created_at'],
      lastLogin: json['last_login'],
    );
  }
}

class Player {
  final String username;
  final int cultivation;
  final String realm;
  final int realmLevel;
  final int hp;
  final int maxHp;
  final int atk;
  final int def;
  final int spiritStones;
  final int stamina;
  final int maxStamina;
  final String technique;
  final List<String> learnedTechniques;
  final Map<String, int> inventory;
  final Map<String, int> materials;
  final Map<String, dynamic>? equipment;
  final List<String> ownedEquipments;
  final int power;
  final double breakthroughChance;
  final int breakthroughBonus;
  final int alchemyLevel;
  final int alchemyExp;
  final Map<String, dynamic> stats;

  Player({
    required this.username,
    required this.cultivation,
    required this.realm,
    required this.realmLevel,
    required this.hp,
    required this.maxHp,
    required this.atk,
    required this.def,
    required this.spiritStones,
    this.stamina = 100,
    this.maxStamina = 100,
    required this.technique,
    required this.learnedTechniques,
    required this.inventory,
    this.materials = const {},
    this.equipment,
    this.ownedEquipments = const [],
    this.power = 0,
    this.breakthroughChance = 0,
    this.breakthroughBonus = 0,
    this.alchemyLevel = 1,
    this.alchemyExp = 0,
    this.stats = const {},
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      username: json['username'] ?? '',
      cultivation: (json['cultivation'] ?? 0).toInt(),
      realm: json['realm'] ?? '炼气期',
      realmLevel: (json['realmLevel'] ?? 1).toInt(),
      hp: (json['hp'] ?? 100).toInt(),
      maxHp: (json['maxHp'] ?? 100).toInt(),
      atk: (json['atk'] ?? 10).toInt(),
      def: (json['def'] ?? 5).toInt(),
      spiritStones: (json['spiritStones'] ?? 0).toInt(),
      stamina: (json['stamina'] ?? 100).toInt(),
      maxStamina: (json['maxStamina'] ?? 100).toInt(),
      technique: json['technique'] ?? 'basic',
      learnedTechniques: List<String>.from(json['learnedTechniques'] ?? ['basic']),
      inventory: Map<String, int>.from((json['inventory'] ?? {}).map((k, v) => MapEntry(k, v.toInt()))),
      materials: Map<String, int>.from((json['materials'] ?? {}).map((k, v) => MapEntry(k, v.toInt()))),
      equipment: json['equipment'] != null ? Map<String, dynamic>.from(json['equipment']) : null,
      ownedEquipments: List<String>.from(json['ownedEquipments'] ?? []),
      power: (json['power'] ?? 0).toInt(),
      breakthroughChance: (json['breakthroughChance'] ?? 0).toDouble(),
      breakthroughBonus: (json['breakthroughBonus'] ?? 0).toInt(),
      alchemyLevel: (json['alchemyLevel'] ?? 1).toInt(),
      alchemyExp: (json['alchemyExp'] ?? 0).toInt(),
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
    );
  }
}

class Monster {
  final String id;
  final String name;
  final int realm;
  final int hp;
  final int atk;
  final int def;
  final int exp;
  final int spiritStones;
  final List<String>? drops;

  Monster({
    required this.id,
    required this.name,
    required this.realm,
    required this.hp,
    required this.atk,
    required this.def,
    required this.exp,
    required this.spiritStones,
    this.drops,
  });

  factory Monster.fromJson(Map<String, dynamic> json) {
    return Monster(
      id: json['id'],
      name: json['name'],
      realm: json['realm'],
      hp: json['hp'],
      atk: json['atk'],
      def: json['def'],
      exp: json['exp'],
      spiritStones: json['spiritStones'],
      drops: json['drops'] != null ? List<String>.from(json['drops']) : null,
    );
  }
}

class Pill {
  final String id;
  final String name;
  final String grade;
  final String effect;
  final int value;
  final int cost;
  final String desc;
  final List<String>? recipe;
  final int owned;

  Pill({
    required this.id,
    required this.name,
    required this.grade,
    required this.effect,
    required this.value,
    required this.cost,
    required this.desc,
    this.recipe,
    this.owned = 0,
  });

  factory Pill.fromJson(Map<String, dynamic> json) {
    return Pill(
      id: json['id'],
      name: json['name'],
      grade: json['grade'],
      effect: json['effect'],
      value: (json['value'] ?? 0).toInt(),
      cost: json['cost'],
      desc: json['desc'],
      recipe: json['recipe'] != null ? List<String>.from(json['recipe']) : null,
      owned: (json['owned'] ?? 0).toInt(),
    );
  }
}

class Technique {
  final String id;
  final String name;
  final String grade;
  final int power;
  final int cost;
  final String desc;
  final bool learned;
  final bool equipped;

  Technique({
    required this.id,
    required this.name,
    required this.grade,
    required this.power,
    required this.cost,
    required this.desc,
    this.learned = false,
    this.equipped = false,
  });

  factory Technique.fromJson(Map<String, dynamic> json) {
    return Technique(
      id: json['id'],
      name: json['name'],
      grade: json['grade'],
      power: json['power'],
      cost: json['cost'],
      desc: json['desc'],
      learned: json['learned'] ?? false,
      equipped: json['equipped'] ?? false,
    );
  }
}

class LeaderboardEntry {
  final String username;
  final String realm;
  final int cultivation;
  final int power;

  LeaderboardEntry({
    required this.username,
    required this.realm,
    required this.cultivation,
    required this.power,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      username: json['username'],
      realm: json['realm'],
      cultivation: (json['cultivation'] ?? 0).toInt(),
      power: (json['power'] ?? 0).toInt(),
    );
  }
}

class PostAuthor {
  final int id;
  final String username;
  final String nickname;
  final String? avatar;

  PostAuthor({required this.id, required this.username, required this.nickname, this.avatar});

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'],
      username: json['username'],
      nickname: json['nickname'] ?? json['username'],
      avatar: json['avatar'],
    );
  }
}

class Post {
  final int id;
  final String content;
  final List<String> images;
  final String? video;
  final int likeCount;
  final int commentCount;
  final String createdAt;
  final bool liked;
  final PostAuthor author;

  Post({
    required this.id,
    required this.content,
    required this.images,
    this.video,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.liked,
    required this.author,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      content: json['content'],
      images: List<String>.from(json['images'] ?? []),
      video: json['video'],
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      liked: json['liked'] ?? false,
      author: PostAuthor.fromJson(json['author']),
    );
  }
}

class Comment {
  final int id;
  final String content;
  final String createdAt;
  final PostAuthor author;

  Comment({required this.id, required this.content, required this.createdAt, required this.author});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      content: json['content'],
      createdAt: json['createdAt'] ?? '',
      author: PostAuthor.fromJson(json['author']),
    );
  }
}

class Dungeon {
  final String id;
  final String name;
  final int minRealm;
  final int staminaCost;
  final String boss;
  final bool unlocked;

  Dungeon({
    required this.id,
    required this.name,
    required this.minRealm,
    required this.staminaCost,
    required this.boss,
    this.unlocked = false,
  });

  factory Dungeon.fromJson(Map<String, dynamic> json) {
    return Dungeon(
      id: json['id'],
      name: json['name'],
      minRealm: json['minRealm'],
      staminaCost: json['staminaCost'],
      boss: json['boss'] ?? '',
      unlocked: json['unlocked'] ?? false,
    );
  }
}

class Equipment {
  final String id;
  final String name;
  final String type;
  final int atk;
  final int def;
  final int hp;
  final int cost;
  final String rarity;
  final bool owned;
  final bool equipped;

  Equipment({
    required this.id,
    required this.name,
    required this.type,
    required this.atk,
    required this.def,
    required this.hp,
    required this.cost,
    required this.rarity,
    this.owned = false,
    this.equipped = false,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      atk: json['atk'],
      def: json['def'],
      hp: json['hp'],
      cost: json['cost'],
      rarity: json['rarity'],
      owned: json['owned'] ?? false,
      equipped: json['equipped'] ?? false,
    );
  }
}
