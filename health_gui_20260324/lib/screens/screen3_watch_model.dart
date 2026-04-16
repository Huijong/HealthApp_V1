import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Screen3WatchModel extends StatefulWidget {
  const Screen3WatchModel({super.key});

  @override
  State<Screen3WatchModel> createState() => _Screen3WatchModelState();
}

class _Screen3WatchModelState extends State<Screen3WatchModel> {
  String _selectedModel = 'Watch8 Classic';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString('selectedWatchModel');
    if (savedModel != null && savedModel.isNotEmpty) {
      setState(() {
        _selectedModel = savedModel;
      });
    }
  }

  final List<Map<String, String>> _models = [
    {
      'title': 'Watch9 44mm',
      'subtitle': 'Latest active style with large display',
    },
    {
      'title': 'Watch9 40mm',
      'subtitle': 'Latest compact and lightweight design',
    },
    {
      'title': 'Watch Ultra 2',
      'subtitle': 'Next generation maximum endurance and performance',
    },
    {
      'title': 'Watch8 Classic',
      'subtitle': 'Classic design with rotating bezel',
    },
    {
      'title': 'Watch8 44mm',
      'subtitle': 'Large display for active lifestyle',
    },
    {
      'title': 'Watch8 40mm',
      'subtitle': 'Compact and lightweight design',
    },
    {
      'title': 'Watch7 44mm',
      'subtitle': 'Active style with large display',
    },
    {
      'title': 'Watch Ultra 1',
      'subtitle': 'Maximum endurance and performance',
    },
  ];

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
        title: const Text('워치 선택'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          itemCount: _models.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final model = _models[index];
            final isSelected = _selectedModel == model['title'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedModel = model['title']!;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? primaryColor.withOpacity(0.6) : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model['title']!,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.grey[900],
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            model['subtitle']!,
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? primaryColor : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
                          width: 2,
                        ),
                        color: isSelected ? primaryColor : Colors.transparent,
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withOpacity(0.9),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selectedWatchModel', _selectedModel);
                
                if (!context.mounted) return;
                
                final bool isSetupComplete = prefs.getBool('isSetupComplete') ?? false;
                if (isSetupComplete) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushNamed(context, '/screen4');
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
              child: const Text('선택 완료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
