import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Screen9Settings extends StatefulWidget {
  const Screen9Settings({super.key});

  @override
  State<Screen9Settings> createState() => _Screen9SettingsState();
}

class _Screen9SettingsState extends State<Screen9Settings> {
  String _userIdSubtitle = '설정되지 않음';
  String _bodyInfoSubtitle = '설정되지 않음';
  String _watchModelSubtitle = '설정되지 않음';
  String _strapSubtitle = '설정되지 않음';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load User ID
    String userId = prefs.getString('Id') ?? '설정되지 않음';

    // Load Body Info
    String gender = prefs.getString('gender') == 'female' ? '여성' : (prefs.getString('gender') == 'male' ? '남성' : '');
    String height = prefs.getString('height') ?? '';
    String weight = prefs.getString('weight') ?? '';
    
    List<String> bodyInfo = [];
    if (gender.isNotEmpty) bodyInfo.add(gender);
    if (height.isNotEmpty) bodyInfo.add('${height}cm');
    if (weight.isNotEmpty) bodyInfo.add('${weight}kg');
    
    // Load Watch Model
    String watchModel = prefs.getString('selectedWatchModel') ?? '설정되지 않음';
    
    // Load Strap
    String strap = prefs.getString('selectedStrap') ?? '설정되지 않음';

    setState(() {
      _userIdSubtitle = userId;
      _bodyInfoSubtitle = bodyInfo.isNotEmpty ? bodyInfo.join(', ') : '설정되지 않음';
      _watchModelSubtitle = watchModel;
      _strapSubtitle = strap;
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
        title: const Text('설정'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettingMenuCard(
                context,
                icon: Icons.badge,
                category: 'Account',
                title: '아이디',
                subtitle: _userIdSubtitle,
                route: '/screen1', // Will go back to screen 1 to let them edit id
                theme: theme,
                isDark: isDark,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 16),
              _buildSettingMenuCard(
                context,
                icon: Icons.person,
                category: 'Biometrics',
                title: '신체 정보',
                subtitle: _bodyInfoSubtitle,
                route: '/screen2',
                theme: theme,
                isDark: isDark,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 16),
              _buildSettingMenuCard(
                context,
                icon: Icons.watch,
                category: 'Device Info',
                title: '워치 모델',
                subtitle: _watchModelSubtitle,
                route: '/screen3',
                theme: theme,
                isDark: isDark,
                primaryColor: primaryColor,
                statusTag: 'Connected',
              ),
              const SizedBox(height: 16),
              _buildSettingMenuCard(
                context,
                icon: Icons.watch_outlined, // or any accessory icon
                category: 'Accessories',
                title: '스트랩 선택',
                subtitle: _strapSubtitle,
                route: '/screen4',
                theme: theme,
                isDark: isDark,
                primaryColor: primaryColor,
              ),

              const SizedBox(height: 32),
              
              Text(
                'System Administration',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => _showAdminLoginDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(isDark ? 0.3 : 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.1),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.admin_panel_settings, color: primaryColor, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '관리자 모드',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '시스템 설정 및 로그 관리',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: primaryColor.withOpacity(0.6)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Battery',
                      value: '84%',
                      theme: theme,
                      isDark: isDark,
                      primaryColor: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Storage',
                      value: '12.4 GB',
                      theme: theme,
                      isDark: isDark,
                      primaryColor: primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 64),

              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'TERMS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'PRIVACY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'SUPPORT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MOMENTUM CORE V2.4.0 • 2024',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAdminLoginDialog(BuildContext context) async {
    final TextEditingController pwController = TextEditingController();
    bool isObscure = true;
    
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('관리자 인증', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: TextField(
                autofocus: true,
                controller: pwController,
                obscureText: isObscure,
                decoration: InputDecoration(
                  hintText: '비밀번호를 입력하세요',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setDialogState(() {
                        isObscure = !isObscure;
                      });
                    },
                  )
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (pwController.text.trim() == 'healthport') {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/screen10');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('비밀번호가 틀렸습니다.')));
                    }
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildSettingMenuCard(
    BuildContext context, {
    required IconData icon,
    required String category,
    required String title,
    required String subtitle,
    required String route,
    required ThemeData theme,
    required bool isDark,
    required Color primaryColor,
    String? statusTag,
  }) {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, route);
        _loadSettings();
      },
      child: Container(
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
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: primaryColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (statusTag != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusTag.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required ThemeData theme,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
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
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index < 3 ? primaryColor : (isDark ? Colors.grey[700] : Colors.grey[200]),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
