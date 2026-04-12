import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Screen10Admin extends StatefulWidget {
  const Screen10Admin({super.key});

  @override
  State<Screen10Admin> createState() => _Screen10AdminState();
}

class _Screen10AdminState extends State<Screen10Admin> {
  bool _isPasswordVisible = false;
  int _deviceCount = 0;
  bool _isLoadingCount = true;

  List<dynamic> _notices = [];
  bool _isLoadingNotices = true;
  String _lastSavedTime = '';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDeviceCount();
    _loadSavedPassword();
    _loadDraft();
    _fetchNotices();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _titleController.text = prefs.getString('draft_title') ?? '';
        _bodyController.text = prefs.getString('draft_body') ?? '';
        _lastSavedTime = prefs.getString('draft_time') ?? '';
      });
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_title', _titleController.text);
    await prefs.setString('draft_body', _bodyController.text);
    
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await prefs.setString('draft_time', timeStr);
    
    if (mounted) {
      setState(() => _lastSavedTime = timeStr);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('기기에 임시 저장되었습니다.')));
    }
  }

  Future<void> _fetchNotices() async {
    try {
      final res = await http.get(Uri.parse('https://health-port.work/notices'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              _notices = data['data'];
              _isLoadingNotices = false;
            });
          }
          return;
        }
      }
    } catch(e) {
      debugPrint("공지 목록 불러오기 실패: $e");
    }
    if (mounted) setState(() => _isLoadingNotices = false);
  }

  Future<void> _loadSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPwd = prefs.getString('admin_pwd');
    if (savedPwd != null && savedPwd.isNotEmpty && mounted) {
      setState(() {
        _pwController.text = savedPwd;
      });
    }
  }

  Future<void> _fetchDeviceCount() async {
    try {
      final res = await http.get(Uri.parse('https://health-port.work/admin/device-count'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _deviceCount = data['device_count'] ?? 0;
            _isLoadingCount = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingCount = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCount = false);
    }
  }

  Future<void> _sendPushNotice() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final pwd = _pwController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요.')));
      return;
    }

    try {
      // Cloudflare Tunnels public domain
      final res = await http.post(
        Uri.parse('https://health-port.work/admin/send-notice'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': pwd,
        },
        body: jsonEncode({'title': title, 'body': body}),
      );
      if (res.statusCode == 200) {
        // 성공 시 텍스트 지우기 및 비밀번호 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_pwd', pwd);

        if (!mounted) return;
        _titleController.clear();
        _bodyController.clear();
        
        final clearPrefs = await SharedPreferences.getInstance();
        await clearPrefs.remove('draft_title');
        await clearPrefs.remove('draft_body');
        await clearPrefs.remove('draft_time');
        setState(() => _lastSavedTime = '');

        // 방금 작성한 공지가 포함되도록 새로고침
        _fetchNotices();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('💡 전송 성공'),
            content: const Text('모든 기기로 푸시 알림이 정상적으로 전송되었습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('전송 실패: ${res.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('네트워크 오류: $e')));
    }
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
        title: const Text('관리자 모드'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice Management Card
              _buildCardWrapper(
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.campaign, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '공지사항 관리',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '공지 제목',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: '예: 헬스 버전 업데이트',
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '내용 본문',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bodyController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: '공지할 내용을 여기에 입력하세요.',
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _saveDraft,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor.withOpacity(0.1),
                            foregroundColor: primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text('임시 저장', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        if (_lastSavedTime.isNotEmpty)
                          Text(
                            '마지막 저장: $_lastSavedTime',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Push Notification Card
              _buildCardWrapper(
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.send_to_mobile, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '푸시 알림',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '수신 대상자 그룹',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                        Text(
                          '모든 활성 사용자',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isLoadingCount ? '계산 중...' : '$_deviceCount개 기기',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                          ),
                          Icon(Icons.groups, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '관리자 비밀번호 (API Key)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pwController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: '비밀번호를 입력하세요',
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _sendPushNotice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('알림 보내기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            const Icon(Icons.send),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // KPI Card
              _buildCardWrapper(
                theme: theme,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '전송 성공률',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '98.2%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(width: 8, height: 8, color: primaryColor),
                        const SizedBox(width: 4),
                        Container(width: 8, height: 8, color: primaryColor),
                        const SizedBox(width: 4),
                        Container(width: 8, height: 8, color: primaryColor),
                        const SizedBox(width: 4),
                        Container(width: 8, height: 8, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // History list etc.
              _buildCardWrapper(
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.list_alt, color: primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '공지사항 히스토리',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_isLoadingNotices)
                      const Center(child: CircularProgressIndicator())
                    else if (_notices.isEmpty)
                      const Text('공지 기록이 없습니다.')
                    else
                      ..._notices.take(5).map((notice) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildHistoryItem(
                            tag: 'Sent',
                            tagColor: primaryColor,
                            title: notice['title'] ?? '제목 없음',
                            time: notice['created_at'] ?? '',
                            status: '성공률 100%',
                            theme: theme,
                            isDark: isDark,
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardWrapper({required ThemeData theme, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHistoryItem({
    required String tag,
    required Color tagColor,
    required String title,
    required String time,
    required String status,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tagColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tag.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: tagColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
