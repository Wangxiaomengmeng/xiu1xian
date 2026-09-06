import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  // 后端服务地址
  static const String baseUrl = 'http://192.168.3.11:3000';
  // Android 模拟器访问本机后端用 10.0.2.2
  // static const String baseUrl = 'http://10.0.2.2:3000';

  String? _token;

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  String fullUrl(String path) => '$baseUrl$path';

  // ===== 认证 =====
  /// 发送邮箱验证码
  /// type: 'register' 注册, 'reset' 找回密码
  Future<Map<String, dynamic>> sendCode(String email, {String type = 'register'}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/send-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'type': type}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> register(String username, String password, String email, String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password, 'email': email, 'code': code}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['token'] != null) {
      _token = data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
    }
    return data;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['token'] != null) {
      _token = data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
    }
    return data;
  }

  /// 忘记密码 - 重置密码
  Future<Map<String, dynamic>> resetPassword(String email, String code, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}),
    );
    return jsonDecode(res.body);
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<bool> isLoggedIn() async {
    await _loadToken();
    return _token != null;
  }

  // ===== 用户资料 =====
  Future<UserInfo> getMe() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/api/auth/me'), headers: _headers);
    return UserInfo.fromJson(jsonDecode(res.body)['user']);
  }

  Future<Map<String, dynamic>> updateNickname(String nickname) async {
    await _loadToken();
    final res = await http.put(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: _headers,
      body: jsonEncode({'nickname': nickname}),
    );
    return jsonDecode(res.body);
  }

  /// 根据文件扩展名推断 MediaType，兜底为 image/jpeg
  MediaType _imageMediaType(String path, {String? mimeType}) {
    if (mimeType != null && mimeType.contains('/')) {
      final parts = mimeType.split('/');
      return MediaType(parts[0], parts.length > 1 ? parts[1] : '');
    }
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'bmp':
        return MediaType('image', 'bmp');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  MediaType _videoMediaType(String path, {String? mimeType}) {
    if (mimeType != null && mimeType.contains('/')) {
      final parts = mimeType.split('/');
      return MediaType(parts[0], parts.length > 1 ? parts[1] : '');
    }
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'mp4':
        return MediaType('video', 'mp4');
      case 'mov':
        return MediaType('video', 'quicktime');
      case 'avi':
        return MediaType('video', 'x-msvideo');
      case 'mkv':
        return MediaType('video', 'x-matroska');
      case 'webm':
        return MediaType('video', 'webm');
      default:
        return MediaType('video', 'mp4');
    }
  }

  Future<Map<String, dynamic>> uploadAvatar(File imageFile, {String? mimeType}) async {
    await _loadToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/auth/avatar'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(await http.MultipartFile.fromPath(
      'avatar',
      imageFile.path,
      contentType: _imageMediaType(imageFile.path, mimeType: mimeType),
    ));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body);
  }

  // ===== 玩家数据 =====
  Future<Player> getPlayer() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/api/game/player'), headers: _headers);
    if (res.statusCode == 401) throw Exception('未登录');
    return Player.fromJson(jsonDecode(res.body));
  }

  Future<Map<String, dynamic>> cultivate() async {
    await _loadToken();
    final res = await http.post(Uri.parse('$baseUrl/api/game/cultivate'), headers: _headers);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> breakthrough() async {
    await _loadToken();
    final res = await http.post(Uri.parse('$baseUrl/api/game/breakthrough'), headers: _headers);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> rest() async {
    await _loadToken();
    final res = await http.post(Uri.parse('$baseUrl/api/game/rest'), headers: _headers);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> offlineGain() async {
    await _loadToken();
    final res = await http.post(Uri.parse('$baseUrl/api/game/offline-gain'), headers: _headers);
    return jsonDecode(res.body);
  }

  // ===== 战斗 =====
  Future<List<Monster>> getMonsters() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/api/game/monsters'), headers: _headers);
    return (jsonDecode(res.body) as List).map((e) => Monster.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> battle(String monsterId) async {
    await _loadToken();
    final res = await http.post(Uri.parse('$baseUrl/api/game/battle/$monsterId'), headers: _headers);
    return jsonDecode(res.body);
  }

  // ===== 丹药 =====
  Future<List<Pill>> getPills() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/api/game/pills'), headers: _headers);
    return (jsonDecode(res.body) as List).map((e) => Pill.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> buyPill(String pillId) async {
    await _loadToken();
    final res = await http.post(Uri.parse('$baseUrl/api/game/buy-pill/$pillId'), headers: _headers);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> usePill(String pillId) async {
    await _loadToken();
    final res = await http.post(Uri.parse('$baseUrl/api/game/use-pill/$pillId'), headers: _headers);
    return jsonDecode(res.body);
  }

  // ===== 功法 =====
  Future<List<Technique>> getTechniques() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/api/game/techniques'), headers: _headers);
    return (jsonDecode(res.body) as List).map((e) => Technique.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> learnTechnique(String techId) async {
    await _loadToken();
    final res = await http.post(Uri.parse('$baseUrl/api/game/learn-technique/$techId'), headers: _headers);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> equipTechnique(String techId) async {
    await _loadToken();
    final res = await http.post(Uri.parse('$baseUrl/api/game/equip-technique/$techId'), headers: _headers);
    return jsonDecode(res.body);
  }

  // ===== 秘境 =====
  Future<List<Dungeon>> getDungeons() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/api/game/dungeons'), headers: _headers);
    return (jsonDecode(res.body) as List).map((e) => Dungeon.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> exploreDungeon(String dungeonId) async {
    await _loadToken();
    final res = await http.post(Uri.parse('$baseUrl/api/game/dungeon/$dungeonId'), headers: _headers);
    return jsonDecode(res.body);
  }

  // ===== 炼丹 =====
  Future<Map<String, dynamic>> getAlchemyMaterials() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/api/game/alchemy/materials'), headers: _headers);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> craftPill(String pillId) async {
    await _loadToken();
    final res = await http.post(Uri.parse('$baseUrl/api/game/alchemy/craft/$pillId'), headers: _headers);
    return jsonDecode(res.body);
  }

  // ===== 装备 =====
  Future<List<Equipment>> getEquipments() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/api/game/equipments'), headers: _headers);
    return (jsonDecode(res.body) as List).map((e) => Equipment.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> buyEquipment(String equipId) async {
    await _loadToken();
    final res = await http.post(Uri.parse('$baseUrl/api/game/buy-equipment/$equipId'), headers: _headers);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> equipItem(String equipId) async {
    await _loadToken();
    final res = await http.post(Uri.parse('$baseUrl/api/game/equip/$equipId'), headers: _headers);
    return jsonDecode(res.body);
  }

  // ===== 排行榜 =====
  Future<List<LeaderboardEntry>> getLeaderboard() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/api/game/leaderboard'), headers: _headers);
    return (jsonDecode(res.body) as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
  }

  // ===== 圈子 - 帖子 =====
  Future<Map<String, dynamic>> getPosts({int page = 1, int limit = 10, int? userId}) async {
    await _loadToken();
    final params = {'page': '$page', 'limit': '$limit'};
    if (userId != null) params['userId'] = '$userId';
    final uri = Uri.parse('$baseUrl/api/posts').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    return jsonDecode(res.body);
  }

  Future<Post> getPostDetail(int postId) async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/api/posts/$postId'), headers: _headers);
    return Post.fromJson(jsonDecode(res.body)['post']);
  }

  Future<Map<String, dynamic>> createPost(String content, {List<String> images = const [], String? video}) async {
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/posts'),
      headers: _headers,
      body: jsonEncode({'content': content, 'images': images, 'video': video}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> toggleLike(int postId) async {
    await _loadToken();
    final res = await http.post(Uri.parse('$baseUrl/api/posts/$postId/like'), headers: _headers);
    return jsonDecode(res.body);
  }

  Future<List<Comment>> getComments(int postId) async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/api/posts/$postId/comments'), headers: _headers);
    return (jsonDecode(res.body)['comments'] as List).map((e) => Comment.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> addComment(int postId, String content) async {
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/posts/$postId/comments'),
      headers: _headers,
      body: jsonEncode({'content': content}),
    );
    return jsonDecode(res.body);
  }

  // 上传图片返回URL
  Future<String?> uploadImage(File imageFile, {String? mimeType}) async {
    await _loadToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/posts/upload-image'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
      contentType: _imageMediaType(imageFile.path, mimeType: mimeType),
    ));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final data = jsonDecode(res.body);
    return data['url'];
  }

  // 上传视频返回URL
  Future<String?> uploadVideo(File videoFile, {String? mimeType}) async {
    await _loadToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/posts/upload-video'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(await http.MultipartFile.fromPath(
      'video',
      videoFile.path,
      contentType: _videoMediaType(videoFile.path, mimeType: mimeType),
    ));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final data = jsonDecode(res.body);
    return data['url'];
  }

  // ===== 公告 =====
  /// 获取最新公告（公开接口）
  Future<Map<String, dynamic>?> getLatestAnnouncement() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/announcements/latest'));
      final data = jsonDecode(res.body);
      return data['announcement'];
    } catch (_) {
      return null;
    }
  }
}
