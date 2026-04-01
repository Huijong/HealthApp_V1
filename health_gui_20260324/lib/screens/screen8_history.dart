import 'package:flutter/material.dart';

class Screen8History extends StatefulWidget {
  const Screen8History({super.key});

  @override
  State<Screen8History> createState() => _Screen8HistoryState();
}

class _Screen8HistoryState extends State<Screen8History> {
  final List<Map<String, dynamic>> _historyData = [
    {
      'id': '1',
      'type': 'Success',
      'date': '2024.03.15 14:30',
      'tags': ['인터벌', '왼쪽', '충분히'],
      'durationStr': 'Duration: 45m 12s • 3.2 km',
      'fileSize': '2.4 MB',
      'isSuccess': true,
    },
    {
      'id': '2',
      'type': 'Success',
      'date': '2024.03.12 09:15',
      'tags': ['조깅', '오른쪽', '적당히'],
      'durationStr': 'Duration: 30m 00s • 2.1 km',
      'fileSize': '1.8 MB',
      'isSuccess': true,
    },
    {
      'id': '3',
      'type': 'Submitted',
      'date': '2024.03.10 18:45',
      'tags': ['지속주', '왼쪽', '느슨하게'],
      'durationStr': 'Pending processing...',
      'fileSize': '2.1 MB',
      'isSuccess': false,
      'opacity': 0.6,
    },
    {
      'id': '4',
      'type': 'Success',
      'date': '2024.03.08 07:00',
      'tags': ['인터벌', '오른쪽', '충분히'],
      'durationStr': 'Duration: 60m 05s • 4.5 km',
      'fileSize': '3.4 MB',
      'isSuccess': true,
    },
    {
      'id': '5',
      'type': 'Success',
      'date': '2024.03.05 12:20',
      'tags': ['조깅', '왼쪽', '적당히'],
      'durationStr': 'Duration: 20m 15s • 1.5 km',
      'fileSize': '1.2 MB',
      'isSuccess': true,
    },
  ];

  void _deleteHistory(String id) {
    setState(() {
      _historyData.removeWhere((item) => item['id'] == id);
    });
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
        title: const Text('운동 히스토리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Submissions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${_historyData.length}',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      color: isDark ? Colors.white : Colors.grey[900],
                      letterSpacing: -2.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sessions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              ..._historyData.map((data) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildHistoryCard(
                    id: data['id'],
                    type: data['type'],
                    date: data['date'],
                    tags: List<String>.from(data['tags']),
                    durationStr: data['durationStr'],
                    fileSize: data['fileSize'],
                    isSuccess: data['isSuccess'],
                    theme: theme,
                    isDark: isDark,
                    primaryColor: primaryColor,
                    opacity: data['opacity'] ?? 1.0,
                  ),
                );
              }),

              const SizedBox(height: 48),
              
              Center(
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: Text(
                    'VIEW OLDER RECORDS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required String id,
    required String type,
    required String date,
    required List<String> tags,
    required String durationStr,
    required String fileSize,
    required bool isSuccess,
    required ThemeData theme,
    required bool isDark,
    required Color primaryColor,
    double opacity = 1.0,
  }) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteHistory(id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
      ),
      child: Opacity(
        opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.white,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.schedule,
                        color: isSuccess ? primaryColor : (isDark ? Colors.grey[500] : Colors.grey[400]),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSuccess ? primaryColor : (isDark ? Colors.grey[500] : Colors.grey[400]),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.asMap().entries.map((entry) {
                      final isFirst = entry.key == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFirst
                              ? (isSuccess ? primaryColor.withOpacity(0.1) : (isDark ? Colors.grey[700] : Colors.grey[200]))
                              : (isDark ? Colors.grey[800] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isFirst
                                ? (isSuccess ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[600]))
                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    durationStr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontStyle: isSuccess ? FontStyle.normal : FontStyle.italic,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'FILE SIZE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fileSize,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 12),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: isDark ? Colors.grey[500] : Colors.grey[400], size: 24),
                  onPressed: () => _deleteHistory(id),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
