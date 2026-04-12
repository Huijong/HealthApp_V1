import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Screen7Notices extends StatefulWidget {
  const Screen7Notices({super.key});

  @override
  State<Screen7Notices> createState() => _Screen7NoticesState();
}

class _Screen7NoticesState extends State<Screen7Notices> {
  List<dynamic> _notices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    try {
      final res = await http.get(Uri.parse('https://health-port.work/notices'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _notices = data['data'];
            _isLoading = false;
          });
          return;
        }
      }
    } catch(e) {
      debugPrint("공지사항 불러오기 에러: $e");
    }
    setState(() => _isLoading = false);
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
        title: const Text('공지 사항'),
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _notices.isEmpty 
            ? Center(
                child: Text(
                  '등록된 공지사항이 없습니다.',
                  style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                )
              )
            : RefreshIndicator(
                onRefresh: _fetchNotices,
                color: primaryColor,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  itemCount: _notices.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final notice = _notices[index];
                    return _buildNoticeCard(
                      title: notice['title'] ?? '제목 없음',
                      body: notice['body'] ?? '',
                      date: notice['created_at'] ?? '',
                      theme: theme,
                      isDark: isDark,
                      primaryColor: primaryColor,
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildNoticeCard({
    required String title,
    required String body,
    required String date,
    required ThemeData theme,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Update',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[400]),
            ),
            const SizedBox(width: 8),
            Text(
              date,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
