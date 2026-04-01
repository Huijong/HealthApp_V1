import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Screen2BodyInfo extends StatefulWidget {
  const Screen2BodyInfo({super.key});

  @override
  State<Screen2BodyInfo> createState() => _Screen2BodyInfoState();
}

class _Screen2BodyInfoState extends State<Screen2BodyInfo> {
  String _selectedGender = 'male';
  DateTime _selectedDate = DateTime(1995, 1, 1);
  final FocusNode _weightFocusNode = FocusNode();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedGender = prefs.getString('gender') ?? 'male';
      if (prefs.getString('birthDate') != null) {
        _selectedDate = DateTime.tryParse(prefs.getString('birthDate')!) ?? DateTime(1995, 1, 1);
      }
      _heightController.text = prefs.getString('height') ?? '';
      _weightController.text = prefs.getString('weight') ?? '';
    });
  }

  @override
  void dispose() {
    _weightFocusNode.dispose();
    _heightController.dispose();
    _weightController.dispose();
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
        title: const Text('신체 정보 입력'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('성별', isDark),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGender = 'male'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 48,
                          decoration: BoxDecoration(
                            color: _selectedGender == 'male' ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '남성',
                            style: TextStyle(
                              color: _selectedGender == 'male' ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGender = 'female'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 48,
                          decoration: BoxDecoration(
                            color: _selectedGender == 'female' ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '여성',
                            style: TextStyle(
                              color: _selectedGender == 'female' ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('생년월일', isDark),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: _buildInputCard(
                  theme: theme,
                  isDark: isDark,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Icon(Icons.calendar_today, color: primaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('키', isDark),
                        const SizedBox(height: 8),
                        _buildInputCard(
                          theme: theme,
                          isDark: isDark,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _heightController,
                                  decoration: InputDecoration(
                                    hintText: '000',
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) {
                                    FocusScope.of(context).requestFocus(_weightFocusNode);
                                  },
                                ),
                              ),
                              Text('cm', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('몸무게', isDark),
                        const SizedBox(height: 8),
                        _buildInputCard(
                          theme: theme,
                          isDark: isDark,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _weightController,
                                  focusNode: _weightFocusNode,
                                  decoration: InputDecoration(
                                    hintText: '00',
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                ),
                              ),
                              Text('kg', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.fitness_center, size: 32, color: primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '정확한 정보를 입력하면\n맞춤형 분석이 가능합니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('gender', _selectedGender);
                await prefs.setString('birthDate', _selectedDate.toIso8601String());
                await prefs.setString('height', _heightController.text);
                await prefs.setString('weight', _weightController.text);
                
                if (!context.mounted) return;
                
                final bool isSetupComplete = prefs.getBool('isSetupComplete') ?? false;
                if (isSetupComplete) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushNamed(context, '/screen3');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 4,
              ),
              child: const Text('저장하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInputCard({required ThemeData theme, required bool isDark, required Widget child}) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
