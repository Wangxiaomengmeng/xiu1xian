import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentCtrl = TextEditingController();
  final List<File> _images = [];
  final List<String?> _imageMimeTypes = [];
  File? _video;
  String? _videoMimeType;
  bool _submitting = false;

  Future<void> _pickImages() async {
    if (_images.length >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('最多上传9张图片')));
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(maxWidth: 1024, imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        for (final f in picked) {
          if (_images.length < 9) {
            _images.add(File(f.path));
            _imageMimeTypes.add(f.mimeType);
          }
        }
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
    if (picked != null) {
      setState(() {
        _video = File(picked.path);
        _videoMimeType = picked.mimeType;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _imageMimeTypes.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty && _images.isEmpty && _video == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入内容或添加图片/视频')));
      return;
    }
    setState(() => _submitting = true);
    final api = context.read<GameProvider>().api;
    try {
      // 先上传图片
      List<String> imageUrls = [];
      for (var i = 0; i < _images.length; i++) {
        final url = await api.uploadImage(_images[i], mimeType: _imageMimeTypes[i]);
        if (url != null) imageUrls.add(url);
      }
      // 上传视频
      String? videoUrl;
      if (_video != null) {
        videoUrl = await api.uploadVideo(_video!, mimeType: _videoMimeType);
      }
      // 发布帖子
      final resp = await api.createPost(content, images: imageUrls, video: videoUrl);
      if (resp['error'] != null) throw Exception(resp['error']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('发布成功')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发布失败: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('发布帖子', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('发布', style: TextStyle(color: Color(0xFFe94560), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentCtrl,
              maxLines: 8,
              maxLength: 2000,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                hintText: '分享你的修仙心得...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            // 图片预览
            if (_images.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: _images.length + (_images.length < 9 ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _images.length) {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24, style: BorderStyle.solid)),
                        child: const Center(child: Icon(Icons.add, color: Colors.white38, size: 30)),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_images[i], fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(i),
                          child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 14)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            // 视频预览
            if (_video != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 160,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                child: Stack(
                  children: [
                    const Center(child: Icon(Icons.play_circle_fill, color: Colors.white54, size: 50)),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _video = null;
                          _videoMimeType = null;
                        }),
                        child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // 工具栏
            Row(
              children: [
                _toolButton(Icons.photo_library, '图片', _pickImages, Colors.blue),
                const SizedBox(width: 16),
                _toolButton(Icons.videocam, '视频', _pickVideo, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
