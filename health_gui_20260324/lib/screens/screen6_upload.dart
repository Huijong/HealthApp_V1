import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class Screen6Upload extends StatefulWidget {
  const Screen6Upload({super.key});

  @override
  State<Screen6Upload> createState() => _Screen6UploadState();
}

class _Screen6UploadState extends State<Screen6Upload> {
  String _userId = 'Unknown';
  String _pos = '왼쪽';
  String _fit = '적당히';
  String _training = '조깅';
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final List<String> _trainingOptions = ['조깅', '인터벌', 'LSD', '변속주', '지속주'];

  List<PlatformFile> _colaFiles = [];
  List<PlatformFile> _captureFiles = [];
  List<PlatformFile> _logFiles = [];
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('Id') ?? 'Unknown';
    });
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
      final dio = Dio();
      dio.options.headers['x-api-key'] = 'my_private_key_50';
      dio.options.connectTimeout = const Duration(minutes: 5);
      dio.options.receiveTimeout = const Duration(minutes: 30);
      dio.options.sendTimeout = const Duration(minutes: 30);

      final allFiles = [..._colaFiles, ..._captureFiles, ..._logFiles];
      if (allFiles.isEmpty) return;

      int totalBytes = allFiles.fold(0, (sum, f) => sum + f.size);
      int bytesAlreadyUploaded = 0;

      String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      Map<String, int> chunksMap = {};
      int chunkSize = 30 * 1024 * 1024; // 30 MB chunks

      for (var platformFile in allFiles) {
        if (platformFile.path == null) continue;
        File file = File(platformFile.path!);
        int fileLength = await file.length();
        
        int chunksCount = (fileLength / chunkSize).ceil();
        if (chunksCount == 0) chunksCount = 1; 
        chunksMap[platformFile.name] = chunksCount;

        RandomAccessFile raf = await file.open(mode: FileMode.read);
        
        for (int i = 0; i < chunksCount; i++) {
          int bytesToRead = (i == chunksCount - 1) ? fileLength - (i * chunkSize) : chunkSize;
          List<int> chunkBytes = await raf.read(bytesToRead);
          
          var formData = FormData.fromMap({
            'session_id': sessionId,
            'filename': platformFile.name,
            'chunk_index': i,
            'chunk': MultipartFile.fromBytes(chunkBytes, filename: '${platformFile.name}.part$i'),
          });
          
          await dio.post(
            'https://health-port.work/upload/chunk',
            data: formData,
            onSendProgress: (sent, total) {
              if (total > 0) {
                double chunkProgress = sent / total;
                double overallProgress = (bytesAlreadyUploaded + (bytesToRead * chunkProgress)) / totalBytes;
                _progressNotifier.value = overallProgress > 1.0 ? 1.0 : overallProgress;
              }
            },
          );
          bytesAlreadyUploaded += bytesToRead;
        }
        await raf.close();
      }

      var completeFormData = FormData.fromMap({
        'session_id': sessionId,
        'user_id': _userId,
        'pos': _pos,
        'fit': _fit,
        'training': _training,
        'location': _locationController.text,
        'remarks': _remarksController.text,
        'total_chunks_map': jsonEncode(chunksMap),
      });

      await dio.post(
        'https://health-port.work/upload/complete',
        data: completeFormData,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      
      setState(() {
         _colaFiles.clear();
         _captureFiles.clear();
         _logFiles.clear();
         _locationController.clear();
         _remarksController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('업로드 성공!')));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
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
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
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
