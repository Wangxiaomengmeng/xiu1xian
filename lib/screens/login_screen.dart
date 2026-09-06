import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = '请先输入邮箱地址');
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _error = '邮箱格式不正确');
      return;
    }
    setState(() => _error = null);
    final provider = context.read<GameProvider>();
    try {
      final resp = await provider.api.sendCode(email, type: 'register');
      if (resp['error'] != null) {
        setState(() => _error = resp['error']);
      } else {
        setState(() => _countdown = 60);
        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() {
            _countdown--;
            if (_countdown <= 0) t.cancel();
          });
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'] ?? '验证码已发送')));
      }
    } catch (e) {
      setState(() => _error = '网络错误，请检查后端服务');
    }
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入道号和密码');
      return;
    }
    if (!_isLogin) {
      final email = _emailCtrl.text.trim();
      final code = _codeCtrl.text.trim();
      if (email.isEmpty) {
        setState(() => _error = '请输入邮箱地址');
        return;
      }
      if (code.isEmpty) {
        setState(() => _error = '请输入邮箱验证码');
        return;
      }
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final provider = context.read<GameProvider>();
    try {
      final resp = _isLogin
          ? await provider.api.login(username, password)
          : await provider.api.register(username, password, _emailCtrl.text.trim(), _codeCtrl.text.trim());
      if (resp.containsKey('token')) {
        await provider.loadAll();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        setState(() => _error = resp['error'] ?? '操作失败');
      }
    } catch (e) {
      setState(() => _error = '网络错误，请检查后端服务是否启动');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.self_improvement, size: 70, color: Color(0xFFe94560)),
                  const SizedBox(height: 12),
                  const Text('修仙录', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8)),
                  const Text('踏入仙途，问鼎长生', style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 4)),
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(25)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _tabButton('登录', _isLogin),
                        _tabButton('注册', !_isLogin),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(_usernameCtrl, '道号（用户名）', Icons.person_outline),
                  const SizedBox(height: 14),
                  _buildTextField(_passwordCtrl, '密码', Icons.lock_outline, obscure: true),
                  if (!_isLogin) ...[
                    const SizedBox(height: 14),
                    _buildTextField(_emailCtrl, '邮箱地址', Icons.email_outlined),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_codeCtrl, '邮箱验证码', Icons.verified_outlined)),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _countdown > 0 ? null : _sendCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _countdown > 0 ? Colors.grey : const Color(0xFFe94560),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(_countdown > 0 ? '${_countdown}s' : '获取验证码', style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFe94560),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isLogin ? '登 录' : '注 册', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(_isLogin ? '没有账号？立即注册' : '已有账号？返回登录', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ),
                      if (_isLogin)
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                          child: const Text('忘记密码？', style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String text, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _isLogin = text == '登录'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFe94560) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(text, style: TextStyle(color: active ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: hint.contains('邮箱') ? TextInputType.emailAddress : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe94560), width: 1.5)),
      ),
    );
  }
}
