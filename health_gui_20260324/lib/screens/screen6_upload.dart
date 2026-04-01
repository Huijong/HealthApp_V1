import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

class Screen6Upload extends StatefulWidget {
  const Screen6Upload({super.key});

  @override
  State<Screen6Upload> createState() => _Screen6UploadState();
}

class _Screen6UploadState extends State<Screen6Upload> {
  String _pos = '왼쪽';
  String _fit = '적당히';
  String _training = '조깅';
  final TextEditingController _locationController = TextEditingController();
  final List<String> _trainingOptions = ['조깅', '인터벌', 'LSD', '변속주', '지속주'];

  List<PlatformFile> _colaFiles = [];
  List<PlatformFile> _captureFiles = [];
  List<PlatformFile> _logFiles = [];
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);

  Future<void> _pickFiles(String type) async {
    try {
      FilePickerResult? result;
      if (type == 'Cola') {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['zip'],
          allowMultiple: true,
        );
        if (result != null) {
          final validFiles = result.files.where((f) => f.name.toUpperCase().startsWith('COLA_')).toList();
          if (validFiles.isEmpty && result.files.isNotEmpty) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('COLA_ 형식으로 시작하는 파일이 없습니다.')));
          } else {
            setState(() => _colaFiles.addAll(validFiles));
          }
        }
      } else if (type == 'Capture') {
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
        );
        if (result != null) {
          final files = result.files;
          setState(() => _captureFiles.addAll(files));
        }
      } else if (type == 'Log') {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['zip'],
          allowMultiple: true,
        );
        if (result != null) {
          final validFiles = result.files.where((f) => f.name.toLowerCase().startsWith('log_')).toList();
          if (validFiles.isEmpty && result.files.isNotEmpty) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('log_ 로 시작하는 파일이 없습니다.')));
          } else {
            setState(() => _logFiles.addAll(validFiles));
          }
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
      final allFiles = [..._colaFiles, ..._captureFiles, ..._logFiles];
      int uploadedCount = 0;

      for (var file in allFiles) {
        if (file.path != null) {
          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(file.path!, filename: file.name),
          });

          await dio.post(
            'https://health-port.work/upload',
            data: formData,
            options: Options(
              headers: {
                'x-api-key': 'my_private_key_50',
              },
            ),
          );
        }
        uploadedCount++;
        _progressNotifier.value = uploadedCount / allFiles.length;
      }

      if (!mounted) return;
      Navigator.pop(context); // Close dialog
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
              _buildUploadCard('Cola', 'Cola 파일(.zip)을 선택해 주세요', Icons.file_download, theme, isDark, primaryColor, _colaFiles),
              const SizedBox(height: 12),
              _buildUploadCard('Capture', '화면 캡처 이미지 파일을 선택해 주세요', Icons.image, theme, isDark, primaryColor, _captureFiles),
              const SizedBox(height: 12),
              _buildUploadCard('Log', '로그 파일(.zip)을 선택해 주세요', Icons.folder_zip, theme, isDark, primaryColor, _logFiles),

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
