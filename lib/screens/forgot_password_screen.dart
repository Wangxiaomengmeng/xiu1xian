import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = '请输入邮箱地址');
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _error = '邮箱格式不正确');
      return;
    }
    setState(() => _error = null);
    final provider = context.read<GameProvider>();
    try {
      final resp = await provider.api.sendCode(email, type: 'reset');
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
    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final newPwd = _newPwdCtrl.text;
    final confirmPwd = _confirmPwdCtrl.text;

    if (email.isEmpty || code.isEmpty || newPwd.isEmpty) {
      setState(() => _error = '请填写完整信息');
      return;
    }
    if (newPwd.length < 6) {
      setState(() => _error = '新密码长度不能少于6位');
      return;
    }
    if (newPwd != confirmPwd) {
      setState(() => _error = '两次输入的密码不一致');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final provider = context.read<GameProvider>();
    try {
      final resp = await provider.api.resetPassword(email, code, newPwd);
      if (resp['error'] != null) {
        setState(() => _error = resp['error']);
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1a1a2e),
              title: const Text('密码重置成功', style: TextStyle(color: Colors.green)),
              content: Text(resp['message'] ?? '请使用新密码登录', style: const TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('返回登录'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _error = '网络错误，请检查后端服务');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('找回密码', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.lock_reset, size: 50, color: Color(0xFFe94560)),
            const SizedBox(height: 16),
            const Text('通过邮箱重置密码', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('请输入注册时使用的邮箱，我们将发送验证码到您的邮箱', style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 30),
            _buildTextField(_emailCtrl, '注册邮箱', Icons.email_outlined),
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
            const SizedBox(height: 14),
            _buildTextField(_newPwdCtrl, '新密码（至少6位）', Icons.lock_outline, obscure: true),
            const SizedBox(height: 14),
            _buildTextField(_confirmPwdCtrl, '确认新密码', Icons.lock_outline, obscure: true),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                    : const Text('重置密码', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4)),
              ),
            ),
          ],
        ),
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
