import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Screen5ActivityList extends StatefulWidget {
  const Screen5ActivityList({super.key});

  @override
  State<Screen5ActivityList> createState() => _Screen5ActivityListState();
}

class _Screen5ActivityListState extends State<Screen5ActivityList> {
  Map<String, int> _badgeCounts = {
    '러닝머신 걷기': 0,
    '러닝머신 달리기': 0,
    '야외 걷기': 0,
    '야외 달리기': 0,
  };

  bool _hasNewNotice = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _checkNotice();
  }

  Future<void> _checkNotice() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hasNewNotice = prefs.getBool('has_new_notice') ?? false;
      });
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // 백그라운드 서비스에서 저장한 최신 데이터 디스크 갱신
    String historyStr = prefs.getString('upload_history') ?? '[]';
    List<dynamic> historyList = jsonDecode(historyStr);
    
    Map<String, int> counts = {
      '러닝머신 걷기': 0,
      '러닝머신 달리기': 0,
      '야외 걷기': 0,
      '야외 달리기': 0,
    };

    for (var item in historyList) {
      if (item['isSuccess'] == true) {
        String activityName = item['activityName']?.toString() ?? 'Unknown';
        if (counts.containsKey(activityName)) {
          counts[activityName] = counts[activityName]! + 1;
        }
      }
    }

    if (mounted) {
      setState(() {
        _badgeCounts = counts;
      });
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
        title: const Text('결과 제출'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/screen9'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice Card
              Container(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(isDark ? 0.3 : 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.campaign, color: primaryColor),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '공지 사항',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isDark ? Colors.white : Colors.grey[900],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_hasNewNotice)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'NEW',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'NOTICE & UPDATES',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: isDark ? Colors.grey[500] : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('has_new_notice', false);
                        if (mounted) setState(() => _hasNewNotice = false);
                        if (mounted) Navigator.pushNamed(context, '/screen7');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text('보기', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  'Exercise List',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildActivityItem(
                context,
                icon: Icons.directions_walk,
                title: '러닝머신 걷기',
                subtitle: 'Treadmill Walking',
                badgeCount: _badgeCounts['러닝머신 걷기'] ?? 0,
                theme: theme,
              ),
              const SizedBox(height: 16),
              _buildActivityItem(
                context,
                icon: Icons.directions_run,
                title: '러닝머신 달리기',
                subtitle: 'Treadmill Running',
                badgeCount: _badgeCounts['러닝머신 달리기'] ?? 0,
                theme: theme,
              ),
              const SizedBox(height: 16),
              _buildActivityItem(
                context,
                icon: Icons.nature_people,
                title: '야외 걷기',
                subtitle: 'Outdoor Walking',
                badgeCount: _badgeCounts['야외 걷기'] ?? 0,
                theme: theme,
              ),
              const SizedBox(height: 16),
              _buildActivityItem(
                context,
                icon: Icons.directions_run,
                title: '야외 달리기',
                subtitle: 'Outdoor Running',
                badgeCount: _badgeCounts['야외 달리기'] ?? 0,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int badgeCount,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (badgeCount > 0)
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/screen8', arguments: title),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              if (badgeCount > 0)
                const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/screen6', arguments: title);
                  if (mounted) {
                    _loadHistory();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 0,
                ),
                child: const Text('제출', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
