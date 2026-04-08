import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class Screen6Upload extends StatefulWidget {
  const Screen6Upload({super.key});

  @override
  State<Screen6Upload> createState() => _Screen6UploadState();
}

class _Screen6UploadState extends State<Screen6Upload> {
  String _userId = 'Unknown';
  String _watchModel = 'Unknown';
  String _strap = 'Unknown';
  String _activityName = 'Unknown';
  String _pos = '왼쪽';
  String _fit = '적당히';
  String _training = '조깅';
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final List<String> _trainingOptions = ['조깅', '인터벌', 'LSD', '변속주', '지속주'];
  Map<String, int> _badgeCounts = {
    '조깅': 0, '인터벌': 0, 'LSD': 0, '변속주': 0, '지속주': 0,
  };

  List<PlatformFile> _colaFiles = [];
  List<PlatformFile> _captureFiles = [];
  List<PlatformFile> _logFiles = [];
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _loadUserId();
    
    // 사용자가 옵션과 파일을 선택하는 동안 백그라운드 서비스가 미리 부팅되도록 보장합니다
    _ensureServiceRunning();
  }

  Future<void> _ensureServiceRunning() async {
    final service = FlutterBackgroundService();
    if (!(await service.isRunning())) {
      await service.startService();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _activityName = args;
    }
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('Id') ?? 'Unknown';
      _watchModel = prefs.getString('selectedWatchModel') ?? 'Unknown';
      _strap = prefs.getString('selectedStrap') ?? 'Unknown';
    });

    String historyStr = prefs.getString('upload_history') ?? '[]';
    List<dynamic> historyList = jsonDecode(historyStr);
    
    Map<String, int> counts = {
      '조깅': 0, '인터벌': 0, 'LSD': 0, '변속주': 0, '지속주': 0,
    };

    for (var item in historyList) {
      if (item['isSuccess'] == true) {
        List<dynamic> tags = item['tags'] ?? [];
        if (tags.isNotEmpty) {
          String training = tags[0].toString();
          if (counts.containsKey(training)) {
            counts[training] = counts[training]! + 1;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _badgeCounts = counts;
      });
    }
  }

  Future<List<PlatformFile>> _pickCustomFiles(String dirPath, String prefixFilter, List<String> extensions, {bool isImageMode = false}) async {
    if (await Permission.manageExternalStorage.request().isGranted || 
        await Permission.storage.request().isGranted) {
      
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$dirPath 폴더가 존재하지 않습니다.')));
        return [];
      }

      final List<File> availableFiles = [];
      try {
        final entities = dir.listSync();
        for (var entity in entities) {
          if (entity is File) {
            final fileName = entity.uri.pathSegments.last;
            final lowerName = fileName.toLowerCase();
            final matchesExt = extensions.isEmpty || extensions.any((ext) => lowerName.endsWith(ext));
            final matchesPrefix = prefixFilter.isEmpty || fileName.toUpperCase().startsWith(prefixFilter.toUpperCase());
            
            if (matchesExt && matchesPrefix) {
              availableFiles.add(entity);
            }
          }
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('폴더 읽기 오류: $e')));
        return [];
      }

      String userFriendlyFilter = prefixFilter.isNotEmpty ? '("$prefixFilter...") ' : '';
      if (availableFiles.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('조건에 맞는 ${userFriendlyFilter}파일이 없습니다.')));
        return [];
      }

      List<File> selectedFiles = [];
      bool? isConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              String titleText = prefixFilter.isNotEmpty ? '파일 선택 ($prefixFilter...)' : '이미지 파일 선택';
              return AlertDialog(
                title: Text(titleText, style: const TextStyle(fontSize: 16)),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 460, // taller for larger grid items
                  child: isImageMode
                    ? GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: availableFiles.length,
                        itemBuilder: (context, index) {
                          final file = availableFiles[index];
                          final isSelected = selectedFiles.contains(file);
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                if (isSelected) {
                                  selectedFiles.remove(file);
                                } else {
                                  selectedFiles.add(file);
                                }
                              });
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                ),
                                if (isSelected)
                                  Container(
                                    color: Colors.black45,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.check_circle, color: Colors.white, size: 36),
                                  ),
                              ],
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableFiles.length,
                        itemBuilder: (context, index) {
                          final file = availableFiles[index];
                          final isSelected = selectedFiles.contains(file);
                          
                          final lowerName = file.path.toLowerCase();
                          final isImage = lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg') || lowerName.endsWith('.png') || lowerName.endsWith('.webp') || lowerName.endsWith('.bmp');
                          
                          Widget thumbnail = isImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    file,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 44),
                                  ),
                                )
                              : const Icon(Icons.folder_zip, size: 44, color: Colors.grey);

                          return CheckboxListTile(
                            secondary: thumbnail,
                            title: Text(file.uri.pathSegments.last, style: const TextStyle(fontSize: 13)),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedFiles.add(file);
                                } else {
                                  selectedFiles.remove(file);
                                }
                              });
                            },
                          );
                        },
                      ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('선택 완료')),
                ],
              );
            }
          );
        }
      );

      if (isConfirmed == true && selectedFiles.isNotEmpty) {
        return selectedFiles.map((f) => PlatformFile(
          name: f.uri.pathSegments.last,
          size: f.lengthSync(),
          path: f.path,
        )).toList();
      }
      return [];
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장소 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.')));
      return [];
    }
  }

  Future<void> _pickFiles(String type) async {
    try {
      if (type == 'Cola') {
        final newFiles = await _pickCustomFiles('/storage/emulated/0/Documents/COLA_FILE', 'COLA_FILE_', ['.zip']);
        if (newFiles.isNotEmpty) {
          setState(() => _colaFiles.addAll(newFiles));
        }
      } else if (type == 'Capture') {
        final newFiles = await _pickCustomFiles('/storage/emulated/0/DCIM/Screenshots', '', ['.jpg', '.jpeg', '.png', '.webp', '.bmp'], isImageMode: true);
        if (newFiles.isNotEmpty) {
          setState(() => _captureFiles.addAll(newFiles));
        }
      } else if (type == 'Log') {
        final newFiles = await _pickCustomFiles('/storage/emulated/0/Documents/COLA_FILE', 'log_', ['.zip']);
        if (newFiles.isNotEmpty) {
          setState(() => _logFiles.addAll(newFiles));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('파일 선택 오류: $e')));
      }
    }
  }

  Future<void> _uploadFiles() async {
    if (_colaFiles.isEmpty && _captureFiles.isEmpty && _logFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('업로드할 파일을 먼저 선택하세요.')));
      return;
    }

    List<String> missingFiles = [];
    if (_colaFiles.isEmpty) missingFiles.add('Cola');
    if (_captureFiles.isEmpty) missingFiles.add('Capture');
    if (_logFiles.isEmpty) missingFiles.add('Log');

    if (missingFiles.isNotEmpty) {
      String missingStr = missingFiles.join(', ');
      bool confirm = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('파일 누락 확인', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text('$missingStr 파일을 첨부 안하셨습니다.\n그래도 전송하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('아니오', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('예', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ) ?? false;
      
      if (!confirm) {
        return; // 사용자가 취소
      }
    }

    _performUpload();
  }

  Future<void> _performUpload() async {
    _progressNotifier.value = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ValueListenableBuilder<double>(
          valueListenable: _progressNotifier,
          builder: (context, progress, child) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('파일 업로드 중...', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 16),
                  Text('${(progress * 100).toStringAsFixed(1)}% 완료', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      final allFiles = [..._colaFiles, ..._captureFiles, ..._logFiles];
      if (allFiles.isEmpty) return;

      List<Map<String, dynamic>> mappedFiles = allFiles.map((e) => {
        'path': e.path,
        'name': e.name,
        'size': e.size,
      }).toList();

      final service = FlutterBackgroundService();
      
      // 혹시 서비스가 안돌고 있다면 시작
      bool isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
        // 백그라운드 분리 스레드(Isolate)가 완전히 초기화되고 이벤트 리스너를 달 때까지 잠시 대기
        await Future.delayed(const Duration(seconds: 2));
      }

      service.invoke('startUpload', {
        'files': mappedFiles,
        'userId': _userId,
        'watchModel': _watchModel,
        'strap': _strap,
        'activityName': _activityName,
        'pos': _pos,
        'fit': _fit,
        'training': _training,
        'location': _locationController.text,
        'remarks': _remarksController.text,
      });

      // 리스너 등록
      service.on('uploadProgress').listen((event) {
        if (event != null && mounted) {
          _progressNotifier.value = event['progress'] as double;
        }
      });

      service.on('uploadComplete').listen((event) {
        if (event != null && mounted) {
           Navigator.pop(context); // Close dialog
           if (event['success'] == true) {
              setState(() {
                 _colaFiles.clear();
                 _captureFiles.clear();
                 _logFiles.clear();
                 _locationController.clear();
                 _remarksController.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('업로드 성공!')));
              // 진행률 다이얼로그 닫은 후, 현재 화면(Screen 6)도 닫아서 Screen 5로 복귀!
              Navigator.pop(context);
           } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('업로드 실패: ${event["error"]}')));
           }
        }
      });

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('업로드 시작 실패: $e')));
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
        title: const Text('업로드 가이드'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('업로드 파일', isDark),
              const SizedBox(height: 12),
              _buildUploadCard('Cola', '"COLA_FILE_" 로 시작하는 압축파일(.zip)', Icons.file_download, theme, isDark, primaryColor, _colaFiles),
              const SizedBox(height: 12),
              _buildUploadCard('Capture', '/sdcard/DCIM/Screenshots/ 내 이미지', Icons.image, theme, isDark, primaryColor, _captureFiles),
              const SizedBox(height: 12),
              _buildUploadCard('Log', '"log_" 로 시작하는 압축파일(.zip)', Icons.folder_zip, theme, isDark, primaryColor, _logFiles),

              const SizedBox(height: 40),

              _buildSectionTitle('착용 위치', isDark),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildSegmentButton('왼쪽', _pos, (val) => setState(() => _pos = val), primaryColor, isDark),
                    _buildSegmentButton('오른쪽', _pos, (val) => setState(() => _pos = val), primaryColor, isDark),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('착용 정도', isDark),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildSegmentButton('충분히', _fit, (val) => setState(() => _fit = val), primaryColor, isDark),
                    _buildSegmentButton('적당히', _fit, (val) => setState(() => _fit = val), primaryColor, isDark),
                    _buildSegmentButton('느슨하게', _fit, (val) => setState(() => _fit = val), primaryColor, isDark),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('훈련 종류', isDark),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _training,
                    isExpanded: true,
                    icon: Icon(Icons.expand_more, color: primaryColor),
                    dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _training = newValue;
                        });
                      }
                    },
                    items: _trainingOptions.map<DropdownMenuItem<String>>((String value) {
                      int count = _badgeCounts[value] ?? 0;
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(value),
                            if (count > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('장소', isDark),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: '훈련 장소를 입력해 주세요.',
                    hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('특이사항', isDark),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _remarksController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: '기타 전달하실 내용을 입력해 주세요.',
                    hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 100),
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
              onPressed: _uploadFiles,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 8,
                shadowColor: primaryColor.withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('업로드 계속하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward),
                ],
              ),
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
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[400] : Colors.grey[500],
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildUploadCard(String title, String subtitle, IconData icon, ThemeData theme, bool isDark, Color primary, List<PlatformFile> selectedFiles) {
    return GestureDetector(
      onTap: () => _pickFiles(title),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selectedFiles.isNotEmpty ? primary.withOpacity(0.6) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selectedFiles.isNotEmpty ? primary : primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                selectedFiles.isNotEmpty ? Icons.check : icon,
                color: selectedFiles.isNotEmpty ? Colors.white : primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (selectedFiles.isEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: selectedFiles.map((file) => Text(
                        file.name,
                        style: TextStyle(fontSize: 12, color: primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String text, String selected, Function(String) onSelect, Color primary, bool isDark) {
    final isSelected = selected == text;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(text),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[500]),
            ),
          ),
        ),
      ),
    );
  }
}
