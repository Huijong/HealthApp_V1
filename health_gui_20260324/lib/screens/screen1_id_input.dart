import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Screen1IdInput extends StatefulWidget {
  const Screen1IdInput({super.key});

  @override
  State<Screen1IdInput> createState() => _Screen1IdInputState();
}

class _Screen1IdInputState extends State<Screen1IdInput> {
  final TextEditingController _idController = TextEditingController();
  final FocusNode _idFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _idFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _idFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ID 입력'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.account_circle,
                            size: 80,
                            color: primaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.fingerprint,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            '아이디',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextField(
                          focusNode: _idFocusNode,
                          autofocus: true,
                          controller: _idController,
                          decoration: InputDecoration(
                            hintText: '아이디를 입력하세요',
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '해당 앱에서 사용할 아이디를 입력해 주세요.',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final userId = _idController.text.trim();
                    if (userId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('아이디를 입력해 주세요.')));
                      return;
                    }
                    bool exists = false;
                    try {
                      final apiKey = 'my_private_key_50';
                      final res = await http.get(Uri.parse('https://health-port.work/check-user/$userId'));
                      if (res.statusCode == 200) {
                        final data = jsonDecode(res.body);
                        exists = data['exists'] ?? false;
                      }
                    } catch(e) {
                      debugPrint('Error checking user: $e');
                    }

                    if (!context.mounted) return;

                    if (exists) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('💡 기존 아이디 발견', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          content: Text('\'$userId\'(으)로 등록된 기록이 이미 서버에 존재합니다.\n그래도 이 아이디를 그대로 사용하시겠습니까?', style: const TextStyle(height: 1.5)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('취소', style: TextStyle(color: Colors.grey)),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('Id', userId);
                                await prefs.setBool('isSetupComplete', true);
                                if (context.mounted) Navigator.pushReplacementNamed(context, '/screen5');
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('진행하기'),
                            ),
                          ],
                        )
                      );
                    } else {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('Id', userId);
                      if (context.mounted) Navigator.pushNamed(context, '/screen2');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    '저장하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
