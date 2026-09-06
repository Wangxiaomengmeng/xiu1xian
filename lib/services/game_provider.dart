import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class GameProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  Player? _player;
  UserInfo? _userInfo;
  bool _loading = false;
  String? _error;

  Player? get player => _player;
  UserInfo? get userInfo => _userInfo;
  bool get loading => _loading;
  String? get error => _error;
  ApiService get api => _api;

  Future<void> loadAll() async {
    await Future.wait([loadPlayer(), loadUserInfo()]);
  }

  Future<void> loadPlayer() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _player = await _api.getPlayer();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserInfo() async {
    try {
      _userInfo = await _api.getMe();
      notifyListeners();
    } catch (_) {}
  }

  void setUserInfo(UserInfo info) {
    _userInfo = info;
    notifyListeners();
  }

  void setPlayer(Player p) {
    _player = p;
    notifyListeners();
  }

  void updateFromResponse(Map<String, dynamic> resp) {
    if (resp.containsKey('player') && resp['player'] is Map) {
      _player = Player.fromJson(resp['player']);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.logout();
    _player = null;
    _userInfo = null;
    notifyListeners();
  }
}
