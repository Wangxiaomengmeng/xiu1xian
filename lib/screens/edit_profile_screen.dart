import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/game_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nicknameCtrl = TextEditingController();
  File? _avatarFile;
  String? _existingAvatar;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GameProvider>();
    _nicknameCtrl.text = provider.userInfo?.nickname ?? '';
    _existingAvatar = provider.userInfo?.avatar;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    final nickname = _nicknameCtrl.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('昵称不能为空')));
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<GameProvider>();
    try {
      // 先改昵称
      final resp = await provider.api.updateNickname(nickname);
      if (resp['error'] != null) throw Exception(resp['error']);
      // 再上传头像（如果选了新的）
      if (_avatarFile != null) {
        final avatarResp = await provider.api.uploadAvatar(_avatarFile!);
        if (avatarResp['error'] != null) throw Exception(avatarResp['error']);
      }
      await provider.loadUserInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final avatarUrl = provider.userInfo?.avatar;

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('编辑资料', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 头像
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFe94560), width: 2),
                    ),
                    child: ClipOval(
                      child: _avatarFile != null
                          ? Image.file(_avatarFile!, fit: BoxFit.cover)
                          : (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: provider.api.fullUrl(avatarUrl),
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (_, __, ___) => _defaultAvatar(),
                                )
                              : _defaultAvatar(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFFe94560), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('点击更换头像', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 32),
            // 昵称
            TextField(
              controller: _nicknameCtrl,
              style: const TextStyle(color: Colors.white),
              maxLength: 20,
              decoration: InputDecoration(
                labelText: '昵称',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFe94560), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 道号（不可改）
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Text('道号（登录账号）', style: TextStyle(color: Colors.white54)),
                  const Spacer(),
                  Text(provider.userInfo?.username ?? '', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe94560),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('保 存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.deepPurple,
      child: const Icon(Icons.person, color: Colors.white, size: 50),
    );
  }
}
